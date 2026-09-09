local UIComponent = require("gfx.ui.components.UIComponent")
local UIConsole = class("UIConsole", UIComponent)

local LEVEL_COLOR = {
    info  = { 80, 200, 120 },
    warn  = { 235, 190, 80 },
    error = { 235, 100, 100 },
}

function UIConsole:ctor(x, y, width, height)
    UIConsole.super.ctor(self, x, y, width, height)

    self.r, self.g, self.b, self.a           = 14, 14, 17, 235
    self.borderR, self.borderG, self.borderB = 40, 42, 50
    self.cornerRadius                        = 4
    self.padding                             = 4
    self.gutterW                             = 14

    self.fontSize                            = 12
    self.lineHeight                          = self.fontSize + 5
    self.charWidth                           = math.max(4, math.floor(self.fontSize * 0.52))

    self.maxEntries                          = 300
    self.entries                             = {}
    self._totalLines                         = 0
    self._wrappedWidth                       = nil

    self.showTimestamps                      = false
    self.timeColW                            = 54

    self.autoScroll                          = true
    self._scrollY                            = 0

    -- drag
    self._dragging                           = false
    self._dragStartY                         = 0
    self._lastDragY                          = 0
    self._dragScrollY                        = 0

    -- elastic scrolling
    self._velocityY                          = 0
    self._bounceStrength                     = 18
    self._bounceDamping                      = 9
    self._overscrollResistance               = 0.35
    self._scrollSpeed                        = 2
end

-- ─── logging API ─────────────────────────────────────────────────────────────

function UIConsole:log(text, level)
    text = tostring(text)
    level = LEVEL_COLOR[level] and level or "info"

    local entry = {
        text    = text,
        level   = level,
        wrapped = self:_wrapText(text, self:_maxCharsPerLine()),
        time    = self.showTimestamps and (os.date and os.date("%H:%M:%S") or "") or nil,
    }

    self.entries[#self.entries + 1] = entry
    self._totalLines = self._totalLines + #entry.wrapped

    while #self.entries > self.maxEntries do
        local removed = table.remove(self.entries, 1)
        self._totalLines = self._totalLines - #removed.wrapped
    end

    self.autoScroll = true
    self._velocityY = 0
    self:_scrollToBottom()
end

function UIConsole:info(text)
    self:log(text, "info")
end

function UIConsole:warn(text)
    self:log(text, "warn")
end

function UIConsole:error(text)
    self:log(text, "error")
end

function UIConsole:clear()
    self.entries = {}
    self._totalLines = 0
    self._scrollY = 0
    self._velocityY = 0
    self.autoScroll = true
end

function UIConsole:setMaxEntries(n)
    self.maxEntries = math.max(1, n)

    while #self.entries > self.maxEntries do
        local removed = table.remove(self.entries, 1)
        self._totalLines = self._totalLines - #removed.wrapped
    end

    if self.autoScroll then
        self:_scrollToBottom()
    end
end

function UIConsole:setShowTimestamps(show)
    self.showTimestamps = show
    self:_rewrapAll()
end

-- ─── wrapping ────────────────────────────────────────────────────────────────

function UIConsole:_maxCharsPerLine()
    local timeW = self.showTimestamps and self.timeColW or 0
    local usable = self.width - self.padding * 2 - self.gutterW - timeW
    return math.max(4, math.floor(usable / self.charWidth))
end

function UIConsole:_wrapText(text, maxChars)
    if maxChars < 1 then maxChars = 1 end

    local lines = {}

    for rawLine in (text .. "\n"):gmatch("([^\n]*)\n") do
        if rawLine == "" then
            lines[#lines + 1] = ""
        else
            local cur = ""

            for word in rawLine:gmatch("%S+") do
                while #word > maxChars do
                    local avail = maxChars - #cur - (cur ~= "" and 1 or 0)

                    if avail < 1 then
                        lines[#lines + 1] = cur
                        cur = ""
                        avail = maxChars
                    end

                    cur = cur .. (cur ~= "" and " " or "") .. word:sub(1, avail)
                    word = word:sub(avail + 1)

                    lines[#lines + 1] = cur
                    cur = ""
                end

                local candidate = (cur == "") and word or (cur .. " " .. word)

                if #candidate > maxChars then
                    if cur ~= "" then
                        lines[#lines + 1] = cur
                    end
                    cur = word
                else
                    cur = candidate
                end
            end

            lines[#lines + 1] = cur
        end
    end

    return lines
end

function UIConsole:_rewrapAll()
    local maxChars = self:_maxCharsPerLine()

    self._totalLines = 0

    for _, entry in ipairs(self.entries) do
        entry.wrapped = self:_wrapText(entry.text, maxChars)
        self._totalLines = self._totalLines + #entry.wrapped
    end

    self._wrappedWidth = self.width

    if self.autoScroll then
        self:_scrollToBottom()
    else
        self._scrollY = math.max(0, math.min(self._scrollY, self:_maxScroll()))
    end
end

-- ─── scrolling ───────────────────────────────────────────────────────────────

function UIConsole:_maxScroll()
    local visible = self.height - self.padding * 2
    return math.max(0, self._totalLines * self.lineHeight - visible)
end

function UIConsole:_scrollToBottom()
    self._scrollY = self:_maxScroll()
end

function UIConsole:_jumpPillRect()
    if self.autoScroll or #self.entries == 0 then
        return nil
    end

    local label = "⮟"
    local w = #label * 6 + 16

    return {
        label = label,
        x = self._absX + self.width / 2 - w / 2,
        y = self._absY + self.height - 22,
        w = w,
        h = 16,
    }
end

-- ─── pointer ─────────────────────────────────────────────────────────────────

function UIConsole:onPointerPressed(px, py)
    if not self:contains(px, py) then
        return false
    end

    local pill = self:_jumpPillRect()

    if pill and px >= pill.x and px <= pill.x + pill.w and py >= pill.y and py <= pill.y + pill.h then
        self.autoScroll = true
        self._velocityY = 0
        self:_scrollToBottom()
        return true
    end

    self._dragging = true
    self._dragStartY = py
    self._lastDragY = py
    self._dragScrollY = self._scrollY
    self._velocityY = 0

    return true
end

function UIConsole:onPointerDragged(px, py)
    if not self._dragging then
        return
    end

    local dy = self._lastDragY - py
    self._lastDragY = py

    local maxScroll = self:_maxScroll()
    local nextY = self._scrollY + dy * self._scrollSpeed

    -- top elastic area
    if nextY < 0 then
        self._scrollY = nextY * self._overscrollResistance

        -- bottom elastic area
    elseif nextY > maxScroll then
        self._scrollY = maxScroll + (nextY - maxScroll) * self._overscrollResistance

        -- normal scrolling
    else
        self._scrollY = nextY
    end

    self._velocityY = dy * self._scrollSpeed
    self.autoScroll = false
end

function UIConsole:onPointerReleased(px, py)
    self._dragging = false
end

function UIConsole:onScrolled(scrollX, scrollY)
    local maxScroll = self:_maxScroll()
    local delta = scrollY * self.lineHeight * self._scrollSpeed
    local nextY = self._scrollY - delta

    if nextY < 0 then
        self._scrollY = nextY * self._overscrollResistance
        self.autoScroll = false
    elseif nextY > maxScroll then
        self._scrollY = maxScroll + (nextY - maxScroll) * self._overscrollResistance
        self.autoScroll = false
    else
        self._scrollY = nextY
        self.autoScroll = self._scrollY >= maxScroll - 1
    end

    return true
end

-- ─── elastic animation ───────────────────────────────────────────────────────

function UIConsole:update(dt)
    if self._dragging then
        return
    end

    local maxScroll = self:_maxScroll()

    -- overscrolled above the top
    if self._scrollY < 0 then
        local distance = -self._scrollY
        local force = distance * self._bounceStrength

        self._velocityY = self._velocityY + force * dt
        self._velocityY = self._velocityY * math.exp(-self._bounceDamping * dt)
        self._scrollY = self._scrollY + self._velocityY * dt

        if math.abs(self._scrollY) < 0.1 and math.abs(self._velocityY) < 0.1 then
            self._scrollY = 0
            self._velocityY = 0
        end

        return
    end

    -- overscrolled below the bottom
    if self._scrollY > maxScroll then
        local distance = maxScroll - self._scrollY
        local force = distance * self._bounceStrength

        self._velocityY = self._velocityY + force * dt
        self._velocityY = self._velocityY * math.exp(-self._bounceDamping * dt)
        self._scrollY = self._scrollY + self._velocityY * dt

        if math.abs(self._scrollY - maxScroll) < 0.1 and math.abs(self._velocityY) < 0.1 then
            self._scrollY = maxScroll
            self._velocityY = 0
        end

        return
    end

    -- inertial scrolling after release
    if math.abs(self._velocityY) > 0.01 then
        self._scrollY = self._scrollY + self._velocityY * dt
        self._velocityY = self._velocityY * math.exp(-8 * dt)

        -- hit top
        if self._scrollY < 0 then
            self._scrollY = self._scrollY * self._overscrollResistance
        end

        -- hit bottom
        if self._scrollY > maxScroll then
            self._scrollY = maxScroll + (self._scrollY - maxScroll) * self._overscrollResistance
        end
    else
        self._velocityY = 0
    end

    if maxScroll <= 0 then
        self._scrollY = 0
        self._velocityY = 0
        self.autoScroll = true
        return
    end

    self.autoScroll = self._scrollY >= maxScroll - 1
end

-- ─── draw ────────────────────────────────────────────────────────────────────

function UIConsole:draw(g)
    if self.width ~= self._wrappedWidth then
        self:_rewrapAll()
    end

    if not self._bgImage then
        if self.a > 0 then
            g:setColor(self.r, self.g, self.b, self.a)
            g:fillRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)

            g:setColor(self.borderR, self.borderG, self.borderB, 255)
            g:drawRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)
        end
    end

    g:save()
    g:setClip(self._absX + 1, self._absY + 1, self.width - 2, self.height - 2)

    local timeW = self.showTimestamps and self.timeColW or 0
    local textX = self._absX + self.padding + self.gutterW + timeW
    local top = self._absY + self.padding
    local bottom = self._absY + self.height - self.padding
    local y = top - self._scrollY

    local font = g:getFont()
    font:setFontSize(self.fontSize)

    for _, entry in ipairs(self.entries) do
        local col = LEVEL_COLOR[entry.level] or LEVEL_COLOR.info

        for i, line in ipairs(entry.wrapped) do
            if y + self.lineHeight >= top and y <= bottom then
                if i == 1 then
                    if self.showTimestamps and entry.time then
                        g:setColor(110, 114, 128, 255)
                        g:drawString(
                            entry.time,
                            self._absX + self.padding + self.gutterW,
                            y + self.lineHeight / 2,
                            Graphics.CENTER_LEFT
                        )
                    end
                end

                g:setColor(col[1], col[2], col[3], 255)
                g:drawString(line, textX, y + self.lineHeight / 2, Graphics.CENTER_LEFT)
            end

            y = y + self.lineHeight
        end
    end

    g:restore()

    -- -- scrollbar
    -- local maxScroll = self:_maxScroll()

    -- if maxScroll > 0 then
    --     local visible = self.height - self.padding * 2
    --     local trackH = self.height - 4
    --     local thumbH = math.max(16, trackH * (visible / (visible + maxScroll)))
    --     local travel = trackH - thumbH

    --     local scrollRatio = math.max(0, math.min(1, self._scrollY / maxScroll))
    --     local thumbY = self._absY + 2 + scrollRatio * travel

    --     g:setColor(0, 0, 0, 120)
    --     g:fillRect(self._absX + self.width - 5, self._absY + 2, 3, trackH)

    --     g:setColor(90, 94, 108, 220)
    --     g:fillRoundRect(self._absX + self.width - 5, thumbY, 3, thumbH, 1, 1)
    -- end

    -- -- jump-to-bottom pill
    -- local pill = self:_jumpPillRect()

    -- if pill then
    --     g:setColor(35, 60, 110, 230)
    --     g:fillRoundRect(pill.x, pill.y, pill.w, pill.h, 8, 8)

    --     g:setColor(190, 215, 255, 255)
    --     g:drawString(
    --         pill.label,
    --         pill.x + pill.w / 2,
    --         pill.y + pill.h / 2,
    --         Graphics.CENTER
    --     )
    -- end
end

return UIConsole

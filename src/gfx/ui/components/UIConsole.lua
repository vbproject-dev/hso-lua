local UIComponent = require("gfx.ui.components.UIComponent")
local UIConsole = class("UIConsole", UIComponent)

local LEVEL_COLOR = {
    info  = { 210, 214, 224 },
    warn  = { 235, 190, 80 },
    error = { 235, 100, 100 },
}

function UIConsole:ctor(x, y, width, height)
    UIConsole.super.ctor(self, x, y, width, height)

    self.r, self.g, self.b, self.a           = 14, 14, 17, 235
    self.borderR, self.borderG, self.borderB = 40, 42, 50
    self.cornerRadius                        = 4
    self.padding                             = 8
    self.gutterW                             = 14 -- reserved for the per-entry severity dot

    self.fontSize                            = 12
    self.lineHeight                          = self.fontSize + 5
    -- No string-measurement API is assumed to exist, so line-wrapping uses
    -- the same "average pixels per character" estimate the rest of this UI
    -- toolkit already relies on for button sizing.
    self.charWidth                           = math.max(4, math.floor(self.fontSize * 0.52))

    self.maxEntries                          = 300
    self.entries                             = {}
    self._totalLines                         = 0
    self._wrappedWidth                       = nil -- forces a wrap pass before the first draw

    self.showTimestamps                      = false
    self.timeColW                            = 54

    self.autoScroll                          = true -- sticks to the newest entry until the user scrolls up
    self._scrollY                            = 0
    self._dragging                           = false
    self._dragStartY                         = 0
    self._dragScrollY                        = 0
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

    if self.autoScroll then self:_scrollToBottom() end
end

function UIConsole:info(text) self:log(text, "info") end

function UIConsole:warn(text) self:log(text, "warn") end

function UIConsole:error(text) self:log(text, "error") end

function UIConsole:clear()
    self.entries = {}
    self._totalLines = 0
    self._scrollY = 0
end

function UIConsole:setMaxEntries(n)
    self.maxEntries = math.max(1, n)
    while #self.entries > self.maxEntries do
        local removed = table.remove(self.entries, 1)
        self._totalLines = self._totalLines - #removed.wrapped
    end
end

function UIConsole:setShowTimestamps(show)
    self.showTimestamps = show
    self:_rewrapAll() -- the timestamp column eats into the wrap width
end

-- ─── wrapping ────────────────────────────────────────────────────────────────

function UIConsole:_maxCharsPerLine()
    local timeW = self.showTimestamps and self.timeColW or 0
    local usable = self.width - self.padding * 2 - self.gutterW - timeW
    return math.max(4, math.floor(usable / self.charWidth))
end

-- Greedy word-wrap, preserving embedded newlines and hard-breaking any
-- single "word" too long to fit a whole line on its own (long paths,
-- stack traces, etc.) so nothing ever overflows or stalls the wrapper.
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
                        cur, avail = "", maxChars
                    end
                    cur = cur .. (cur ~= "" and " " or "") .. word:sub(1, avail)
                    word = word:sub(avail + 1)
                    lines[#lines + 1] = cur
                    cur = ""
                end

                local candidate = (cur == "") and word or (cur .. " " .. word)
                if #candidate > maxChars then
                    lines[#lines + 1] = cur
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

-- Re-wraps every existing entry — needed when the component is resized,
-- since previously-wrapped line breaks no longer match the new width.
function UIConsole:_rewrapAll()
    local maxChars = self:_maxCharsPerLine()
    self._totalLines = 0
    for _, entry in ipairs(self.entries) do
        entry.wrapped = self:_wrapText(entry.text, maxChars)
        self._totalLines = self._totalLines + #entry.wrapped
    end
    self._wrappedWidth = self.width
    if self.autoScroll then self:_scrollToBottom() end
end

function UIConsole:_maxScroll()
    local visible = self.height - self.padding * 2
    return math.max(0, self._totalLines * self.lineHeight - visible)
end

function UIConsole:_scrollToBottom()
    self._scrollY = self:_maxScroll()
end

function UIConsole:_jumpPillRect()
    if self.autoScroll or #self.entries == 0 then return nil end
    local label = "scroll to latest"
    local w = #label * 6 + 16
    return {
        label = label,
        x = self._absX + self.width / 2 - w / 2,
        y = self._absY + self.height - 22,
        w = w,
        h = 16,
    }
end

function UIConsole:onPointerPressed(px, py)
    if not self:contains(px, py) then return false end

    local pill = self:_jumpPillRect()
    if pill and px >= pill.x and px <= pill.x + pill.w and py >= pill.y and py <= pill.y + pill.h then
        self.autoScroll = true
        self:_scrollToBottom()
        return true
    end

    self._dragging    = true
    self._dragStartY  = py
    self._dragScrollY = self._scrollY
    return true
end

function UIConsole:onPointerDragged(px, py)
    if not self._dragging then return end
    local maxScroll = self:_maxScroll()
    self._scrollY = math.max(0, math.min(maxScroll, self._dragScrollY + (self._dragStartY - py)))
    self.autoScroll = (self._scrollY >= maxScroll - 1)
end

function UIConsole:onPointerReleased(px, py)
    self._dragging = false
end

function UIConsole:onScrolled(scrollX, scrollY)
    local maxScroll = self:_maxScroll()
    self._scrollY = math.max(0, math.min(maxScroll, self._scrollY - scrollY * self.lineHeight))
    self.autoScroll = (self._scrollY >= maxScroll - 1)
    return true
end

-- ─── draw ────────────────────────────────────────────────────────────────────

function UIConsole:draw(g)
    if self.width ~= self._wrappedWidth then
        self:_rewrapAll()
    end
    if not self._bgImage or self.a < 1 then
        g:setColor(self.r, self.g, self.b, self.a)
        g:fillRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)
        g:setColor(self.borderR, self.borderG, self.borderB, 255)
        g:drawRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)
    end
    g:save()
    g:setClip(self._absX + 1, self._absY + 1, self.width - 2, self.height - 2)

    local timeW  = self.showTimestamps and self.timeColW or 0
    local textX  = self._absX + self.padding + self.gutterW + timeW
    local top    = self._absY + self.padding
    local bottom = self._absY + self.height - self.padding
    local y      = top - self._scrollY

    local font   = g:getFont()
    font:setFontSize(self.fontSize)
    for _, entry in ipairs(self.entries) do
        local col = LEVEL_COLOR[entry.level] or LEVEL_COLOR.info
        for i, line in ipairs(entry.wrapped) do
            if y + self.lineHeight >= top and y <= bottom then
                if i == 1 then
                    -- g:setColor(col[1], col[2], col[3], 255)
                    -- g:fillRoundRect(self._absX + self.padding, y + self.lineHeight / 2 - 3, 6, 6, 3, 3)
                    if self.showTimestamps and entry.time then
                        g:setColor(110, 114, 128, 255)
                        g:drawString(entry.time, self._absX + self.padding + self.gutterW,
                            y + self.lineHeight / 2, Graphics.CENTER_LEFT)
                    end
                end
                g:setColor(col[1], col[2], col[3], 255)
                g:drawString(line, textX, y + self.lineHeight / 2, Graphics.CENTER_LEFT)
            end
            y = y + self.lineHeight
        end
    end

    g:restore()

    -- scrollbar
    local maxScroll = self:_maxScroll()
    if maxScroll > 0 then
        local visible = self.height - self.padding * 2
        local trackH  = self.height - 4
        local thumbH  = math.max(16, trackH * (visible / (visible + maxScroll)))
        local travel  = trackH - thumbH
        local thumbY  = self._absY + 2 + (self._scrollY / maxScroll) * travel
        g:setColor(0, 0, 0, 120)
        g:fillRect(self._absX + self.width - 5, self._absY + 2, 3, trackH)
        g:setColor(90, 94, 108, 220)
        g:fillRoundRect(self._absX + self.width - 5, thumbY, 3, thumbH, 1, 1)
    end

    -- while scrolled away from the bottom, hint that newer output is
    -- waiting below — same convention as chat apps / game dev consoles
    local pill = self:_jumpPillRect()
    if pill then
        g:setColor(35, 60, 110, 230)
        g:fillRoundRect(pill.x, pill.y, pill.w, pill.h, 8, 8)
        g:setColor(190, 215, 255, 255)
        g:drawString(pill.label, pill.x + pill.w / 2, pill.y + pill.h / 2, Graphics.CENTER)
    end
end

return UIConsole

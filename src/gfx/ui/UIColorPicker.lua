local UIColorPicker = class("UIColorPicker")

-- ─── layout ──────────────────────────────────────────────────────────────────
local W       = 460
local H       = 420
local MX      = (SCREEN_WIDTH  - W) / 2
local MY      = (SCREEN_HEIGHT - H) / 2
local PAD     = 14
local HDR_H   = 34
local FTR_H   = 48

local SV_SIZE = 200          -- SV square
local HUE_W   = 20           -- hue bar width
local HUE_GAP = 8            -- gap between SV and hue bar

-- right panel (sliders) starts after SV + hue bar
local RP_X    = MX + PAD + SV_SIZE + HUE_GAP + HUE_W + PAD
local RP_W    = W - (SV_SIZE + HUE_GAP + HUE_W) - PAD * 3
local SL_H    = 14           -- slider track height
local ROW_H   = 36           -- per-channel row height
local INPUT_W = 44           -- number input box width
local LABEL_W = 14           -- "R" "G" "B" "A" label width

-- ─── HSV <-> RGB ─────────────────────────────────────────────────────────────

local function hsvToRgb(h, s, v)
    if s == 0 then
        local c = math.floor(v * 255 + 0.5)
        return c, c, c
    end
    h = h % 360
    local i = math.floor(h / 60)
    local f = h / 60 - i
    local p = v * (1 - s)
    local q = v * (1 - s * f)
    local t = v * (1 - s * (1 - f))
    local r, g, b
    if     i == 0 then r,g,b = v,t,p
    elseif i == 1 then r,g,b = q,v,p
    elseif i == 2 then r,g,b = p,v,t
    elseif i == 3 then r,g,b = p,q,v
    elseif i == 4 then r,g,b = t,p,v
    else               r,g,b = v,p,q
    end
    return math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5)
end

local function rgbToHsv(r, g, b)
    r, g, b = r/255, g/255, b/255
    local mx = math.max(r,g,b)
    local mn = math.min(r,g,b)
    local d  = mx - mn
    local v  = mx
    local s  = mx == 0 and 0 or d/mx
    local h  = 0
    if d ~= 0 then
        if     mx == r then h = (g-b)/d % 6
        elseif mx == g then h = (b-r)/d + 2
        else                h = (r-g)/d + 4
        end
        h = h * 60
    end
    return h, s, v
end

-- ─── channel definitions ─────────────────────────────────────────────────────
-- each: key, label, r1,g1,b1 (left color), r2,g2,b2 (right color computed at render)
local CHANNELS = {
    { key="r", label="R" },
    { key="g", label="G" },
    { key="b", label="B" },
    { key="a", label="A" },
}

-- ─── ctor ────────────────────────────────────────────────────────────────────

function UIColorPicker:ctor(onPick)
    self.onPick    = onPick
    self.visible   = false
    self._h        = 0
    self._s        = 1
    self._v        = 1
    self._r        = 255
    self._g        = 0
    self._b        = 0
    self._a        = 255
    self._drag     = nil   -- "sv"|"hue"|"r"|"g"|"b"|"a"
    self._focus    = nil   -- "r"|"g"|"b"|"a"|"hex"
    self._inputs   = { r="255", g="0", b="0", a="255", hex="FF0000FF" }
    self._origR    = 255
    self._origG    = 0
    self._origB    = 0
    self._origA    = 255
end

-- ─── open / close ────────────────────────────────────────────────────────────

function UIColorPicker:open(r, g, b, a)
    self._r, self._g, self._b = r or 255, g or 255, b or 255
    self._a = a or 255
    self._origR, self._origG, self._origB, self._origA = self._r, self._g, self._b, self._a
    self._h, self._s, self._v = rgbToHsv(self._r, self._g, self._b)
    self:_syncInputs()
    self.visible = true
    self._focus  = nil
    self._drag   = nil
end

function UIColorPicker:close()
    self.visible = false
    self:_stopInput()
end

function UIColorPicker:_stopInput()
    if self._focus then
        Input.stopInput()
        Input.clearInputCallback()
        self._focus = nil
    end
end

function UIColorPicker:_syncInputs()
    self._inputs.r   = tostring(self._r)
    self._inputs.g   = tostring(self._g)
    self._inputs.b   = tostring(self._b)
    self._inputs.a   = tostring(self._a)
    self._inputs.hex = string.format("%02X%02X%02X%02X", self._r, self._g, self._b, self._a)
end

function UIColorPicker:_syncFromRGB()
    self._h, self._s, self._v = rgbToHsv(self._r, self._g, self._b)
    self:_syncInputs()
end

function UIColorPicker:_syncFromHSV()
    self._r, self._g, self._b = hsvToRgb(self._h, self._s, self._v)
    self:_syncInputs()
end

function UIColorPicker:_commitInput(key)
    if key == "hex" then
        local s = self._inputs.hex:gsub("[^%x]","")
        if #s == 6 then s = s .. "FF" end
        if #s == 8 then
            self._r = tonumber(s:sub(1,2),16)
            self._g = tonumber(s:sub(3,4),16)
            self._b = tonumber(s:sub(5,6),16)
            self._a = tonumber(s:sub(7,8),16)
            self:_syncFromRGB()
        end
    else
        local n = tonumber(self._inputs[key])
        if n then
            n = math.max(0, math.min(255, math.floor(n+0.5)))
            self["_"..key] = n
            if key ~= "a" then self:_syncFromRGB()
            else self:_syncInputs() end
        end
    end
end

-- ─── geometry ────────────────────────────────────────────────────────────────

local function svX()  return MX + PAD end
local function svY()  return MY + HDR_H + PAD end
local function hueX() return svX() + SV_SIZE + HUE_GAP end
local function hueY() return svY() end

-- right panel rows: R, G, B, A, then hex
local function rowY(i) return MY + HDR_H + PAD + (i-1) * ROW_H end
local function sliderX()  return RP_X + LABEL_W + 6 end
local function sliderW()  return RP_W - LABEL_W - 6 - INPUT_W - 6 end
local function inputX()   return RP_X + LABEL_W + 6 + sliderW() + 6 end

-- ─── pointer ─────────────────────────────────────────────────────────────────

function UIColorPicker:onPointerPressed(px, py)
    if not self.visible then return false end

    -- header close button
    if px >= MX+W-28 and px <= MX+W-4 and py >= MY+4 and py <= MY+HDR_H-4 then
        self:close(); return true
    end

    -- footer
    local btnY = MY + H - FTR_H + 10
    if py >= btnY and py <= btnY + 28 then
        -- cancel
        if px >= MX+PAD and px <= MX+PAD+90 then
            self:close(); return true
        end
        -- ok
        if px >= MX+W-PAD-90 and px <= MX+W-PAD then
            if self.onPick then self.onPick(self._r, self._g, self._b, self._a) end
            self:close(); return true
        end
    end

    -- SV square
    local sx, sy = svX(), svY()
    if px >= sx and px <= sx+SV_SIZE and py >= sy and py <= sy+SV_SIZE then
        self:_stopInput()
        self._drag = "sv"
        self:_dragSV(px, py)
        return true
    end

    -- hue bar
    local hx, hy = hueX(), hueY()
    if px >= hx and px <= hx+HUE_W and py >= hy and py <= hy+SV_SIZE then
        self:_stopInput()
        self._drag = "hue"
        self:_dragHue(py)
        return true
    end

    -- channel sliders + inputs
    for i, ch in ipairs(CHANNELS) do
        local ry  = rowY(i)
        local slx = sliderX()
        local slw = sliderW()
        local inx = inputX()

        -- slider track
        if px >= slx and px <= slx+slw and py >= ry+4 and py <= ry+ROW_H-4 then
            self:_stopInput()
            self._drag = ch.key
            self:_dragChannel(ch.key, px)
            return true
        end

        -- input box
        if px >= inx and px <= inx+INPUT_W and py >= ry+6 and py <= ry+ROW_H-6 then
            self:_startInput(ch.key)
            return true
        end
    end

    -- hex row
    local hexRowY = rowY(5)
    local hexInX  = RP_X + 28
    local hexInW  = RP_W - 28
    if px >= hexInX and px <= hexInX+hexInW and py >= hexRowY+6 and py <= hexRowY+ROW_H-6 then
        self:_startInput("hex")
        return true
    end

    return true
end

function UIColorPicker:onPointerDragged(px, py)
    if not self.visible then return end
    if self._drag == "sv"  then self:_dragSV(px, py)
    elseif self._drag == "hue" then self:_dragHue(py)
    elseif self._drag then self:_dragChannel(self._drag, px)
    end
end

function UIColorPicker:onPointerReleased(px, py)
    self._drag = nil
end

function UIColorPicker:_dragSV(px, py)
    local sx, sy = svX(), svY()
    self._s = math.max(0, math.min(1, (px - sx) / SV_SIZE))
    self._v = math.max(0, math.min(1, 1 - (py - sy) / SV_SIZE))
    self:_syncFromHSV()
end

function UIColorPicker:_dragHue(py)
    self._h = math.max(0, math.min(359.99, ((py - hueY()) / SV_SIZE) * 360))
    self:_syncFromHSV()
end

function UIColorPicker:_dragChannel(key, px)
    local slx = sliderX()
    local slw = sliderW()
    local t   = math.max(0, math.min(1, (px - slx) / slw))
    local n   = math.floor(t * 255 + 0.5)
    self["_"..key] = n
    if key ~= "a" then self:_syncFromRGB()
    else self:_syncInputs() end
end

-- ─── text input ──────────────────────────────────────────────────────────────

function UIColorPicker:_startInput(key)
    if self._focus == key then return end
    self:_stopInput()
    self._focus = key
    self._inputs[key] = (key == "hex") and
        string.format("%02X%02X%02X%02X", self._r, self._g, self._b, self._a) or
        tostring(self["_"..key])
    Input.startInput()
    Input.setInputCallback(function(ch)
        local max = (key == "hex") and 8 or 3
        if #self._inputs[key] < max then
            self._inputs[key] = self._inputs[key] .. (key == "hex" and ch:upper() or ch)
        end
    end)
end

function UIColorPicker:onKeyPressed(key)
    if not self.visible then return end
    if self._focus then
        if key == Input.KEY_BACKSPACE then
            local s = self._inputs[self._focus]
            self._inputs[self._focus] = s:sub(1, #s - 1)
        elseif key == Input.KEY_RETURN or key == Input.KEY_KP_ENTER then
            self:_commitInput(self._focus)
            self:_stopInput()
        elseif key == Input.KEY_ESCAPE then
            self:_syncInputs()
            self:_stopInput()
        end
        return
    end
    if key == Input.KEY_ESCAPE then self:close() end
    if key == Input.KEY_RETURN then
        if self.onPick then self.onPick(self._r, self._g, self._b, self._a) end
        self:close()
    end
end

-- ─── render helpers ──────────────────────────────────────────────────────────

local function drawCheckerboard(g, x, y, w, h, size)
    size = size or 6
    for row = 0, math.ceil(h/size)-1 do
        for col = 0, math.ceil(w/size)-1 do
            local light = (row+col)%2 == 0
            g:setColor(light and 200 or 140, light and 200 or 140, light and 200 or 140, 255)
            g:fillRect(x+col*size, y+row*size, size, size)
        end
    end
end

local function drawSliderCursor(g, x, y, h)
    g:setColor(255, 255, 255, 240)
    g:fillRoundRect(x-4, y-2, 8, h+4, 3, 3)
    g:setColor(0, 0, 0, 160)
    g:drawRoundRect(x-4, y-2, 8, h+4, 3, 3)
end

-- ─── render ──────────────────────────────────────────────────────────────────

function UIColorPicker:render(g)
    if not self.visible then return end

    -- dim overlay
    g:setColor(0, 0, 0, 160)
    g:fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- modal shadow
    g:setColor(0, 0, 0, 80)
    g:fillRoundRect(MX+4, MY+4, W, H, 10, 10)

    -- modal bg
    g:setColor(30, 30, 33, 255)
    g:fillRoundRect(MX, MY, W, H, 10, 10)
    g:setColor(55, 55, 62, 255)
    g:drawRoundRect(MX, MY, W, H, 10, 10)

    -- header
    g:setColor(22, 22, 25, 255)
    g:fillRoundRect(MX, MY, W, HDR_H, 10, 10)
    g:fillRect(MX, MY+HDR_H/2, W, HDR_H/2)
    g:setColor(55, 55, 62, 255)
    g:drawLine(MX, MY+HDR_H, MX+W, MY+HDR_H)
    g:setColor(210, 210, 218, 255)
    g:drawString("Color Picker", MX+PAD, MY+HDR_H/2, Graphics.CENTER_LEFT)
    -- close btn
    g:setColor(190, 55, 55, 255)
    g:fillRoundRect(MX+W-28, MY+5, 22, HDR_H-10, 4, 4)
    g:setColor(255,255,255,255)
    g:drawString("X", MX+W-17, MY+HDR_H/2, Graphics.CENTER)

    local sx, sy = svX(), svY()
    local cr, cg, cb = self._r, self._g, self._b

    -- ── SV square ────────────────────────────────────────────────────────────
    -- render as 4x4 block grid for performance
    local COLS = 40
    local ROWS = 40
    local cw2  = SV_SIZE / COLS
    local rh2  = SV_SIZE / ROWS
    for col = 0, COLS-1 do
        local s = col / (COLS-1)
        for row = 0, ROWS-1 do
            local v  = 1 - row / (ROWS-1)
            local lr, lg, lb = hsvToRgb(self._h, s, v)
            g:setColor(lr, lg, lb, 255)
            g:fillRect(
                sx + math.floor(col*cw2),
                sy + math.floor(row*rh2),
                math.ceil(cw2)+1,
                math.ceil(rh2)+1
            )
        end
    end
    g:setColor(55, 55, 62, 255)
    g:drawRect(sx, sy, SV_SIZE, SV_SIZE)

    -- SV cursor
    local curX = sx + math.floor(self._s * SV_SIZE)
    local curY = sy + math.floor((1-self._v) * SV_SIZE)
    g:setColor(0, 0, 0, 180)
    g:drawCircle(curX, curY, 8)
    g:setColor(255, 255, 255, 255)
    g:drawCircle(curX, curY, 7)
    g:setColor(cr, cg, cb, 255)
    g:fillCircle(curX, curY, 6)

    -- ── Hue bar (vertical) ───────────────────────────────────────────────────
    local hx, hy = hueX(), hueY()
    local HUE_STEPS = 36
    for i = 0, HUE_STEPS-1 do
        local h1 = i / HUE_STEPS * 360
        local r1, g1, b1 = hsvToRgb(h1, 1, 1)
        g:setColor(r1, g1, b1, 255)
        local y1 = hy + math.floor(i / HUE_STEPS * SV_SIZE)
        local y2 = hy + math.floor((i+1) / HUE_STEPS * SV_SIZE)
        g:fillRect(hx, y1, HUE_W, y2-y1+1)
    end
    g:setColor(55, 55, 62, 255)
    g:drawRect(hx, hy, HUE_W, SV_SIZE)
    -- hue cursor
    local hcY = hy + math.floor((self._h/360) * SV_SIZE)
    g:setColor(255, 255, 255, 230)
    g:fillRect(hx-3, hcY-3, HUE_W+6, 6)
    g:setColor(0, 0, 0, 160)
    g:drawRect(hx-3, hcY-3, HUE_W+6, 6)

    -- ── Right panel: R G B A sliders ─────────────────────────────────────────
    local slx = sliderX()
    local slw = sliderW()
    local inx = inputX()

    -- channel colors for gradient endpoints
    local chColors = {
        r = { {0,cg,cb}, {255,cg,cb} },
        g = { {cr,0,cb}, {cr,255,cb} },
        b = { {cr,cg,0}, {cr,cg,255} },
        a = nil,  -- special: checkerboard
    }
    local chVals = { r=self._r, g=self._g, b=self._b, a=self._a }
    local chLabColors = {
        r = {220, 80,  80 },
        g = {80,  200, 100},
        b = {80,  130, 220},
        a = {180, 180, 185},
    }

    for i, ch in ipairs(CHANNELS) do
        local ry  = rowY(i)
        local val = chVals[ch.key]
        local lc  = chLabColors[ch.key]

        -- label
        g:setColor(lc[1], lc[2], lc[3], 255)
        g:drawString(ch.label, RP_X, ry + ROW_H/2, Graphics.CENTER_LEFT)

        -- slider track bg
        g:setColor(22, 22, 25, 255)
        g:fillRoundRect(slx, ry + (ROW_H-SL_H)/2, slw, SL_H, 4, 4)

        -- gradient fill
        local GSTEPS = 16
        if ch.key == "a" then
            -- checkerboard then alpha gradient
            drawCheckerboard(g, slx, ry+(ROW_H-SL_H)/2, slw, SL_H, 5)
            for j = 0, GSTEPS-1 do
                local a1 = math.floor(j/GSTEPS*255)
                local x1 = slx + math.floor(j/GSTEPS*slw)
                local x2 = slx + math.floor((j+1)/GSTEPS*slw)
                g:setColor(cr, cg, cb, a1)
                g:fillRect(x1, ry+(ROW_H-SL_H)/2, x2-x1, SL_H)
            end
        else
            local c1 = chColors[ch.key][1]
            local c2 = chColors[ch.key][2]
            for j = 0, GSTEPS-1 do
                local t  = j / GSTEPS
                local t2 = (j+1) / GSTEPS
                local tm = (t+t2)/2
                local lr = math.floor(c1[1]*(1-tm) + c2[1]*tm + 0.5)
                local lg = math.floor(c1[2]*(1-tm) + c2[2]*tm + 0.5)
                local lb = math.floor(c1[3]*(1-tm) + c2[3]*tm + 0.5)
                g:setColor(lr, lg, lb, 255)
                local x1 = slx + math.floor(t*slw)
                local x2 = slx + math.floor(t2*slw)
                g:fillRect(x1, ry+(ROW_H-SL_H)/2, x2-x1, SL_H)
            end
        end

        g:setColor(55, 55, 62, 255)
        g:drawRoundRect(slx, ry+(ROW_H-SL_H)/2, slw, SL_H, 4, 4)

        -- slider cursor
        local cx2 = slx + math.floor((val/255) * slw)
        drawSliderCursor(g, cx2, ry+(ROW_H-SL_H)/2, SL_H)

        -- input box
        local isFocus = self._focus == ch.key
        g:setColor(isFocus and 35 or 28, isFocus and 55 or 28, isFocus and 90 or 32, 255)
        g:fillRoundRect(inx, ry+6, INPUT_W, ROW_H-12, 4, 4)
        g:setColor(isFocus and 70 or 50, isFocus and 120 or 50, isFocus and 210 or 56, 255)
        g:drawRoundRect(inx, ry+6, INPUT_W, ROW_H-12, 4, 4)
        g:setColor(220, 220, 228, 255)
        local disp = isFocus and (self._inputs[ch.key].."|") or tostring(val)
        g:drawString(disp, inx + INPUT_W/2, ry+ROW_H/2, Graphics.CENTER)
    end

    -- ── Hex row ───────────────────────────────────────────────────────────────
    local hexRowY = rowY(5)
    g:setColor(120, 120, 128, 255)
    g:drawString("#", RP_X, hexRowY+ROW_H/2, Graphics.CENTER_LEFT)
    local hexInX = RP_X + 18
    local hexInW = RP_W - 18
    local hexFoc = self._focus == "hex"
    g:setColor(hexFoc and 35 or 28, hexFoc and 55 or 28, hexFoc and 90 or 32, 255)
    g:fillRoundRect(hexInX, hexRowY+6, hexInW, ROW_H-12, 4, 4)
    g:setColor(hexFoc and 70 or 50, hexFoc and 120 or 50, hexFoc and 210 or 56, 255)
    g:drawRoundRect(hexInX, hexRowY+6, hexInW, ROW_H-12, 4, 4)
    g:setColor(220, 220, 228, 255)
    local hexDisp = hexFoc and (self._inputs.hex.."|") or
        string.format("%02X%02X%02X%02X", self._r, self._g, self._b, self._a)
    g:drawString(hexDisp, hexInX+8, hexRowY+ROW_H/2, Graphics.CENTER_LEFT)

    -- ── Preview row ───────────────────────────────────────────────────────────
    local prevY = rowY(6) + 4
    local prevH = 28
    local prevW = RP_W
    -- old color (left half)
    g:setColor(self._origR, self._origG, self._origB, self._origA)
    g:fillRoundRect(RP_X, prevY, prevW/2, prevH, 4, 4)
    -- new color (right half)
    drawCheckerboard(g, RP_X + prevW/2, prevY, prevW/2, prevH, 5)
    g:setColor(cr, cg, cb, self._a)
    g:fillRoundRect(RP_X + prevW/2, prevY, prevW/2, prevH, 4, 4)
    g:setColor(55, 55, 62, 255)
    g:drawRoundRect(RP_X, prevY, prevW, prevH, 4, 4)
    -- labels
    g:setColor(100, 100, 108, 255)
    g:drawString("old", RP_X + prevW/4, prevY+prevH+8, Graphics.CENTER)
    g:drawString("new", RP_X + prevW*3/4, prevY+prevH+8, Graphics.CENTER)

    -- ── Footer ────────────────────────────────────────────────────────────────
    local btnY = MY + H - FTR_H + 10
    g:setColor(22, 22, 25, 255)
    g:fillRect(MX, MY+H-FTR_H, W, FTR_H)
    g:setColor(55, 55, 62, 255)
    g:drawLine(MX, MY+H-FTR_H, MX+W, MY+H-FTR_H)

    -- cancel
    g:setColor(50, 50, 56, 255)
    g:fillRoundRect(MX+PAD, btnY, 90, 28, 6, 6)
    g:setColor(55, 55, 62, 255)
    g:drawRoundRect(MX+PAD, btnY, 90, 28, 6, 6)
    g:setColor(180, 180, 188, 255)
    g:drawString("Cancel", MX+PAD+45, btnY+14, Graphics.CENTER)

    -- ok
    g:setColor(40, 95, 175, 255)
    g:fillRoundRect(MX+W-PAD-90, btnY, 90, 28, 6, 6)
    g:setColor(60, 120, 210, 255)
    g:drawRoundRect(MX+W-PAD-90, btnY, 90, 28, 6, 6)
    g:setColor(220, 232, 255, 255)
    g:drawString("OK", MX+W-PAD-45, btnY+14, Graphics.CENTER)
end

return UIColorPicker

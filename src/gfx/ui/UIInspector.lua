local UI           = require("gfx.ui.components.init")

local UIInspector  = class("UIInspector")

local W            = 290
local PAD          = 10
local ROW_H        = 30
local LABEL_W      = 96
local FIELD_H      = 22
local SEC_H        = 26
local TITLE_H      = 46
local PICK_W       = 30
local SWATCH_W     = 42
local CURSOR_BLINK = 0.5

local function F(key, label, ftype, opts)
    return { key = key, label = label, ftype = ftype or "number", opts = opts }
end

local SECTIONS = {
    {
        title = "Transform",
        icon = "⊞",
        fields = {
            F("x", "X", "number"), F("y", "Y", "number"),
            F("width", "W", "number"), F("height", "H", "number"),
        }
    },
    { title = "Info", icon = "✎", fields = { F("name", "Name", "string") } },
    {
        title = "Appearance",
        icon = "◈",
        fields = {
            F("color", "Color", "color"),
            F("bgImagePath", "BG Image", "image"),
            F("bgNinePath", "BG Nine Path", "enum", { "false", "true" }),
            F("bgNineLeft", "BG Left", "number"),
            F("bgNineTop", "BG Top", "number"),
            F("bgNineRight", "BG Right", "number"),
            F("bgNineBottom", "BG Bottom", "number"),
        }
    },
}

local EXTRA = {
    Canvas      = { {
        title = "Canvas",
        fields = {
            F("active", "Active", "enum", { "true", "false" }),
        }
    } },
    Panel       = { {
        title = "Panel",
        fields = {
            F("cornerRadius", "Radius", "number"),
            F("clip", "Clip Content", "enum", { "false", "true" }),
        }
    } },
    Button      = { {
        title = "Button",
        fields = {
            F("text", "Text", "string"),
            F("fontSize", "Font Size", "number"),
            F("cornerRadius", "Radius", "number"),
            F("textR", "Text R", "number"), F("textG", "Text G", "number"), F("textB", "Text B", "number"),
            F("onClick", "OnClick", "string"),
        }
    } },
    Label       = { {
        title = "Label",
        fields = {
            F("labelText", "Text", "string"),
            F("labelSize", "Font Size", "number"),
            F("labelR", "Text R", "number"), F("labelG", "Text G", "number"), F("labelB", "Text B", "number"),
            F("textAnchor", "Align", "enum", { "CENTER_LEFT", "CENTER", "CENTER_RIGHT" }),
        }
    } },
    TextField   = { {
        title = "TextField",
        fields = {
            F("text", "Text", "string"),
            F("placeholder", "Placeholder", "string"),
            F("fontSize", "Font Size", "number"),
            F("textR", "Text R", "number"), F("textG", "Text G", "number"), F("textB", "Text B", "number"),
            F("cornerRadius", "Radius", "number"),
        }
    } },
    Image       = { {
        title = "Image",
        fields = {
            F("imagePath", "Path", "image"),
        }
    } },
    ScrollView  = { {
        title = "ScrollView",
        fields = {
            F("contentWidth", "Content W", "number"), F("contentHeight", "Content H", "number"),
            F("direction", "Direction", "enum", { "vertical", "horizontal" }),
        }
    } },
    Slider      = { {
        title = "Slider",
        fields = {
            F("sliderMin", "Min", "number"), F("sliderMax", "Max", "number"), F("sliderValue", "Value", "number"),
            F("fillR", "Fill R", "number"), F("fillG", "Fill G", "number"), F("fillB", "Fill B", "number"),
            F("onChange", "OnChange", "string"),
        }
    } },
    Checkbox    = { {
        title = "Checkbox",
        fields = {
            F("text", "Label", "string"),
            F("checked", "Checked", "enum", { "false", "true" }),
            F("checkR", "Check R", "number"), F("checkG", "Check G", "number"), F("checkB", "Check B", "number"),
            F("onChanged", "OnChanged", "string"),
        }
    } },
    RadioButton = { {
        title = "RadioButton",
        fields = {
            F("text", "Label", "string"),
            F("radioGroup", "Group", "string"),
            F("checked", "Selected", "enum", { "false", "true" }),
            F("checkR", "Fill R", "number"), F("checkG", "Fill G", "number"), F("checkB", "Fill B", "number"),
            F("onChanged", "OnChanged", "string"),
        }
    } },
    ProgressBar = { {
        title = "ProgressBar",
        fields = {
            F("progressValue", "Value (0-1)", "number"),
            F("fillR2", "Fill R", "number"), F("fillG2", "Fill G", "number"), F("fillB2", "Fill B", "number"),
            F("showLabel", "Show %", "enum", { "true", "false" }),
        }
    } },
    ListView    = { {
        title = "ListView",
        fields = {
            F("listItems", "Items", "string"),
            F("itemHeight", "Item Height", "number"),
            F("onSelect", "OnSelect", "string"),
        }
    } },
    Tooltip     = { {
        title = "Tooltip",
        fields = {
            F("tooltipText", "Text", "string"),
            F("arrowDir", "Arrow", "enum", { "up", "down", "left", "right", "none" }),
        }
    } },
    ConsoleLog  = { {
        title = "ConsoleLog",
        fields = {
            F("maxEntries", "Max Entries", "number"),
            F("showTimestamps", "Timestamps", "enum", { "false", "true" }),
            F("fontSize", "Font Size", "number"),
        }
    } },
}

-- type badge colors
local TYPE_BADGE = {
    Canvas = "90,200,210",
    Panel = "5,80,160",
    Button = "60,100,200",
    Image = "40,140,70",
    Label = "120,80,180",
    TextField = "80,130,180",
    ScrollView = "100,60,160",
    Slider = "40,150,160",
    Checkbox = "160,130,40",
    RadioButton = "170,90,40",
    ProgressBar = "40,170,90",
    ListView = "80,110,180",
    Tooltip = "150,60,60",
    ConsoleLog = "90,200,140",
}

local function badgeColor(t)
    local s = TYPE_BADGE[t] or "60,60,80"
    local r, g, b = s:match("(%d+),(%d+),(%d+)")
    return tonumber(r), tonumber(g), tonumber(b)
end

-- ─── ctor ────────────────────────────────────────────────────────────────────

function UIInspector:ctor(onOpenPicker, onOpenColorPicker)
    self.onOpenPicker                  = onOpenPicker
    self.onOpenColorPicker             = onOpenColorPicker
    self.widget                        = nil
    self.x                             = SCREEN_WIDTH - W
    self.y                             = 52
    self.height                        = SCREEN_HEIGHT - 52
    self._fields                       = {}
    self._activeKey                    = nil
    self._activeFtype                  = nil
    self._inputBuf                     = ""
    self._cursorPos                    = 0
    self._cursorOn                     = true
    self._cursorT                      = 0
    self._scrollY                      = 0
    self._contentH                     = 0
    self._dragging                     = false
    self._dragStartY                   = 0
    self._dragScrollY                  = 0
    self._hoverRow                     = nil

    self._bg                           = UI.UIPanel.new(self.x, self.y, W, self.height)
    self._bg.r, self._bg.g, self._bg.b = 20, 20, 24
    self._bg.clip                      = false
    self._bg:updateAbsolutePosition(0, 0)
end

-- ─── widget binding ──────────────────────────────────────────────────────────

function UIInspector:setWidget(w)
    self:_stopInput()
    self.widget   = w
    self._scrollY = 0
    self:_buildLayout()
end

function UIInspector:_buildLayout()
    self._fields = {}
    if not self.widget then return end
    local secs = {}
    for _, s in ipairs(SECTIONS) do secs[#secs + 1] = s end
    local extra = EXTRA[self.widget.type]
    if extra then for _, s in ipairs(extra) do secs[#secs + 1] = s end end

    local cy = TITLE_H + 6
    for _, sec in ipairs(secs) do
        self._fields[#self._fields + 1] = { kind = "section", label = sec.title, icon = sec.icon or "⬡", cy = cy }
        cy = cy + SEC_H + 2
        for _, f in ipairs(sec.fields) do
            self._fields[#self._fields + 1] = {
                kind = "field",
                key = f.key,
                label = f.label,
                ftype = f.ftype,
                opts = f
                    .opts,
                cy = cy
            }
            cy = cy + ROW_H + 1
        end
        cy = cy + 6
    end
    self._contentH = cy + PAD
end

-- ─── input ───────────────────────────────────────────────────────────────────

function UIInspector:_startInput(key, ftype)
    if self._activeKey == key then return end
    self:_stopInput()
    self._activeKey   = key
    self._activeFtype = ftype
    self._inputBuf    = tostring(self.widget[key] or "")
    self._cursorPos   = #self._inputBuf
    self._cursorOn    = true
    self._cursorT     = 0
    Input.startInput()
    Input.setInputCallback(function(ch)
        local b         = self._inputBuf
        self._inputBuf  = b:sub(1, self._cursorPos) .. ch .. b:sub(self._cursorPos + 1)
        self._cursorPos = self._cursorPos + #ch
        self._cursorOn  = true; self._cursorT = 0
        self:_liveUpdate()
    end)
end

function UIInspector:_stopInput()
    if not self._activeKey then return end
    self:_commit()
    Input.stopInput()
    Input.clearInputCallback()
    self._activeKey = nil; self._activeFtype = nil
end

function UIInspector:_liveUpdate()
    if not self._activeKey or not self.widget then return end
    if self._activeFtype == "number" then
        local n = tonumber(self._inputBuf)
        if n then self.widget[self._activeKey] = n end
    end
end

function UIInspector:_commit()
    if not self._activeKey or not self.widget then return end
    local row = self:_findField(self._activeKey)
    if not row then return end
    if row.ftype == "number" then
        local n = tonumber(self._inputBuf)
        if n then self.widget[self._activeKey] = n end
    else
        self.widget[self._activeKey] = self._inputBuf
        if self._activeKey == "imagePath" then
            self.widget.component:setImage(self._inputBuf)
        elseif self._activeKey == "bgImagePath" then
            self.widget.component:setBgImage(self._inputBuf)
        end
    end
end

function UIInspector:_findField(key)
    for _, r in ipairs(self._fields) do
        if r.kind == "field" and r.key == key then return r end
    end
end

-- ─── key events ──────────────────────────────────────────────────────────────

function UIInspector:onKeyPressed(key)
    if not self._activeKey then return end
    self._cursorOn = true; self._cursorT = 0
    if key == Input.KEY_BACKSPACE then
        if self._cursorPos > 0 then
            self._inputBuf  = self._inputBuf:sub(1, self._cursorPos - 1) .. self._inputBuf:sub(self._cursorPos + 1)
            self._cursorPos = self._cursorPos - 1
            self:_liveUpdate()
        end
    elseif key == Input.KEY_DELETE then
        if self._cursorPos < #self._inputBuf then
            self._inputBuf = self._inputBuf:sub(1, self._cursorPos) .. self._inputBuf:sub(self._cursorPos + 2)
            self:_liveUpdate()
        end
    elseif key == Input.KEY_LEFT then
        self._cursorPos = math.max(0, self._cursorPos - 1)
    elseif key == Input.KEY_RIGHT then
        self._cursorPos = math.min(#self._inputBuf, self._cursorPos + 1)
    elseif key == Input.KEY_HOME then
        self._cursorPos = 0
    elseif key == Input.KEY_END then
        self._cursorPos = #self._inputBuf
    elseif key == Input.KEY_RETURN or key == Input.KEY_KP_ENTER then
        self:_stopInput()
    elseif key == Input.KEY_ESCAPE then
        self._inputBuf  = tostring(self.widget[self._activeKey] or "")
        self._cursorPos = #self._inputBuf
        Input.stopInput(); Input.clearInputCallback()
        self._activeKey = nil; self._activeFtype = nil
    end
end

function UIInspector:onKeyReleased(key) end

-- ─── pointer ─────────────────────────────────────────────────────────────────

function UIInspector:onPointerPressed(px, py)
    if px < self.x then
        self:_stopInput(); return false
    end

    self._dragging    = true
    self._dragStartY  = py
    self._dragScrollY = self._scrollY

    if not self.widget then return true end

    local localY = py - self.y + self._scrollY

    for _, row in ipairs(self._fields) do
        if row.kind ~= "field" then goto continue end
        if localY >= row.cy and localY <= row.cy + ROW_H then
            if row.ftype == "enum" then
                self:_stopInput()
                local cur = tostring(self.widget[row.key])
                for j, v in ipairs(row.opts) do
                    if v == cur then
                        local nxt = row.opts[(j % #row.opts) + 1]
                        if nxt == "true" then
                            self.widget[row.key] = true
                        elseif nxt == "false" then
                            self.widget[row.key] = false
                        else
                            self.widget[row.key] = nxt
                        end
                        break
                    end
                end
            elseif row.ftype == "color" then
                self:_stopInput()
                if self.onOpenColorPicker then self.onOpenColorPicker() end
            elseif row.ftype == "image" then
                local pickX = self.x + W - PAD - PICK_W
                local ry    = self.y - self._scrollY + row.cy
                if px >= pickX and px <= pickX + PICK_W and py >= ry + 2 and py <= ry + FIELD_H + 2 then
                    self:_stopInput()
                    if self.onOpenPicker then self.onOpenPicker(row.key, tostring(self.widget[row.key] or "")) end
                else
                    self:_startInput(row.key, "string")
                end
            else
                self:_startInput(row.key, row.ftype)
            end
            return true
        end
        ::continue::
    end
    return true
end

function UIInspector:onPointerDragged(px, py)
    if not self._dragging then return end
    local maxS = math.max(0, self._contentH - self.height)
    self._scrollY = math.max(0, math.min(maxS, self._dragScrollY + (self._dragStartY - py)))
end

function UIInspector:onPointerReleased(px, py) self._dragging = false end

function UIInspector:onPointerMoved(px, py)
    self._hoverRow = nil
    if px < self.x then return end
    local localY = py - self.y + self._scrollY
    for _, row in ipairs(self._fields) do
        if row.kind == "field" and localY >= row.cy and localY <= row.cy + ROW_H then
            self._hoverRow = row; break
        end
    end
end

-- ─── update ──────────────────────────────────────────────────────────────────

function UIInspector:update(dt)
    if self._activeKey then
        self._cursorT = self._cursorT + dt
        if self._cursorT >= CURSOR_BLINK then
            self._cursorT  = 0
            self._cursorOn = not self._cursorOn
        end
    end
end

-- ─── render ──────────────────────────────────────────────────────────────────

function UIInspector:render(g)
    self._bg:render(g)

    -- left border
    g:setColor(14, 14, 18, 255)
    g:fillRect(self.x, self.y, 1, self.height)

    -- title bar
    g:setColor(16, 16, 20, 255)
    g:fillRect(self.x, self.y, W, TITLE_H)
    g:setColor(14, 14, 18, 255)
    g:drawLine(self.x, self.y + TITLE_H, self.x + W, self.y + TITLE_H)

    if not self.widget then
        g:setColor(160, 168, 195, 255)
        g:drawString("Inspector", self.x + PAD, self.y + TITLE_H / 2, Graphics.CENTER_LEFT)
        g:setColor(50, 52, 62, 255)
        g:drawString("Select a widget", self.x + W / 2, self.y + self.height / 2 - 10, Graphics.CENTER)
        g:setColor(38, 40, 50, 255)
        g:drawString("to view properties", self.x + W / 2, self.y + self.height / 2 + 10, Graphics.CENTER)
        return
    end

    -- type badge
    local br, bg2, bb = badgeColor(self.widget.type)
    g:setColor(br, bg2, bb, 200)
    local bw = #self.widget.type * 7 + 14
    g:fillRoundRect(self.x + PAD, self.y + TITLE_H / 2 - 10, bw, 20, 5, 5)
    g:setColor(255, 255, 255, 220)
    g:drawString(self.widget.type, self.x + PAD + bw / 2, self.y + TITLE_H / 2, Graphics.CENTER)

    -- widget name (right side of title)
    g:setColor(80, 85, 105, 255)
    g:drawString(self.widget.name, self.x + W - PAD, self.y + TITLE_H / 2, Graphics.CENTER_RIGHT)

    -- clipped scroll area
    g:save()
    g:setClip(self.x, self.y + TITLE_H, W, self.height - TITLE_H)

    local ox = self.x
    local oy = self.y - self._scrollY

    for i, row in ipairs(self._fields) do
        local ry = oy + row.cy

        if row.kind == "section" then
            -- section header bg
            g:setColor(14, 14, 18, 255)
            g:fillRect(ox, ry, W, SEC_H)
            -- left accent
            g:setColor(60, 110, 210, 255)
            g:fillRect(ox, ry, 3, SEC_H)
            -- top/bottom lines
            g:setColor(10, 10, 14, 255)
            g:drawLine(ox, ry, ox + W, ry)
            g:drawLine(ox, ry + SEC_H, ox + W, ry + SEC_H)
            -- label
            g:setColor(140, 155, 195, 255)
            g:drawString(row.label, ox + PAD + 6, ry + SEC_H / 2, Graphics.CENTER_LEFT)
            -- chevron
            g:setColor(60, 65, 85, 255)
            g:drawString("›", ox + W - PAD - 4, ry + SEC_H / 2, Graphics.CENTER_RIGHT)
        elseif row.kind == "field" then
            local isActive  = self._activeKey == row.key
            local isHovered = self._hoverRow == row
            local isImage   = row.ftype == "image"
            local isColor   = row.ftype == "color"
            local isEnum    = row.ftype == "enum"
            local valueX    = ox + PAD + LABEL_W + 6
            local valueW    = isImage and (W - PAD - LABEL_W - PICK_W - PAD * 2 - 6)
                or (W - PAD * 2 - LABEL_W - 6)

            -- row bg
            if isActive then
                g:setColor(22, 38, 68, 255)
            elseif isHovered then
                g:setColor(28, 28, 34, 255)
            elseif i % 2 == 0 then
                g:setColor(22, 22, 26, 255)
            else
                g:setColor(24, 24, 28, 255)
            end
            g:fillRect(ox, ry, W, ROW_H)

            -- active left glow
            if isActive then
                g:setColor(55, 120, 220, 255)
                g:fillRect(ox, ry, 2, ROW_H)
            end

            -- label (right-aligned in label column)
            g:setColor(isActive and 160 or 105, isActive and 170 or 110, isActive and 200 or 135, 255)
            g:drawString(row.label, ox + PAD + LABEL_W, ry + ROW_H / 2, Graphics.CENTER_RIGHT)

            -- divider between label and value
            g:setColor(30, 30, 36, 255)
            g:drawLine(ox + PAD + LABEL_W + 3, ry + 4, ox + PAD + LABEL_W + 3, ry + ROW_H - 4)

            if isColor then
                local wr = self.widget.r or 255
                local wg = self.widget.g or 255
                local wb = self.widget.b or 255
                local wa = self.widget.a or 255
                -- checkerboard
                local CK = 5
                for ci = 0, math.ceil(SWATCH_W / CK) - 1 do
                    local light = (ci % 2 == 0)
                    g:setColor(light and 155 or 95, light and 155 or 95, light and 155 or 95, 255)
                    g:fillRect(valueX + ci * CK, ry + 4, CK, FIELD_H)
                    g:setColor(light and 95 or 155, light and 95 or 155, light and 95 or 155, 255)
                    g:fillRect(valueX + ci * CK, ry + 4 + FIELD_H / 2, CK, FIELD_H / 2)
                end
                g:setColor(wr, wg, wb, wa)
                g:fillRoundRect(valueX, ry + 4, SWATCH_W, FIELD_H, 4, 4)
                g:setColor(0, 0, 0, 80)
                g:drawRoundRect(valueX, ry + 4, SWATCH_W, FIELD_H, 4, 4)
                g:setColor(175, 182, 205, 255)
                g:drawString(string.format("#%02X%02X%02X  A:%d", wr, wg, wb, wa),
                    valueX + SWATCH_W + 7, ry + ROW_H / 2, Graphics.CENTER_LEFT)
            elseif isEnum then
                -- pill-style toggle
                g:setColor(28, 45, 80, 255)
                g:fillRoundRect(valueX, ry + 4, valueW, FIELD_H, 4, 4)
                g:setColor(50, 80, 140, 255)
                g:drawRoundRect(valueX, ry + 4, valueW, FIELD_H, 4, 4)
                g:setColor(160, 195, 255, 255)
                g:drawString("◀  " .. tostring(self.widget[row.key]) .. "  ▶",
                    valueX + valueW / 2, ry + ROW_H / 2, Graphics.CENTER)
            else
                -- text field
                if isActive then
                    g:setColor(18, 32, 60, 255)
                    g:fillRoundRect(valueX, ry + 4, valueW, FIELD_H, 4, 4)
                    g:setColor(55, 115, 220, 255)
                    g:drawRoundRect(valueX, ry + 4, valueW, FIELD_H, 4, 4)
                else
                    g:setColor(28, 28, 34, 255)
                    g:fillRoundRect(valueX, ry + 4, valueW, FIELD_H, 4, 4)
                    g:setColor(38, 38, 46, 255)
                    g:drawRoundRect(valueX, ry + 4, valueW, FIELD_H, 4, 4)
                end

                local display
                if isActive then
                    local b = self._inputBuf
                    display = b:sub(1, self._cursorPos) .. (self._cursorOn and "|" or " ") .. b:sub(self._cursorPos + 1)
                else
                    local val = tostring(self.widget[row.key] or "")
                    display = val:match("([^/\\]+)$") or val
                end
                g:setColor(isActive and 225 or 185, isActive and 232 or 190, isActive and 255 or 210, 255)
                -- clip text inside field
                g:save()
                g:setClip(valueX + 2, ry + 4, valueW - 4, FIELD_H)
                g:drawString(display, valueX + 6, ry + ROW_H / 2, Graphics.CENTER_LEFT)
                g:restore()

                -- pick button
                if isImage then
                    local pickX = ox + W - PAD - PICK_W
                    g:setColor(35, 65, 115, 255)
                    g:fillRoundRect(pickX, ry + 4, PICK_W, FIELD_H, 4, 4)
                    g:setColor(55, 100, 180, 255)
                    g:drawRoundRect(pickX, ry + 4, PICK_W, FIELD_H, 4, 4)
                    g:setColor(150, 190, 255, 255)
                    g:drawString("…", pickX + PICK_W / 2, ry + ROW_H / 2, Graphics.CENTER)
                end
            end

            -- bottom separator
            g:setColor(18, 18, 22, 255)
            g:drawLine(ox + LABEL_W + PAD + 6, ry + ROW_H, ox + W, ry + ROW_H)
        end
    end

    g:restore()

    -- scrollbar
    local maxS = math.max(0, self._contentH - self.height)
    if maxS > 0 then
        local ratio  = (self.height - TITLE_H) / self._contentH
        local thumbH = math.max(28, (self.height - TITLE_H) * ratio)
        local travel = (self.height - TITLE_H) - thumbH
        local thumbY = self.y + TITLE_H + (self._scrollY / maxS) * travel
        g:setColor(14, 14, 18, 255)
        g:fillRect(self.x + W - 6, self.y + TITLE_H, 6, self.height - TITLE_H)
        g:setColor(55, 58, 72, 220)
        g:fillRoundRect(self.x + W - 5, thumbY + 2, 4, thumbH - 4, 2, 2)
    end
end

return UIInspector

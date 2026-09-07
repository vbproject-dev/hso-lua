local UIComponent = require("gfx.ui.components.UIComponent")
local UITextField = class("UITextField", UIComponent)

local CURSOR_BLINK = 0.5
local focusedField = nil

function UITextField:ctor(x, y, width, height)
    UITextField.super.ctor(self, x, y, width, height)
    self.text = ""
    self.placeholder = ""
    self.r = 40
    self.g = 40
    self.b = 40
    self.a = 255
    self.textR = 255
    self.textG = 255
    self.textB = 255
    self.fontSize = 16
    self.cornerRadius = 4
    self.focused = false
    self._cursorPos = 0
    self._cursorTimer = 0
    self._cursorOn = true
    self.onSubmit = nil
    self.onChange = nil
end

function UITextField:focus()
    if focusedField == self then return end

    if focusedField then
        focusedField:blur()
    end

    focusedField = self
    self.focused = true
    self._cursorPos = #self.text
    self._cursorTimer = 0
    self._cursorOn = true

    Input.startInput()
    Input.setInputCallback(function(ch)
        if focusedField == self then
            self:_insert(ch)
        end
    end)
end

function UITextField:blur()
    if focusedField ~= self then return end

    self.focused = false
    focusedField = nil

    Input.stopInput()
    Input.clearInputCallback()
end

function UITextField:_insert(ch)
    local before = self.text:sub(1, self._cursorPos)
    local after = self.text:sub(self._cursorPos + 1)
    self.text = before .. ch .. after
    self._cursorPos = self._cursorPos + #ch
    self._cursorOn = true
    self._cursorTimer = 0
    if self.onChange then self.onChange(self, self.text) end
end

function UITextField:_backspace()
    if self._cursorPos == 0 then return end
    local before = self.text:sub(1, self._cursorPos - 1)
    local after = self.text:sub(self._cursorPos + 1)
    self.text = before .. after
    self._cursorPos = math.max(0, self._cursorPos - 1)
    if self.onChange then self.onChange(self, self.text) end
end

function UITextField:_delete()
    if self._cursorPos >= #self.text then return end
    local before = self.text:sub(1, self._cursorPos)
    local after = self.text:sub(self._cursorPos + 2)
    self.text = before .. after
    if self.onChange then self.onChange(self, self.text) end
end

function UITextField:onKeyPressed(key)
    if not self.focused then return end

    self._cursorOn = true
    self._cursorTimer = 0

    if key == Input.KEY_BACKSPACE then
        self:_backspace()
    elseif key == Input.KEY_DELETE then
        self:_delete()
    elseif key == Input.KEY_LEFT then
        self._cursorPos = math.max(0, self._cursorPos - 1)
    elseif key == Input.KEY_RIGHT then
        self._cursorPos = math.min(#self.text, self._cursorPos + 1)
    elseif key == Input.KEY_HOME then
        self._cursorPos = 0
    elseif key == Input.KEY_END then
        self._cursorPos = #self.text
    elseif key == Input.KEY_RETURN or key == Input.KEY_KP_ENTER then
        local text = self.text
        self:blur()
        if self.onSubmit then self.onSubmit(self, text) end
    elseif key == Input.KEY_ESCAPE then
        self:blur()
    end
end

function UITextField:onPointerPressed(px, py)
    if self:contains(px, py) then
        self:focus()
        return true
    end
    self:blur()
    return false
end

function UITextField:update(dt)
    if not self.focused then return end

    self._cursorTimer = self._cursorTimer + dt
    if self._cursorTimer >= CURSOR_BLINK then
        self._cursorTimer = 0
        self._cursorOn = not self._cursorOn
    end
end

function UITextField:draw(g)
    local PAD = 6
    if not self._bgImage then
        g:setColor(self.r, self.g, self.b, self.a)
        g:fillRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)

        if self.focused then
            g:setColor(80, 140, 220, 255)
        else
            g:setColor(80, 80, 80, 255)
        end

        g:drawRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)
    end
    local ty = self._absY + self.height / 2

    if self.focused then
        local before = self.text:sub(1, self._cursorPos)
        local after = self.text:sub(self._cursorPos + 1)
        local display = before .. (self._cursorOn and "|" or " ") .. after
        g:setColor(self.textR, self.textG, self.textB, 255)
        g:drawString(display, self._absX + PAD, ty, Graphics.CENTER_LEFT)
    elseif self.text ~= "" then
        g:setColor(self.textR, self.textG, self.textB, 255)
        g:drawString(self.text, self._absX + PAD, ty, Graphics.CENTER_LEFT)
    else
        g:setColor(100, 100, 100, 255)
        g:drawString(self.placeholder, self._absX + PAD, ty, Graphics.CENTER_LEFT)
    end
end

function UITextField:dispose()
    if focusedField == self then
        self:blur()
    end
    UITextField.super.dispose(self)
end

return UITextField

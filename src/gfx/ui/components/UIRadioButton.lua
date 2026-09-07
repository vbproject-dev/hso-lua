local UIComponent = require("gfx.ui.components.UIComponent")
local UIRadioButton = class("UIRadioButton", UIComponent)

function UIRadioButton:ctor(x, y, width, height)
    UIRadioButton.super.ctor(self, x, y, width, height)
    self.selected   = false
    self.text       = "Option"
    self.group      = "default"   -- group name; UIRadioButton.groups[group] = list
    self.r          = 50
    self.g          = 50
    self.b          = 50
    self.a          = 255
    self.fillR      = 70
    self.fillG      = 130
    self.fillB      = 220
    self.textR      = 220
    self.textG      = 220
    self.textB      = 220
    self.dotSize    = 18
    self.onChanged  = nil
    self._pressed   = false
end

function UIRadioButton:draw(g)
    local r  = self.dotSize / 2
    local cx = self._absX + r
    local cy = self._absY + self.height / 2

    -- outer circle
    if self.selected then
        g:setColor(self.fillR, self.fillG, self.fillB, self.a)
    else
        g:setColor(self.r, self.g, self.b, self.a)
    end
    g:fillCircle(cx, cy, r)

    -- border
    if self.selected then
        g:setColor(math.max(0,self.fillR-30), math.max(0,self.fillG-30), math.max(0,self.fillB-30), 255)
    else
        g:setColor(80, 80, 88, 255)
    end
    g:drawCircle(cx, cy, r)

    -- inner dot
    if self.selected then
        g:setColor(255, 255, 255, 255)
        g:fillCircle(cx, cy, r - 5)
    end

    -- label
    g:setColor(self.textR, self.textG, self.textB, 255)
    g:drawString(self.text, self._absX + self.dotSize + 8, self._absY + self.height / 2, Graphics.CENTER_LEFT)
end

function UIRadioButton:onPointerPressed(px, py)
    if self:contains(px, py) then
        self._pressed = true
        return true
    end
    return false
end

function UIRadioButton:onPointerReleased(px, py)
    if self._pressed and self:contains(px, py) then
        self.selected = true
        if self.onChanged then self.onChanged(self) end
    end
    self._pressed = false
end

return UIRadioButton

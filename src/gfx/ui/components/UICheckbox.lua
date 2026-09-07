local UIComponent = require("gfx.ui.components.UIComponent")
local UICheckbox = class("UICheckbox", UIComponent)

function UICheckbox:ctor(x, y, width, height)
    UICheckbox.super.ctor(self, x, y, width, height)
    self.checked    = false
    self.text       = "Checkbox"
    self.r          = 50
    self.g          = 50
    self.b          = 50
    self.a          = 255
    self.checkR     = 70
    self.checkG     = 130
    self.checkB     = 220
    self.textR      = 220
    self.textG      = 220
    self.textB      = 220
    self.boxSize    = 18
    self.onChanged  = nil
    self._pressed   = false
end

function UICheckbox:draw(g)
    local bx = self._absX
    local by = self._absY + (self.height - self.boxSize) / 2
    local bs = self.boxSize

    -- box bg
    if self.checked then
        g:setColor(self.checkR, self.checkG, self.checkB, self.a)
    else
        g:setColor(self.r, self.g, self.b, self.a)
    end
    g:fillRoundRect(bx, by, bs, bs, 4, 4)

    -- border
    if self.checked then
        g:setColor(
            math.max(0, self.checkR - 30),
            math.max(0, self.checkG - 30),
            math.max(0, self.checkB - 30), 255)
    else
        g:setColor(80, 80, 88, 255)
    end
    g:drawRoundRect(bx, by, bs, bs, 4, 4)

    -- checkmark
    if self.checked then
        g:setColor(255, 255, 255, 255)
        local cx = bx + bs / 2
        local cy = by + bs / 2
        -- draw a tick: two lines
        g:drawLine(bx + 3, by + bs/2, bx + bs/2 - 1, by + bs - 4)
        g:drawLine(bx + bs/2 - 1, by + bs - 4, bx + bs - 3, by + 4)
        g:drawLine(bx + 3, by + bs/2 + 1, bx + bs/2 - 1, by + bs - 3)
        g:drawLine(bx + bs/2 - 1, by + bs - 3, bx + bs - 3, by + 5)
    end

    -- label
    g:setColor(self.textR, self.textG, self.textB, 255)
    g:drawString(self.text, bx + bs + 8, self._absY + self.height / 2, Graphics.CENTER_LEFT)
end

function UICheckbox:onPointerPressed(px, py)
    if self:contains(px, py) then
        self._pressed = true
        return true
    end
    return false
end

function UICheckbox:onPointerReleased(px, py)
    if self._pressed and self:contains(px, py) then
        self.checked = not self.checked
        if self.onChanged then self.onChanged(self.checked) end
    end
    self._pressed = false
end

return UICheckbox

local UIComponent = require("gfx.ui.components.UIComponent")
local UIButton = class("UIButton", UIComponent)

function UIButton:ctor(x, y, width, height)
    UIButton.super.ctor(self, x, y, width, height)
    self.text         = "Button"
    self.r            = 70
    self.g            = 70
    self.b            = 70
    self.a            = 255
    self.textR        = 255
    self.textG        = 255
    self.textB        = 255
    self.fontSize     = 16
    self.cornerRadius = 6
    self._pressed     = false
    self.onClick      = nil
end

function UIButton:draw(g)
    if self._bgImage then
        self:_drawBgImage(g)
    else
        local dr = self._pressed and -20 or 0
        g:setColor(self.r + dr, self.g + dr, self.b + dr, self.a)
        g:fillRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)
        self:_drawBgImage(g)
        g:setColor(math.max(0, self.r - 30), math.max(0, self.g - 30), math.max(0, self.b - 30), self.a)
        g:drawRoundRect(self._absX, self._absY, self.width, self.height, self.cornerRadius, self.cornerRadius)
    end
    g:setColor(self.textR, self.textG, self.textB, 255)
    g:drawString(self.text, self._absX + self.width / 2, self._absY + self.height / 2, Graphics.CENTER)
end

-- override render so bgImage is NOT drawn twice (we call it manually in draw)
function UIButton:render(g)
    if not self.visible then return end
    self:draw(g)
    for _, c in ipairs(self.children) do
        if c.visible then c:render(g) end
    end
end

function UIButton:onPointerPressed(px, py)
    if self:contains(px, py) then
        self._pressed = true
        return true
    end
    return false
end

function UIButton:onPointerReleased(px, py)
    if self._pressed then
        self._pressed = false
        if self:contains(px, py) and self.onClick then
            self.onClick(self)
        end
    end
end

return UIButton

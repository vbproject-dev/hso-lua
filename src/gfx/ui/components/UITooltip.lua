local UIComponent = require("gfx.ui.components.UIComponent")
local UITooltip = class("UITooltip", UIComponent)

function UITooltip:ctor(x, y, width, height)
    UITooltip.super.ctor(self, x, y, width, height)
    self.text       = "Tooltip"
    self.r          = 40
    self.g          = 40
    self.b          = 44
    self.a          = 230
    self.textR      = 220
    self.textG      = 220
    self.textB      = 228
    self.borderR    = 80
    self.borderG    = 130
    self.borderB    = 220
    self.padding    = 8
    self.arrowSize  = 6
    self.visible    = false   -- shown on demand
end

function UITooltip:show(text, x, y)
    self.text    = text or self.text
    self.x       = x or self.x
    self.y       = y or self.y
    self.visible = true
    self:updateAbsolutePosition(0, 0)
end

function UITooltip:hide()
    self.visible = false
end

function UITooltip:draw(g)
    local pad = self.padding
    local ax  = self._absX
    local ay  = self._absY

    -- shadow
    g:setColor(0, 0, 0, 80)
    g:fillRoundRect(ax + 2, ay + 2, self.width, self.height, 5, 5)

    -- bg
    g:setColor(self.r, self.g, self.b, self.a)
    g:fillRoundRect(ax, ay, self.width, self.height, 5, 5)

    -- border
    g:setColor(self.borderR, self.borderG, self.borderB, 200)
    g:drawRoundRect(ax, ay, self.width, self.height, 5, 5)

    -- arrow (pointing down from bottom center)
    local arrowX = ax + self.width / 2
    local arrowY = ay + self.height
    g:setColor(self.r, self.g, self.b, self.a)
    g:fillTriangle(
        arrowX - self.arrowSize, arrowY,
        arrowX + self.arrowSize, arrowY,
        arrowX, arrowY + self.arrowSize
    )
    g:setColor(self.borderR, self.borderG, self.borderB, 200)
    g:drawLine(arrowX - self.arrowSize, arrowY, arrowX, arrowY + self.arrowSize)
    g:drawLine(arrowX, arrowY + self.arrowSize, arrowX + self.arrowSize, arrowY)

    -- text
    g:setColor(self.textR, self.textG, self.textB, 255)
    g:drawString(self.text, ax + self.width/2, ay + self.height/2, Graphics.CENTER)
end

return UITooltip

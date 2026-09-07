local UIComponent = require("gfx.ui.components.UIComponent")
local UIProgressBar = class("UIProgressBar", UIComponent)

function UIProgressBar:ctor(x, y, width, height)
    UIProgressBar.super.ctor(self, x, y, width, height)
    self.value      = 0.5    -- 0.0 to 1.0
    self.r          = 40
    self.g          = 40
    self.b          = 40
    self.a          = 255
    self.fillR      = 70
    self.fillG      = 180
    self.fillB      = 100
    self.showText   = true
    self.text       = ""     -- if empty, shows percentage
    self.cornerRadius = 4
end

function UIProgressBar:draw(g)
    local v  = math.max(0, math.min(1, self.value))
    local cr = self.cornerRadius

    -- track
    g:setColor(self.r, self.g, self.b, self.a)
    g:fillRoundRect(self._absX, self._absY, self.width, self.height, cr, cr)

    -- fill
    local fw = math.max(cr * 2, v * self.width)
    g:setColor(self.fillR, self.fillG, self.fillB, self.a)
    g:fillRoundRect(self._absX, self._absY, fw, self.height, cr, cr)

    -- shine overlay
    g:setColor(255, 255, 255, 25)
    g:fillRoundRect(self._absX, self._absY, self.width, self.height / 2, cr, cr)

    -- border
    g:setColor(
        math.max(0, self.r - 20),
        math.max(0, self.g - 20),
        math.max(0, self.b - 20), 200)
    g:drawRoundRect(self._absX, self._absY, self.width, self.height, cr, cr)

    -- label
    if self.showText then
        local label = self.text ~= "" and self.text or string.format("%.0f%%", v * 100)
        -- shadow
        g:setColor(0, 0, 0, 120)
        g:drawString(label, self._absX + self.width/2 + 1, self._absY + self.height/2 + 1, Graphics.CENTER)
        g:setColor(255, 255, 255, 230)
        g:drawString(label, self._absX + self.width/2, self._absY + self.height/2, Graphics.CENTER)
    end
end

return UIProgressBar

local UIComponent = require("gfx.ui.components.UIComponent")
local UIPanel = class("UIPanel", UIComponent)

function UIPanel:ctor(x, y, width, height)
    UIPanel.super.ctor(self, x, y, width, height)
    self.r    = 50
    self.g    = 50
    self.b    = 50
    self.a    = 255
    self.clip = true
end

function UIPanel:draw(g)
    g:setColor(self.r, self.g, self.b, self.a)
    g:fillRect(self._absX, self._absY, self.width, self.height)
end

function UIPanel:render(g)
    if not self.visible then return end
    self:draw(g)
    self:_drawBgImage(g)
    if self.clip then
        g:save()
        g:setClip(self._absX, self._absY, self.width, self.height)
    end
    for _, c in ipairs(self.children) do
        if c.visible then c:render(g) end
    end
    if self.clip then
        g:restore()
    end
end

return UIPanel

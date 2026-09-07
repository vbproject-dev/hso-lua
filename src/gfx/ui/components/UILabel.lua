local UIComponent = require("gfx.ui.components.UIComponent")
local UILabel = class("UILabel", UIComponent)

function UILabel:ctor(x, y, width, height)
    UILabel.super.ctor(self, x, y, width, height)
    self.text       = ""
    self.textR      = 255
    self.textG      = 255
    self.textB      = 255
    self.textA      = 255
    self.fontSize   = 16
    self.textAnchor = Graphics.CENTER_LEFT
end

function UILabel:draw(g)
    local font = g:getFont()
    font:setFontSize(self.fontSize)
    g:setColor(self.textR, self.textG, self.textB, self.textA)

    local tx = self._absX
    local ty = self._absY + self.height / 2

    if self.textAnchor == Graphics.TOP_LEFT then
        tx = self._absX
        ty = self._absY
    elseif self.textAnchor == Graphics.TOP_CENTER then
        tx = self._absX + self.width / 2
        ty = self._absY
    elseif self.textAnchor == Graphics.TOP_RIGHT then
        tx = self._absX + self.width
        ty = self._absY
    elseif self.textAnchor == Graphics.CENTER_LEFT then
        tx = self._absX
        ty = self._absY + self.height / 2
    elseif self.textAnchor == Graphics.CENTER then
        tx = self._absX + self.width / 2
        ty = self._absY + self.height / 2
    elseif self.textAnchor == Graphics.CENTER_RIGHT then
        tx = self._absX + self.width
        ty = self._absY + self.height / 2
    elseif self.textAnchor == Graphics.BOTTOM_LEFT then
        tx = self._absX
        ty = self._absY + self.height
    elseif self.textAnchor == Graphics.BOTTOM_CENTER then
        tx = self._absX + self.width / 2
        ty = self._absY + self.height
    elseif self.textAnchor == Graphics.BOTTOM_RIGHT then
        tx = self._absX + self.width
        ty = self._absY + self.height
    end

    g:drawString(
        self.text,
        tx,
        ty,
        self.textAnchor
    )
end

return UILabel

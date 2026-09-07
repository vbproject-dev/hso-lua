local UIComponent = require("gfx.ui.components.UIComponent")
local UISlider = class("UISlider", UIComponent)

function UISlider:ctor(x, y, width, height)
    UISlider.super.ctor(self, x, y, width, height)
    self.min          = 0
    self.max          = 100
    self.value        = 50
    self.r            = 60
    self.g            = 60
    self.b            = 60
    self.a            = 255
    self.trackR       = 50
    self.trackG       = 50
    self.trackB       = 50
    self.fillR        = 70
    self.fillG        = 130
    self.fillB        = 220
    self.thumbR       = 255
    self.thumbG       = 255
    self.thumbB       = 255
    self.thumbRadius  = 8
    self.trackHeight  = 6
    self.showValue    = true
    self.onChange     = nil
    self._dragging    = false
end

function UISlider:_trackY()
    return self._absY + self.height / 2
end

function UISlider:_thumbX()
    local t = (self.value - self.min) / math.max(0.0001, self.max - self.min)
    return self._absX + self.thumbRadius + t * (self.width - self.thumbRadius * 2)
end

function UISlider:_valueFromX(px)
    local t = (px - self._absX - self.thumbRadius) / math.max(1, self.width - self.thumbRadius * 2)
    t = math.max(0, math.min(1, t))
    return self.min + t * (self.max - self.min)
end

function UISlider:draw(g)
    local ty  = self:_trackY()
    local th  = self.trackHeight
    local tx  = self._absX + self.thumbRadius
    local tw  = self.width - self.thumbRadius * 2
    local thX = self:_thumbX()
    local t   = (self.value - self.min) / math.max(0.0001, self.max - self.min)

    -- track bg
    g:setColor(self.trackR, self.trackG, self.trackB, self.a)
    g:fillRoundRect(tx, ty - th/2, tw, th, th/2, th/2)

    -- fill
    g:setColor(self.fillR, self.fillG, self.fillB, self.a)
    g:fillRoundRect(tx, ty - th/2, math.max(th, t * tw), th, th/2, th/2)

    -- thumb shadow
    g:setColor(0, 0, 0, 60)
    g:fillCircle(thX + 1, ty + 1, self.thumbRadius)

    -- thumb
    g:setColor(self.fillR, self.fillG, self.fillB, 255)
    g:fillCircle(thX, ty, self.thumbRadius)
    g:setColor(self.thumbR, self.thumbG, self.thumbB, 255)
    g:fillCircle(thX, ty, self.thumbRadius - 2)

    -- value label
    if self.showValue then
        local disp = string.format("%.0f", self.value)
        g:setColor(200, 200, 205, 255)
        g:drawString(disp, self._absX + self.width + 6, ty, Graphics.CENTER_LEFT)
    end
end

function UISlider:onPointerPressed(px, py)
    if self:contains(px, py) then
        self._dragging = true
        self.value = self:_valueFromX(px)
        if self.onChange then self.onChange(self.value) end
        return true
    end
    return false
end

function UISlider:onPointerDragged(px, py)
    if self._dragging then
        self.value = self:_valueFromX(px)
        if self.onChange then self.onChange(self.value) end
    end
end

function UISlider:onPointerReleased(px, py)
    self._dragging = false
end

return UISlider

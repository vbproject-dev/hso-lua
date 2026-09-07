local UIComponent = require("gfx.ui.components.UIComponent")
local UIListView  = class("UIListView", UIComponent)

local ITEM_H      = 32
local PAD         = 8

function UIListView:ctor(x, y, width, height)
    UIListView.super.ctor(self, x, y, width, height)
    self.items         = {} -- list of strings
    self.selectedIndex = 0
    self.r             = 30
    self.g             = 30
    self.b             = 32
    self.a             = 255
    self.itemR         = 38
    self.itemG         = 38
    self.itemB         = 42
    self.selR          = 40
    self.selG          = 80
    self.selB          = 150
    self.textR         = 200
    self.textG         = 200
    self.textB         = 205
    self.selTextR      = 220
    self.selTextG      = 232
    self.selTextB      = 255
    self.itemHeight    = ITEM_H
    self.onSelect      = nil -- callback(index, item)
    self._scrollY      = 0
    self._dragging     = false
    self._dragStartY   = 0
    self._dragScrollY  = 0
    self._dragMoved    = false
end

function UIListView:setItems(list)
    self.items = list
    self.selectedIndex = 0
    self._scrollY = 0
end

function UIListView:addItem(item)
    self.items[#self.items + 1] = item
end

function UIListView:_totalH()
    return #self.items * self.itemHeight
end

function UIListView:_maxScroll()
    return math.max(0, self:_totalH() - self.height)
end

function UIListView:draw(g)
    -- background
    g:setColor(self.r, self.g, self.b, self.a)
    g:fillRoundRect(self._absX, self._absY, self.width, self.height, 4, 4)
    g:setColor(math.max(0, self.r - 10), math.max(0, self.g - 10), math.max(0, self.b - 10), 200)
    g:drawRoundRect(self._absX, self._absY, self.width, self.height, 4, 4)

    g:save()
    g:setClip(self._absX, self._absY, self.width, self.height)

    for i, item in ipairs(self.items) do
        local iy = self._absY + (i - 1) * self.itemHeight - self._scrollY
        if iy + self.itemHeight >= self._absY and iy <= self._absY + self.height then
            local isSel = i == self.selectedIndex
            if isSel then
                g:setColor(self.selR, self.selG, self.selB, 255)
                g:fillRect(self._absX + 1, iy, self.width - 2, self.itemHeight)
            elseif i % 2 == 0 then
                g:setColor(self.itemR + 4, self.itemG + 4, self.itemB + 4, 255)
                g:fillRect(self._absX + 1, iy, self.width - 2, self.itemHeight)
            end

            -- separator
            g:setColor(math.max(0, self.r - 8), math.max(0, self.g - 8), math.max(0, self.b - 8), 180)
            g:drawLine(self._absX + PAD, iy + self.itemHeight - 1,
                self._absX + self.width - PAD, iy + self.itemHeight - 1)

            if isSel then
                g:setColor(self.selTextR, self.selTextG, self.selTextB, 255)
            else
                g:setColor(self.textR, self.textG, self.textB, 255)
            end
            g:drawString(tostring(item), self._absX + PAD, iy + self.itemHeight / 2, Graphics.CENTER_LEFT)
        end
    end

    g:restore()

    -- scrollbar
    local maxS = self:_maxScroll()
    if maxS > 0 then
        local ratio  = self.height / self:_totalH()
        local thumbH = math.max(20, self.height * ratio)
        local travel = self.height - thumbH
        local thumbY = self._absY + (self._scrollY / maxS) * travel
        g:setColor(50, 50, 56, 200)
        g:fillRect(self._absX + self.width - 5, self._absY, 5, self.height)
        g:setColor(100, 100, 110, 220)
        g:fillRoundRect(self._absX + self.width - 4, thumbY, 3, thumbH, 2, 2)
    end
end

function UIListView:onPointerPressed(px, py)
    if not self:contains(px, py) then return false end
    self._dragging    = true
    self._dragStartY  = py
    self._dragScrollY = self._scrollY
    self._dragMoved   = false
    return true
end

function UIListView:onPointerDragged(px, py)
    if not self._dragging then return end
    local dy = math.abs(py - self._dragStartY)
    if dy > 4 then self._dragMoved = true end
    self._scrollY = math.max(0, math.min(self:_maxScroll(),
        self._dragScrollY + (self._dragStartY - py)))
end

function UIListView:onPointerReleased(px, py)
    if self._dragging and not self._dragMoved and self:contains(px, py) then
        local localY = py - self._absY + self._scrollY
        local idx    = math.floor(localY / self.itemHeight) + 1
        if idx >= 1 and idx <= #self.items then
            self.selectedIndex = idx
            if self.onSelect then self.onSelect(idx, self.items[idx]) end
        end
    end
    self._dragging = false
end

function UIListView:onScrolled(scrollX, scrollY)
    if not self:contains(scrollX, scrollY) then return false end

    self._scrollY = math.max(0, math.min(self:_maxScroll(), self._scrollY - scrollY * self.itemHeight))
    return true
end

return UIListView

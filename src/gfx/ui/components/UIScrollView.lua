local UIPanel = require("gfx.ui.components.UIPanel")
local UIScrollView = class("UIScrollView", UIPanel)

local SCROLLBAR_W = 6
local MIN_THUMB = 20
local MAX_OVERSCROLL = 80
local BOUNCE_SPEED = 12
local BOUNCE_DAMPING = 0.75

function UIScrollView:ctor(x, y, width, height)
    UIScrollView.super.ctor(self, x, y, width, height)

    self.contentWidth = width
    self.contentHeight = height
    self.direction = "vertical"

    self._scrollX = 0
    self._scrollY = 0

    self._draggingScroll = false
    self._dragStartX = 0
    self._dragStartY = 0
    self._dragScrollX = 0
    self._dragScrollY = 0

    self._bouncing = false
end

function UIScrollView:_maxScrollX()
    return math.max(0, self.contentWidth - self.width)
end

function UIScrollView:_maxScrollY()
    return math.max(0, self.contentHeight - self.height)
end

function UIScrollView:scrollTo(x, y)
    self._scrollX = math.max(0, math.min(x, self:_maxScrollX()))
    self._scrollY = math.max(0, math.min(y, self:_maxScrollY()))
    self:_updateChildPositions()
end

function UIScrollView:_setScroll(x, y)
    self._scrollX = x
    self._scrollY = y
    self:_updateChildPositions()
end

function UIScrollView:_updateChildPositions()
    local x = self._absX - self._scrollX
    local y = self._absY - self._scrollY

    for _, c in ipairs(self.children) do
        c:updateAbsolutePosition(x, y)
    end
end

function UIScrollView:addChild(child)
    child.parent = self
    self.children[#self.children + 1] = child
    child:updateAbsolutePosition(self._absX - self._scrollX, self._absY - self._scrollY)
    return child
end

function UIScrollView:updateAbsolutePosition(parentAbsX, parentAbsY)
    local ox, oy = self:getDrawOrigin()

    self._absX = (parentAbsX or 0) + ox
    self._absY = (parentAbsY or 0) + oy

    self:_updateChildPositions()
end

function UIScrollView:update(dt)
    UIScrollView.super.update(self, dt)

    if self._draggingScroll or not self._bouncing then return end

    local maxX = self:_maxScrollX()
    local maxY = self:_maxScrollY()

    local targetX = math.max(0, math.min(self._scrollX, maxX))
    local targetY = math.max(0, math.min(self._scrollY, maxY))

    local dx = targetX - self._scrollX
    local dy = targetY - self._scrollY
    local factor = math.min(1, BOUNCE_SPEED * dt)

    self._scrollX = self._scrollX + dx * factor
    self._scrollY = self._scrollY + dy * factor

    if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
        self._scrollX = targetX
        self._scrollY = targetY
        self._bouncing = false
    end

    self:_updateChildPositions()
end

function UIScrollView:onPointerPressed(px, py)
    if not self:contains(px, py) then return false end

    self._bouncing = false
    self._draggingScroll = true
    self._dragStartX = px
    self._dragStartY = py
    self._dragScrollX = self._scrollX
    self._dragScrollY = self._scrollY

    UIScrollView.super.onPointerPressed(self, px, py)
    return true
end

function UIScrollView:onPointerDragged(px, py)
    if not self._draggingScroll then return end

    if self.direction == "vertical" then
        local scroll = self._dragScrollY + self._dragStartY - py
        local max = self:_maxScrollY()

        if scroll < 0 then
            scroll = scroll * 0.35
        elseif scroll > max then
            scroll = max + (scroll - max) * 0.35
        end

        self._scrollY = math.max(-MAX_OVERSCROLL, math.min(max + MAX_OVERSCROLL, scroll))
    else
        local scroll = self._dragScrollX + self._dragStartX - px
        local max = self:_maxScrollX()

        if scroll < 0 then
            scroll = scroll * 0.35
        elseif scroll > max then
            scroll = max + (scroll - max) * 0.35
        end

        self._scrollX = math.max(-MAX_OVERSCROLL, math.min(max + MAX_OVERSCROLL, scroll))
    end

    self:_updateChildPositions()
end

function UIScrollView:onPointerReleased(px, py)
    if not self._draggingScroll then return end

    self._draggingScroll = false

    local maxX = self:_maxScrollX()
    local maxY = self:_maxScrollY()

    self._bouncing = self._scrollX < 0 or self._scrollX > maxX or self._scrollY < 0 or self._scrollY > maxY

    UIScrollView.super.onPointerReleased(self, px, py)
end

function UIScrollView:render(g)
    if not self.visible then return end

    self:draw(g)

    g:save()
    g:setClip(self._absX, self._absY, self.width, self.height)

    for _, c in ipairs(self.children) do
        if c.visible then c:render(g) end
    end

    g:restore()

    self:_drawScrollbar(g)
end

function UIScrollView:_drawScrollbar(g)
    if self.direction == "vertical" then
        local maxScroll = self:_maxScrollY()
        if maxScroll <= 0 then return end
        local ratio = self.height / self.contentHeight
        local thumbH = math.max(MIN_THUMB, self.height * ratio)
        local travel = self.height - thumbH
        local scroll = math.max(0, math.min(self._scrollY, maxScroll))
        local thumbY = self._absY + (scroll / maxScroll) * travel
        local bx = self._absX + self.width - SCROLLBAR_W - 2
        g:setColor(0, 0, 0, 80)
        g:fillRect(bx, self._absY, SCROLLBAR_W, self.height)
        g:setColor(160, 160, 160, 200)
        g:fillRoundRect(bx, thumbY, SCROLLBAR_W, thumbH, 3, 3)
    else
        local maxScroll = self:_maxScrollX()
        if maxScroll <= 0 then return end
        local ratio = self.width / self.contentWidth
        local thumbW = math.max(MIN_THUMB, self.width * ratio)
        local travel = self.width - thumbW
        local scroll = math.max(0, math.min(self._scrollX, maxScroll))
        local thumbX = self._absX + (scroll / maxScroll) * travel
        local by = self._absY + self.height - SCROLLBAR_W - 2
        g:setColor(0, 0, 0, 80)
        g:fillRect(self._absX, by, self.width, SCROLLBAR_W)
        g:setColor(160, 160, 160, 200)
        g:fillRoundRect(thumbX, by, thumbW, SCROLLBAR_W, 3, 3)
    end
end

return UIScrollView

-- UIComponent: base class for all UI components
local UIComponent = class("UIComponent")

local ANCHOR_OFFSET = {
    [Graphics.TOP_LEFT]      = { 0, 0 },
    [Graphics.TOP_CENTER]    = { 0.5, 0 },
    [Graphics.TOP_RIGHT]     = { 1, 0 },
    [Graphics.CENTER_LEFT]   = { 0, 0.5 },
    [Graphics.CENTER]        = { 0.5, 0.5 },
    [Graphics.CENTER_RIGHT]  = { 1, 0.5 },
    [Graphics.BOTTOM_LEFT]   = { 0, 1 },
    [Graphics.BOTTOM_CENTER] = { 0.5, 1 },
    [Graphics.BOTTOM_RIGHT]  = { 1, 1 },
}

UIComponent.ANCHOR_OFFSET = ANCHOR_OFFSET

function UIComponent:ctor(x, y, width, height)
    self.x            = x or 0
    self.y            = y or 0
    self.width        = width or 100
    self.height       = height or 40
    self.anchor       = Graphics.TOP_LEFT
    self.visible      = true
    self.name         = ""
    self.parent       = nil
    self.children     = {}
    self._absX        = 0
    self._absY        = 0
    self.bgImagePath  = ""
    self._bgImage     = nil
    self._bgLoaded    = false

    self.bgNinePath   = false
    self.bgNineLeft   = 8
    self.bgNineTop    = 8
    self.bgNineRight  = 8
    self.bgNineBottom = 8
end

function UIComponent:setNinePath(enabled, left, top, right, bottom)
    self.bgNinePath = enabled or false
    self.bgNineLeft = left or 0
    self.bgNineTop = top or 0
    self.bgNineRight = right or 0
    self.bgNineBottom = bottom or 0
end

-- ─── anchor ──────────────────────────────────────────────────────────────────

function UIComponent:getDrawOrigin()
    local off = ANCHOR_OFFSET[self.anchor] or { 0, 0 }
    return self.x - off[1] * self.width,
        self.y - off[2] * self.height
end

-- ─── absolute position ───────────────────────────────────────────────────────

function UIComponent:updateAbsolutePosition(parentAbsX, parentAbsY)
    local ox, oy = self:getDrawOrigin()
    self._absX = (parentAbsX or 0) + ox
    self._absY = (parentAbsY or 0) + oy
    for _, child in ipairs(self.children) do
        child:updateAbsolutePosition(self._absX, self._absY)
    end
end

-- ─── background image ────────────────────────────────────────────────────────

function UIComponent:setBgImage(path)
    self.bgImagePath = path or ""
    self._bgImage    = nil
    self._bgLoaded   = false
end

function UIComponent:_loadBgImage()
    if self._bgLoaded then return end
    self._bgLoaded = true
    if self.bgImagePath == "" then return end
    local ok, img = pcall(function() return Image.createImage(self.bgImagePath) end)
    if ok then self._bgImage = img end
end

function UIComponent:_drawBgImage(g)
    self:_loadBgImage()

    if not self._bgImage then
        return
    end

    if self.bgNinePath then
        g:draw9Sprite(
            self._bgImage,
            self.bgNineLeft,
            self.bgNineRight,
            self.bgNineTop,
            self.bgNineBottom,
            self._absX,
            self._absY,
            self.width,
            self.height
        )
    else
        g:drawImageScale(
            self._bgImage,
            self._absX,
            self._absY,
            self.width,
            self.height,
            Graphics.TOP_LEFT
        )
    end
end

-- ─── children ────────────────────────────────────────────────────────────────

-- index is optional; omit it to append (preserves prior behaviour). Passing
-- an index lets callers reorder siblings, e.g. when the hierarchy panel
-- drag-and-drop moves a node to a specific position among its new siblings.
function UIComponent:addChild(child, index)
    child.parent = self
    table.insert(self.children, index or (#self.children + 1), child)
    child:updateAbsolutePosition(self._absX, self._absY)
    return child
end

function UIComponent:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            return
        end
    end
end

function UIComponent:clearChildren()
    for _, c in ipairs(self.children) do c.parent = nil end
    self.children = {}
end

-- ─── hit test ────────────────────────────────────────────────────────────────

function UIComponent:contains(px, py)
    return px >= self._absX and px <= self._absX + self.width and
        py >= self._absY and py <= self._absY + self.height
end

-- ─── pointer events ──────────────────────────────────────────────────────────

function UIComponent:onPointerPressed(px, py)
    for i = #self.children, 1, -1 do
        local c = self.children[i]
        if c.visible and c:contains(px, py) then
            c:onPointerPressed(px, py)
            return true
        end
    end
    return false
end

function UIComponent:onPointerDragged(px, py)
    for i = #self.children, 1, -1 do
        local c = self.children[i]
        if c.visible then c:onPointerDragged(px, py) end
    end
end

function UIComponent:onPointerReleased(px, py)
    for i = #self.children, 1, -1 do
        local c = self.children[i]
        if c.visible then c:onPointerReleased(px, py) end
    end
end

-- ─── key events ──────────────────────────────────────────────────────────────

function UIComponent:onKeyPressed(key)
    for i = #self.children, 1, -1 do
        self.children[i]:onKeyPressed(key)
    end
end

function UIComponent:onKeyReleased(key)
    for i = #self.children, 1, -1 do
        self.children[i]:onKeyReleased(key)
    end
end

function UIComponent:onScrolled(scrollX, scrollY)
    for i = #self.children, 1, -1 do
        self.children[i]:onScrolled(scrollX, scrollY)
    end
end

-- ─── update / render ─────────────────────────────────────────────────────────

function UIComponent:update(dt)
    for _, c in ipairs(self.children) do
        if c.visible then c:update(dt) end
    end
end

function UIComponent:render(g)
    if not self.visible then return end
    self:draw(g)
    self:_drawBgImage(g)
    for _, c in ipairs(self.children) do
        if c.visible then c:render(g) end
    end
end

-- override in subclasses
function UIComponent:draw(g)
end

function UIComponent:dispose()
    for _, c in ipairs(self.children) do c:dispose() end
end

return UIComponent

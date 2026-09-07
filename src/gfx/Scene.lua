local UIJson = require("gfx.ui.UIJson")

local Scene = class("Scene")

function Scene:ctor()
    self.widgets = {}
end

function Scene:loadUI(path)
    self.widgets = UIJson.load(path)
    for _, w in ipairs(self.widgets) do
        w:sync()
    end
end

-- Returns the top-level Canvas widget with this name, or nil.
function Scene:getCanvas(name)
    for _, w in ipairs(self.widgets) do
        if w.type == "Canvas" and w.name == name then
            return w
        end
    end
end

function Scene:setCanvasActive(name, active)
    for _, w in ipairs(self.widgets) do
        if w.type == "Canvas" and w.name == name then
            w.active = active
            w:sync()
            return
        end
    end
end

function Scene:findInCanvas(canvasName, widgetName)
    local canvas = self:getCanvas(canvasName)
    if not canvas then return nil end

    local function find(list)
        for _, w in ipairs(list) do
            if w.name == widgetName then return w end

            if w.children and #w.children > 0 then
                local result = find(w.children)
                if result then return result end
            end
        end
    end

    return find(canvas.children or {})
end

-- Convenience: skip the UIWidget wrapper and get straight to the
-- UIComponent (the thing with .render/.setImage/etc) for a named widget
-- inside a named canvas.
function Scene:getWidget(canvasName, widgetName)
    local w = self:findInCanvas(canvasName, widgetName)
    return w and w.component
end

-- Recursively collects every UIWidget of a given type under one canvas
-- (e.g. every "Button"). Returns a flat array of UIWidgets, not components.
function Scene:findAllInCanvas(canvasName, widgetType)
    local out = {}
    local canvas = self:getCanvas(canvasName)
    if not canvas then return out end
    local function visit(list)
        for _, w in ipairs(list) do
            if w.type == widgetType then out[#out + 1] = w end
            if #w.children > 0 then visit(w.children) end
        end
    end
    visit(canvas.children)
    return out
end

function Scene:update(dt)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.update then c:update(dt) end
    end
end

function Scene:render(g)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.render then c:render(g) end
    end
end

function Scene:onPointerPressed(x, y)
    for i = #self.widgets, 1, -1 do
        local c = self.widgets[i].component
        if c and c.visible and c.contains and c:contains(x, y) then
            if c.onPointerPressed and c:onPointerPressed(x, y) then return true end
        end
    end
    return false
end

function Scene:onPointerDragged(x, y)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.onPointerDragged then c:onPointerDragged(x, y) end
    end
end

function Scene:onPointerReleased(x, y)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.onPointerReleased then c:onPointerReleased(x, y) end
    end
end

function Scene:onKeyPressed(key)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.onKeyPressed then c:onKeyPressed(key) end
    end
end

function Scene:onKeyReleased(key)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.onKeyReleased then c:onKeyReleased(key) end
    end
end

function Scene:onScrolled(scrollX, scrollY)
    for _, w in ipairs(self.widgets) do
        local c = w.component
        if c and c.visible and c.onScrolled then c:onScrolled(scrollX, scrollY) end
    end
end

function Scene:onEnter()
end

function Scene:onExit()
end

function Scene:dispose()
    self.widgets = {}
end

return Scene

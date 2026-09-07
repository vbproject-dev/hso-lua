local Scene            = require("gfx.Scene")
local UIWidget         = require("gfx.ui.UIWidget")

local UIRuntimePreview = class("UIRuntimePreview", Scene)

local SCENE_W          = 1280
local SCENE_H          = 720
local SAVE_PATH        = "ui_layout.json"

function UIRuntimePreview:ctor(path)
    UIRuntimePreview.super.ctor(self)

    self.widgets = {}
    self.status = ""
    self._savePath = path or SAVE_PATH

    if FileUtils and FileUtils.exists and FileUtils.exists(self._savePath) then
        local ok, txt = pcall(function() return FileUtils.readText(self._savePath) end)

        if ok and txt then
            local data = JSON and JSON.toTable and JSON.toTable(txt) or nil

            if data and data.widgets then
                for _, widgetData in ipairs(data.widgets) do
                    self.widgets[#self.widgets + 1] = UIWidget.fromTable(widgetData)
                end

                self.status = "Loaded " .. tostring(#self.widgets) .. " widgets"
            else
                self.status = "No widgets in JSON"
            end
        else
            self.status = "Failed to read layout"
        end
    else
        self.status = "Layout file not found"
    end

    self:_syncWidgets()
end

function UIRuntimePreview:_sceneOrigin()
    return math.floor((SCREEN_WIDTH - SCENE_W) / 2), math.floor((SCREEN_HEIGHT - SCENE_H) / 2)
end

function UIRuntimePreview:_syncWidgets()
    for _, w in ipairs(self.widgets) do
        w:sync()
    end

    local scx, scy = self:_sceneOrigin()

    for _, w in ipairs(self.widgets) do
        w.component:updateAbsolutePosition(scx, scy)
    end
end

function UIRuntimePreview:update(dt)
    self:_syncWidgets()

    for _, w in ipairs(self.widgets) do
        if w and w.component and w.component.visible then
            w.component:update(dt)
        end
    end
end

function UIRuntimePreview:onPointerPressed(px, py)
    local scx, scy = self:_sceneOrigin()

    if px < scx or py < scy or px > scx + SCENE_W or py > scy + SCENE_H then
        return false
    end

    self:_syncWidgets()

    for i = #self.widgets, 1, -1 do
        local w = self.widgets[i]
        local c = w and w.component

        if c and c.visible and c:contains(px, py) then
            if c:onPointerPressed(px, py) then
                return true
            end
        end
    end

    return true
end

function UIRuntimePreview:onPointerDragged(px, py)
    for _, w in ipairs(self.widgets) do
        local c = w and w.component

        if c and c.visible then
            c:onPointerDragged(px, py)
        end
    end
end

function UIRuntimePreview:onPointerReleased(px, py)
    for _, w in ipairs(self.widgets) do
        local c = w and w.component

        if c and c.visible then
            c:onPointerReleased(px, py)
        end
    end
end

function UIRuntimePreview:onKeyPressed(key)
    if key == Input.KEY_ESCAPE then
        local SceneManager = require("gfx.SceneManager")
        SceneManager.getInstance():setScene(require("gfx.scenes.MainScene").new())
        return
    end

    for _, w in ipairs(self.widgets) do
        local c = w and w.component

        if c and c.visible then
            c:onKeyPressed(key)
        end
    end
end

function UIRuntimePreview:onKeyReleased(key)
    for _, w in ipairs(self.widgets) do
        local c = w and w.component

        if c and c.visible then
            c:onKeyReleased(key)
        end
    end
end

function UIRuntimePreview:render(g)
    local scx, scy = self:_sceneOrigin()

    g:setColor(0, 0, 0, 100)
    g:fillRect(scx + 6, scy + 6, SCENE_W, SCENE_H)

    g:setColor(0, 0, 0, 50)
    g:fillRect(scx + 10, scy + 10, SCENE_W, SCENE_H)

    g:setColor(30, 30, 36, 255)
    g:fillRect(scx, scy, SCENE_W, SCENE_H)

    self:_syncWidgets()

    for _, w in ipairs(self.widgets) do
        if w and w.component and w.component.visible then
            w.component:render(g)
        end
    end

    g:setColor(55, 60, 78, 255)
    g:drawRect(scx, scy, SCENE_W, SCENE_H)

    g:setColor(160, 170, 200, 255)
    g:drawString(self.status, scx + 8, scy - 18, Graphics.CENTER_LEFT)
end

return UIRuntimePreview

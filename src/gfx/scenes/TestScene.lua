local Scene = require "gfx.Scene"
local UICanvas = require "gfx.ui.components.UICanvas"
local UIWidget = require "gfx.ui.UIWidget"
local UIToolbar = require "gfx.ui.components.UIToolbar"
local TestScene = class("TestScene", Scene)

function TestScene:ctor()
    TestScene.super.ctor(self)

    local canvas = UICanvas.new(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)


    self:addWidget(UIWidget.fromComponent(canvas,
        {
            name = "canvas",
            type = "Canvas"
        }
    ))

    self:addWidget(UIWidget.fromComponent(UIToolbar.new(0, 0, SCREEN_WIDTH, 60),
        {
            name = "toolbar",
            type = "Toolbar"
        }
    ))
end

function TestScene:render(g)
    g:setColor(255, 0, 0, 255)
    g:fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    TestScene.super.render(self, g)
end

return TestScene

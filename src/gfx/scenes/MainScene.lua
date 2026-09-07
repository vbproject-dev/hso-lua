local Scene     = require("gfx.Scene")
local UIEditor  = require("gfx.ui.UIEditor")

local MainScene = class("MainScene", Scene)

function MainScene:ctor()
    MainScene.super.ctor(self)
    self.editor = UIEditor.new()
end

function MainScene:onPointerPressed(x, y)
    self.editor:onPointerPressed(x, y)
end

function MainScene:onPointerDragged(x, y)
    self.editor:onPointerDragged(x, y)
end

function MainScene:onPointerReleased(x, y)
    self.editor:onPointerReleased(x, y)
end

function MainScene:onKeyPressed(key)
    self.editor:onKeyPressed(key)
end

function MainScene:onKeyReleased(key)
    self.editor:onKeyReleased(key)
end

function MainScene:onScrolled(scrollX, scrollY)
    self.editor:onScrolled(scrollX, scrollY)
end

function MainScene:update(dt)
    self.editor:update(dt)
end

function MainScene:render(g)
    self.editor:render(g)
end

return MainScene

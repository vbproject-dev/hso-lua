local Scene = require "gfx.Scene"
local HandlerRegistry = require "core.HandlerRegistry"
local TestScene = class("TestScene", Scene)

function TestScene:ctor()
    TestScene.super.ctor(self)
    self:loadUI("ui_layout.json")

    self.console = self:getWidget("log", "console")
    self.reload = self:getWidget("log", "reload")
    self.reload.onClick = function()
        local modules = {
            { module = "modules.handlers.CommonHandler" },
            { module = "modules.handlers.LoginHandler" },
            { module = "modules.handlers.CharacterHandler" },
            { module = "modules.handlers.GameHandler" },
        }

        HandlerRegistry.reload(modules)
        local success, err = reloadPackage("modules")
        if err then
            log(err)
        end
    end
end

function TestScene:log(ste)
    self.console:log(ste)
end

function TestScene:render(g)
    g:setColor(255, 0, 0, 255)
    g:fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    TestScene.super.render(self, g)
end

return TestScene

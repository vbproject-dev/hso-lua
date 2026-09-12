local Scene           = require "gfx.Scene"
local HandlerRegistry = require "core.HandlerRegistry"
local ModuleRegistry  = require "core.ModuleRegistry"

local LogScene        = class("LogScene", Scene)

function LogScene:ctor()
    LogScene.super.ctor(self)
    self:loadUI("log_ui.json")

    self.canvas = self:getCanvas("log")
    self.width = SCREEN_WIDTH
    self.height = SCREEN_HEIGHT
    self.console = self:getWidget("log", "console")
    self.reload = self:getWidget("log", "reload")
    self.reload.onClick = function()
        ModuleRegistry.reload()

        local handlers = {
            { module = "modules.handlers.CommonHandler" },
            { module = "modules.handlers.LoginHandler" },
            { module = "modules.handlers.CharacterHandler" },
            { module = "modules.handlers.GameHandler" },
        }

        HandlerRegistry.reload(handlers)
    end
end

function LogScene:log(ste)
    self.console:log(ste)
end

function LogScene:render(g)
    g:setColor(255, 0, 0, 255)
    g:fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    LogScene.super.render(self, g)
end

return LogScene

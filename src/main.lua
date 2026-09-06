require "core.Class"
require "core.Logger"
require "core.Constants"
local GameServer = require "network.GameServer"

local Main = class("Main")

function Main:ctor()
    self.gameServer = nil
end

function Main:configure()
    return {
        useGraphics = false,
    }
end

function Main:init()
    self.gameServer = GameServer.new()
    self.gameServer:init()
end

function Main:onUpdate(dt)
    self.gameServer:update(dt)
end

function Main:onRender(g)
end

return Main.new()

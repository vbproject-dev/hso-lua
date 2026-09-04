require "core.Class"
require "core.Logger"
require "core.GameConstants"
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

    -- local encrypt, err = LuaPacker.packDirectory("assets/src", "encrypt")
    -- if err then
    --     log(err)
    -- end

    -- local content = "{}"

    -- local response, err = API.upload(
    --     "test.json",
    --     content
    -- )

    -- if not response then
    --     print("Upload failed:", err)
    --     return
    -- end

    -- print("Upload:", response)
end

function Main:onUpdate(dt)
    self.gameServer:update(dt)
end

function Main:onRender(g)
end

return Main.new()

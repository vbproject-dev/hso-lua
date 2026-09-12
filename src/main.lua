require "core.Class"
require "core.Logger"
require "core.Constants"
local GameServer   = require "network.GameServer"
local SceneManager = require "gfx.SceneManager"
local WebServer    = require "network.WebServer"
local Main         = class("Main")


function Main:ctor()
    self.gameServer = nil
    self.webServer = nil
end

function Main:configure()
    _G.SCREEN_WIDTH = 900  --1280
    _G.SCREEN_HEIGHT = 480 --720
    GFX = true
    return {
        useGraphics = GFX,
        title = "HSO",
        width = SCREEN_WIDTH,
        height = SCREEN_HEIGHT,
    }
end

function Main:init()
    if GFX then
        gfx:setFont(Font.create("fonts/JetBrainsMono-Regular.ttf", FontStyle.BOLD, 16))
        SceneManager.getInstance():setScene(require("gfx.scenes.LogScene").new())
    end
    self.gameServer = GameServer.new()
    self.gameServer:init()
    self.webServer = WebServer.new()
    self.webServer:init()
end

function Main:onUpdate(dt)
    self.gameServer:update(dt)
    self.webServer:update(dt)

    if GFX then
        SceneManager.getInstance():update(dt)
    end
end

function Main:onRender(g)
    if GFX then
        SceneManager.getInstance():render(g)
    end
end

return Main.new()

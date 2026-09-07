require "core.Class"
require "core.Logger"
require "core.Constants"
local GameServer = require "network.GameServer"
local SceneManager = require "gfx.SceneManager"

local Main = class("Main")

local useGfx = true
function Main:ctor()
    self.gameServer = nil
end

function Main:configure()
    _G.SCREEN_WIDTH = 800
    _G.SCREEN_HEIGHT = 480
    GFX = false
    return {
        useGraphics = GFX,
        title = "HSO",
        width = SCREEN_WIDTH,
        height = SCREEN_HEIGHT,
    }
end

function Main:init()
    self.gameServer = GameServer.new()
    self.gameServer:init()
    if GFX then
        gfx:setFont(Font.create("fonts/JetBrainsMono-Regular.ttf", FontStyle.BOLD, 16))
        SceneManager.getInstance():setScene(require("gfx.scenes.MainScene").new())
    end
end

function Main:onUpdate(dt)
    self.gameServer:update(dt)

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

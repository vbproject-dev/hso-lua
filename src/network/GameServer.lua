local Config          = require("core.Config")
local MySQL           = require("core.MySQL")
local Network         = require("network.Network")
local HandlerRegistry = require("core.HandlerRegistry")
local GameData        = require("database.GameData")
local GameWorld       = require("modules.game.world.GameWorld")


local GameServer          = class("GameServer")

local MYSQL_PING_INTERVAL = 60

function GameServer:ctor()
    self.mysqlElapsed = 0
    self.network = Network.new(function(session)
        local player = GameWorld.instance():getPlayerBySession(session)
        if player then
            GameWorld.instance():unregisterPlayer(player)
            -- Save Data
        end
    end)
end

function GameServer:init()
    DEBUG = true

    local config = Config.load("config.json")
    if not config then
        return false
    end

    local db = config.database
    local conn, err = MySQL.connect(db.host, db.user, db.password, db.name, db.port)
    if err then
        log("[MySQL] " .. tostring(err))
        return false
    end

    if not GameData.load() then
        return false
    end

    GameWorld.instance():init()

    local modules = {
        { module = "modules.handlers.CommonHandler" },
    }

    HandlerRegistry.loadAll(modules)

    self.network:start(config.server.port)

    return true
end

function GameServer:update(dt)
    self.mysqlElapsed = self.mysqlElapsed + dt

    if self.mysqlElapsed >= MYSQL_PING_INTERVAL then
        self.mysqlElapsed = 0

        if self.db then
            self.db:ping()
        end
    end

    GameWorld.instance():update(dt)
end

return GameServer

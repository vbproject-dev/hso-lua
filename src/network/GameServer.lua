local Config            = require("core.Config")
local MySQL             = require("core.MySQL")
local Network           = require("network.Network")
local GameData          = require("database.GameData")
local GameWorld         = require("modules.game.world.GameWorld")
local HandlerRegistry   = require("core.HandlerRegistry")
local ModuleRegistry    = require("core.ModuleRegistry")
local NpcScriptRegistry = require("modules.game.npc.NpcScriptRegistry")




local GameServer          = class("GameServer")

local MYSQL_PING_INTERVAL = 60

function GameServer:ctor()
    self.mysqlElapsed = 0
    self.network = Network.new(function(session)
        local player = GameWorld.instance():getPlayerBySession(session)
        if player then
            GameWorld.instance():unregisterPlayer(player)
            local saved, err = updateTable("player", player:toTable(), { id = player.id })
            if err then
                log("[MySQL] Failed to update player %s, %s", player.name, err)
            end
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

    self.db = conn

    if not GameData.load() then
        return false
    end

    GameWorld.instance():init()

    -- Network Writters
    ModuleRegistry.loadPackage("modules.writters")
    ModuleRegistry.loadPackage("modules.game.items.function")
    -- Network Handlers
    local handlers = {
        { module = "modules.handlers.CommonHandler" },
        { module = "modules.handlers.LoginHandler" },
        { module = "modules.handlers.CharacterHandler" },
        { module = "modules.handlers.GameHandler" },
    }
    HandlerRegistry.loadAll(handlers)

    -- Register NPC Scripts
    if GameData.npcs then
        GameData.npcs:forEach(function(npc)
            if npc.script_name then
                NpcScriptRegistry.load(npc.id, "modules.game.npc." .. npc.script_name)
            end
        end)
    end

    NpcScriptRegistry.loadCommon("modules.game.npc.CommonScript")


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

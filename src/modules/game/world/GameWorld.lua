local Map = require("modules.game.world.Map")
local GameData = require("database.GameData")

local GameWorld = class("GameWorld")

local _instance = nil

function GameWorld.instance()
    if not _instance then
        _instance = GameWorld.new()
    end
    return _instance
end

function GameWorld:ctor()
    self.mapList = ArrayList.new()
    self.playerList = ArrayList.new()
    self.playerSessions = {} -- session -> Player lookup
end

function GameWorld:init()
    log("[GameWorld] Initializing game world and maps...")

    GameData.maps:forEach(function(data)
        self.mapList:add(Map.new(data))
    end)

    local totalZones = self.mapList:reduce(0, function(total, map)
        return total + map:getZoneCount()
    end)

    log("[GameWorld] Initialized %d maps with %d total zones.", self.mapList:size(), totalZones)
end

function GameWorld:getMap(mapId)
    return self.mapList:findFirst(function(map)
        return map.id == mapId
    end)
end

function GameWorld:getMaps()
    return self.mapList
end

function GameWorld:registerPlayer(player, session)
    if not player then return end

    if session then
        player:setSession(session)
        self.playerSessions[session] = player
    end

    if not self.playerList:contains(player) then
        self.playerList:add(player)
    end

    player.online = true

    log("[GameWorld] Player registered: %s (ID: %d) | Total Online: %d",
        player.name or "Unknown", player.id, self:getOnlineCount())
end

function GameWorld:unregisterPlayer(playerOrSession)
    local player = nil

    if playerOrSession and playerOrSession.id then
        player = playerOrSession
    elseif playerOrSession then
        player = self.playerSessions[playerOrSession]
    end

    if not player then return end

    -- Safety: never leave a player stranded inside a zone
    if player.zone then
        player.zone:removePlayer(player)
    end

    -- Clean up session and global player list
    if player.session then
        self.playerSessions[player.session] = nil
        player:setSession(nil)
    end

    self.playerList:remove(player)
    player.online = false

    log("[GameWorld] Player unregistered: %s (ID: %d) | Total Online: %d",
        player.name or "Unknown", player.id, self:getOnlineCount())
end

function GameWorld:onSessionDisconnect(session)
    if not session then return end
    local player = self.playerSessions[session] or session:get("player")
    if player then
        self:unregisterPlayer(player)
    end
end

function GameWorld:getPlayer(playerId)
    return self.playerList:findFirst(function(p)
        return p.id == playerId
    end)
end

function GameWorld:getPlayerBySession(session)
    if not session then return nil end
    return self.playerSessions[session] or session:get("player")
end

function GameWorld:getPlayerById(id)
    if not id then return nil end
    return self.playerList:findFirst(function(p)
        return p.id == id
    end)
end

function GameWorld:getPlayerByAccount(accountId)
    if accountId == nil then return nil end
    return self.playerList:findFirst(function(p)
        return p.accountId == accountId
    end)
end

function GameWorld:getOnlineCount()
    return self.playerList:size()
end

function GameWorld:update(dt)
    self.mapList:forEach(function(map)
        map:update(dt)
    end)
end

return GameWorld

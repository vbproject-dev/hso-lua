local Zone = require("modules.game.world.Zone")
local Map = class("Map")

function Map:ctor(data)
    self.id = data.id
    self.name = data.name
    self.zoneCount = data.max_zone or 10
    self.maxPlayersPerZone = data.max_player or 30
    self.miniMap = data.mini_map
    self.type = data.type
    self.isCity = data.is_city == 1
    self.isShowHs = data.show_hs == 1
    self.warps = ArrayList.new(data.warp_point)
    self.mobs = ArrayList.new(data.mob_data)
    self.itemMap = ArrayList.new(data.item_map)
    self.npcs = ArrayList.new(data.npc)
    self.tileData = data.tile_data
    self.bgType = data.bg_type
    self.bgHeight = data.bg_height

    self.zones = ArrayList.new()
    -- Initialize zones (0-indexed to match client area index)
    for i = 0, self.zoneCount - 1 do
        local zone = Zone.new(self, i, self.maxPlayersPerZone)


        self.zones:add(zone)
    end
end

function Map:getId()
    return self.id
end

function Map:getName()
    return self.name
end

function Map:getZoneCount()
    return self.zoneCount
end

function Map:getZones()
    return self.zones
end

function Map:getZone(zoneId)
    if zoneId == nil then return nil end

    local zone = self.zones:findFirst(function(z)
        return z.id == zoneId
    end)

    if zone then
        return zone
    end

    -- Fallback 1-based indexing check if within range
    if zoneId >= 1 and zoneId <= self.zones:size() then
        return self.zones:get(zoneId)
    end

    return nil
end

function Map:getAvailableZone()
    return self.zones:findFirst(function(zone)
        return not zone:isFull()
    end)
end

function Map:addPlayer(player, zoneId)
    if not player then return false end

    local targetZone = self:getZone(zoneId)

    if not targetZone or targetZone:isFull() then
        targetZone = self:getAvailableZone()
    end

    if not targetZone then
        log("[Map] No available zone in Map %d for player %s", self.id, player.name or "Unknown")
        return false
    end

    return targetZone:addPlayer(player)
end

function Map:removePlayer(player)
    if not player then return false end

    if player.zone and player.zone.map == self then
        return player.zone:removePlayer(player)
    end

    local zone = self.zones:findFirst(function(z)
        return z:hasPlayer(player)
    end)

    if zone then
        return zone:removePlayer(player)
    end

    return false
end

function Map:findPlayer(playerId)
    for _, zone in self.zones:ipairs() do
        local p = zone:getPlayer(playerId)
        if p then
            return p, zone
        end
    end
    return nil, nil
end

function Map:getPlayerCount()
    return self.zones:reduce(0, function(total, zone)
        return total + zone:getPlayerCount()
    end)
end

function Map:getZoneStatusList()
    return self.zones:map(function(zone)
        return {
            id = zone.id,
            players = zone:getPlayerCount(),
            max = zone.maxPlayers,
            isFull = zone:isFull(),
        }
    end)
end

function Map:update(dt)
    self.zones:forEach(function(zone)
        zone:update(dt)
    end)
end

return Map

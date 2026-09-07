local Cmd              = require "network.Cmd"
local CommonWritter    = require "modules.writters.CommonWritter"
local CharacterWritter = require "modules.writters.CharacterWritter"
local GameWritter      = require "modules.writters.GameWritter"


local Zone = class("Zone")

function Zone:ctor(map, id, maxPlayers)
    self.map = map
    self.id = id
    self.maxPlayers = maxPlayers or 10
    self.players = ArrayList.new()
    self.monsters = ArrayList.new()
    self.npcs = ArrayList.new()
end

function Zone:getId()
    return self.id
end

function Zone:getMap()
    return self.map
end

function Zone:getPlayers()
    return self.players
end

function Zone:getPlayerCount()
    return self.players:size()
end

function Zone:isFull()
    return self.players:size() >= self.maxPlayers
end

function Zone:getPlayer(playerId)
    return self.players:findFirst(function(p)
        return p.id == playerId
    end)
end

function Zone:hasPlayer(player)
    if not player then return false end
    return self.players:contains(player)
end

function Zone:addPlayer(player)
    if not player then return false end

    -- If the player is already in another zone, remove them first
    if player.zone and player.zone ~= self then
        player.zone:removePlayer(player)
    end


    player:setZone(self)

    if not self.players:contains(player) then
        self.players:add(player)
    end

    self:onPlayerJoin(player)
    return true
end

function Zone:removePlayer(player)
    if not player then return false end

    if not self.players:contains(player) then
        return false
    end

    self.players:remove(player)
    player:setZone(nil)

    self:onPlayerLeave(player)
    return true
end

function Zone:addMonster(monster)
    if not monster then return false end
    if monster.zone and monster.zone ~= self then monster.zone:removeMonster(monster) end

    monster:setZone(self)

    if not self.monsters:contains(monster) then
        self.monsters:add(monster)
    end

    return true
end

function Zone:removeMonster(monster)
    if not monster or not self.monsters:contains(monster) then return false end

    self.monsters:remove(monster)
    monster:setZone(nil)

    return true
end

function Zone:addNpc(npc)
    if not npc then return false end
    if npc.zone and npc.zone ~= self then npc.zone:removeNpc(npc) end

    npc:setZone(self)

    if not self.npcs:contains(npc) then
        self.npcs:add(npc)
    end

    return true
end

function Zone:removeNpc(npc)
    if not npc or not self.npcs:contains(npc) then return false end

    self.npcs:remove(npc)
    npc:setZone(nil)

    return true
end

function Zone:getObjects(type)
    if type == 0 then return self.players end
    if type == 1 then return self.monsters end
    if type == 2 then return self.npcs end
end

function Zone:getObject(type, id)
    local objects = self:getObjects(type)
    if not objects then return nil end

    return objects:findFirst(function(object) return object.id == id end)
end

function Zone:removeObject(type, id)
    local objects = self:getObjects(type)
    if not objects then return false end

    local object = objects:findFirst(function(object) return object.id == id end)
    if not object then return false end

    objects:remove(object)
    object:setZone(nil)

    return true
end

function Zone:forEachPlayer(callback, exceptPlayer)
    self.players:forEach(function(p)
        if p ~= exceptPlayer then
            callback(p)
        end
    end)
end

function Zone:broadcast(packet, exceptPlayer)
    self:forEachPlayer(function(player)
        player:send(packet)
    end, exceptPlayer)
end

function Zone:update(dt)
    self.players:forEach(function(p)
        if p.update then
            p:update(dt)
        end
    end)
end

function Zone:getStatusArea()
    if self:isFull() then
        return 0
    end

    if self:getPlayerCount() >= self.maxPlayers / 2 then
        return 1
    end

    return 2
end

function Zone:onPlayerJoin(player)
    CharacterWritter.mainCharInfo(player)
    CommonWritter.changeMap(player)
    GameWritter.npcBig(player, self.npcs)
    self:forEachPlayer(function(other)
        other:send(Packet.new(Cmd.CHAR_WEARING, player:wearingData()))
    end)
end

function Zone:onPlayerLeave(player)
    self:forEachPlayer(function(other)
        -- notify other
    end, player)
end

return Zone

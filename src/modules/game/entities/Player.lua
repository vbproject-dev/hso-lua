local BaseObject = require("modules.game.entities.BaseObject")
local Equipment = require("modules.game.items.Equipment")
local Inventory = require("modules.game.inventory.Inventory")
local EquipType = require("modules.game.items.EquipType")

local Player = class("Player", BaseObject)

function Player:ctor(data)
    Player.super.ctor(self, data)
    self.accountId = data.account_id or 0
    self.class = data.class or 0
    self.level = data.level or 1
    self.exp = data.exp or 0
    self.gold = data.gold or 0
    self.gem = data.gem or 0
    self.info = data.info or {}
    self.rms = data.rms or { {}, {} }
    self.fashion = ArrayList.new(data.fashion or { -1, -1, -1, -1, -1, -1, -1 })

    self.wearing = ArrayList.new()
    for i = 0, 23 do
        self.wearing:add(nil)
    end

    for __, itemData in pairs(data.wearing or {}) do
        local item = Equipment.create(itemData)
        if item then
            local slot = self:getAvailableSlotForType(item)
            if slot then
                item.slot = slot
                self.wearing:set(slot, item)
            end
        end
    end

    local count = self.wearing:reduce(0, function(count, item)
        return count + (item and 1 or 0)
    end)
    log("wearing size %s", count)

    self.inventory = Inventory.new(data.bag or {})
    self.bank = Inventory.new(data.bank or {})
    -- Stats
    self.hp = 32000
    self.maxHp = 32000
    self.mp = 32000
    self.maxMp = 32000

    self.online = false
    self.session = nil
    self.zone = nil
end

function Player:setSession(session)
    self.session = session
end

function Player:getSession()
    return self.session
end

function Player:setZone(zone)
    self.zone = zone
end

function Player:getZone()
    return self.zone
end

function Player:getMap()
    return self.zone and self.zone.map or nil
end

function Player:wear(item)
    local slots = EquipType[item.info.type]
    if not slots then return nil end

    local slot = slots[1]

    for _, candidate in ipairs(slots) do
        if not self.wearing:get(candidate) then
            slot = candidate
            break
        end
    end

    local old = self.wearing:get(slot)
    item.slot = slot
    self.wearing:set(slot, item)

    return old
end

function Player:unwear(slot)
    local item = self.wearing:get(slot)
    if not item then return nil end

    self.wearing:set(slot, nil)
    return item
end

function Player:getWearing(slot)
    local item = self.wearing:get(slot)
    return item
end

function Player:getAvailableSlotForType(item)
    local slots = EquipType[item.info.type]
    if not slots then return nil end

    for _, slot in ipairs(slots) do
        if not self.wearing:get(slot) then
            return slot
        end
    end

    return nil
end

function Player:toTable()
    return {
        class = self.class,
        level = self.level,
        exp = self.exp,
        gold = self.gold,
        gem = self.gem,
        info = self.info,
        wearing = self.wearing:toTable(function(item) return item:toTable() end),
        inventory = self.inventory:toTable(),
        bank = self.bank:toTable(),
    }
end

function Player:send(packet)
    if self.session then
        self.session:send(packet)
    end
end

function Player:wearingData()
    local packet = Packet.new()
    packet:writeShort(self.id)
    packet:writeByte(self.wearing:size())
    self.wearing:forEachIndexed(function(index, item)
        if not item then
            packet:writeByte(-1)
        else
            packet:writeByte(index)
            packet:writeUTF(item.info.name)
            packet:writeByte(item.info.role)
            packet:writeByte(item.info.type)
            packet:writeShort(item.info.icon)
            packet:writeByte(item.info.part)
            packet:writeByte(item.plus)
            packet:writeShort(item.info.level)
            packet:writeByte(item.color)

            packet:writeByte(item.options:size())
            item.options:forEach(function(op)
                packet:writeByte(op.id)
                packet:writeInt(op.value)
            end)

            -- lock
            packet:writeByte(1)
        end
    end)

    -- Pet
    packet:writeByte(-1)

    packet:writeByte(self.fashion:size())
    self.fashion:forEach(function(id)
        packet:writeShort(id)
    end)
    return packet:getData()
end

return Player

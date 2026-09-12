local Cmd = require "network.Cmd"
local GameData = require "database.GameData"
local PartManager = require "database.PartManager"
local GameWritter = {}

function GameWritter.objectMove(player, mover)
    local packet = Packet.new(Cmd.OBJECT_MOVE)
    packet:writeByte(mover.type)

    if iskindof(mover, "Monster") then
        packet:writeShort(mover.template.id)
    else
        packet:writeShort(0)
    end

    packet:writeShort(mover.id)
    packet:writeShort(mover.x)
    packet:writeShort(mover.y)
    packet:writeByte(-1)

    player:send(packet)
end

function GameWritter.monsterInfo(player, monster)
    local packet = Packet.new(Cmd.MONSTER_INFO)

    packet:writeShort(monster.id)
    packet:writeByte(monster.template.level)
    packet:writeShort(monster.x)
    packet:writeShort(monster.y)
    packet:writeInt(monster.hp)
    packet:writeInt(monster.maxHp)
    if monster.template.id >= 89 and monster.template.id <= 92 then
        packet:writeByte(monster.template.id - 43)
    elseif monster.template.id == 151 then
        packet:writeByte(65)
    elseif monster.template.id == 152 then
        packet:writeByte(66)
    elseif monster.template.id == 154 then
        packet:writeByte(64)
    else
        packet:writeByte(20)
    end

    packet:writeInt(monster.refreshTime)
    packet:writeShort(-1) -- clan monster
    packet:writeByte(0)
    packet:writeByte(2)   -- speed
    packet:writeByte(0)
    packet:writeUTF("")
    packet:writeLong(-11111)
    packet:writeByte(monster.color)

    player:send(packet)
end

function GameWritter.removeObject(player, objectId)
    local packet = Packet.new(Cmd.REMOVE_ACTOR)
    packet:writeShort(objectId)
    player:send(packet)
end

function GameWritter.npcBig(player, npcs)
    local packet = Packet.new(Cmd.NPC_BIG)
    packet:writeByte(npcs:size())
    npcs:forEach(function(npc)
        packet:writeUTF(npc.template.name)
        packet:writeUTF(npc.template.dialog_name)
        packet:writeByte(npc.template.id)
        packet:writeByte(npc.template.image_id)
        packet:writeShort(npc.x)
        packet:writeShort(npc.y)
        packet:writeByte(npc.template.w_block)
        packet:writeByte(npc.template.h_block)
        packet:writeByte(npc.template.total_frame)
        packet:writeByte(npc.template.big_avatar)
        packet:writeUTF(npc.template.dialog_text)
        packet:writeByte(npc.template.person)
        packet:writeByte(npc.template.show_hp)
    end)
    player:send(packet)
end

local function updateInventory(player, inventory, type)
    local packet = Packet.new(16)
    if type == 3 then
        packet:writeByte(0)
        packet:writeByte(type)
        packet:writeLong(player.gold)
        packet:writeInt(player.gem)
        packet:writeByte(type)

        local equipments = inventory:findByCategory(type)
        packet:writeByte(equipments:size())

        equipments:forEachIndexed(function(index, item)
            packet:writeUTF(item.info.name)
            packet:writeByte(item.info.role)
            packet:writeShort(index)
            packet:writeByte(item.info.type)
            packet:writeShort(item.info.icon)
            packet:writeByte(item.plus)
            packet:writeShort(item.info.level)
            packet:writeByte(item.color)
            packet:writeByte(1)
            packet:writeByte(item.lock and 0 or 1)

            packet:writeByte(item.options:size())
            item.options:forEach(function(option)
                packet:writeByte(option.id)
                packet:writeInt(option.value)
            end)

            if item.expired ~= 0 then
                local timeUse = math.floor((item.expired - os.time() * 1000) / 60000)
                packet:writeInt(timeUse > 0 and timeUse or 1)
            else
                packet:writeInt(0)
            end

            packet:writeByte(item.lock and 1 or 0)

            if item.expired <= 0 then
                packet:writeByte(0)
            else
                packet:writeByte(1)
                packet:writeInt(0)
                packet:writeUTF(tostring(item.expired))
            end

            packet:writeByte(0)
        end)
    else
        packet:writeByte(0)
        packet:writeByte(type)
        packet:writeLong(player.gold)
        packet:writeInt(player.gem)
        packet:writeByte(type)

        local slots = inventory:findByCategory(type)
        packet:writeByte(slots:size())

        slots:forEach(function(item)
            packet:writeShort(item.id)
            packet:writeShort(item.quantity)
            packet:writeByte(1)
            packet:writeByte(0)
        end)
    end

    player:send(packet)
end

function GameWritter.openShop(player)
    local shop = player.shop
    if shop.category == 3 then
        local packet = Packet.new(Cmd.NPC_INFO)
        packet:writeUTF(shop.name)
        packet:writeByte(1)
        packet:writeShort(shop.items:size())
        shop.items:forEach(function(itemData)
            local equipment = GameData.getEquipment(itemData.id)
            packet:writeShort(equipment.id)
            packet:writeUTF(equipment.name)
            packet:writeByte(equipment.role)
            packet:writeByte(equipment.type)
            packet:writeShort(equipment.icon)
            packet:writeLong(itemData.price)
            packet:writeShort(equipment.level)
            packet:writeByte(equipment.color)
            packet:writeByte(#equipment.options)
            for __, opt in pairs(equipment.options) do
                packet:writeByte(opt.id)
                packet:writeInt(opt.value)
            end

            packet:writeByte(itemData.priceType)
        end)

        player:send(packet)
    elseif shop.category == 4 then
        local packet = Packet.new(Cmd.NPC_INFO)
        packet:writeUTF(shop.name)
        packet:writeByte(0)
        packet:writeShort(shop.items:size())
        shop.items:forEach(function(itemData)
            packet:writeShort(itemData.id)
        end)

        player:send(packet)
    elseif shop.category == 7 then
        local packet = Packet.new(Cmd.NPC_INFO)
        packet:writeUTF(shop.name)
        packet:writeByte(4)
        packet:writeShort(shop.items:size())
        shop.items:forEach(function(itemData)
            packet:writeShort(itemData.id)
        end)

        player:send(packet)
    end
end

function GameWritter.updateInventory(player)
    updateInventory(player, player.inventory, 4)
    updateInventory(player, player.inventory, 7)
    updateInventory(player, player.inventory, 3)
end

function GameWritter.itemMap(player, id)
    local zoomLv = player.session:get("zoom")
    local data = PartManager.getByZoom(zoomLv, 111, id)
    if not data then return end

    local packet = Packet.new(Cmd.LOAD_IMAGE_DATA_AUTO_EFF)
    packet:writeByte(1)

    packet:writeShort(#data.imageData)
    packet:writeBytes(data.imageData)

    packet:writeByte(0) -- dx
    packet:writeByte(0) -- dy
    packet:writeShort(0)

    packet:writeShort(player.x / 24) -- x
    packet:writeShort(player.y / 24) -- y
    packet:writeByte(0)              -- Type Effect
    packet:writeByte(0)              -- hOne

    packet:writeShort(3000)          -- objectID
    packet:writeShort(0)             -- Loop

    packet:writeByte(1)              -- TypeObject
    player:send(packet)
    return packet
end

function GameWritter.openMenu(player, menu)
    local packet = Packet.new(Cmd.DYNAMIC_MENU)

    packet:writeShort(menu.npc)
    packet:writeByte(menu.index)
    packet:writeByte(menu.children:size())

    menu.children:forEach(function(item)
        packet:writeUTF(item.name)
    end)

    packet:writeUTF(menu.name)

    player:send(packet)
end

return GameWritter

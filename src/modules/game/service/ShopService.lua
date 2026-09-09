local Cmd = require "network.Cmd"
local GameData = require "database.GameData"
local ShopService = {}

function ShopService.openShop(player, shop)
    if shop.category == 3 then
        local packet = Packet.new(Cmd.NPC_INFO)
        packet:writeUTF(shop.name)
        packet:writeByte(1)
        packet:writeShort(#shop.items)
        for __, itemData in ipairs(shop.items) do
            local equipment = GameData.getEquipment(itemData.itemId)
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
        end

        player:send(packet)
    elseif shop.category == 4 then
        local packet = Packet.new(Cmd.NPC_INFO)
        packet:writeUTF(shop.name)
        packet:writeByte(0)
        packet:writeShort(#shop.items)
        for __, itemData in ipairs(shop.items) do
            packet:writeShort(itemData.itemId)
        end

        player:send(packet)
    elseif shop.category == 7 then
        local packet = Packet.new(Cmd.NPC_INFO)
        packet:writeUTF(shop.name)
        packet:writeByte(4)
        packet:writeShort(#shop.items)
        for __, itemData in ipairs(shop.items) do
            packet:writeShort(itemData.itemId)
        end

        player:send(packet)
    end

    player.shop = shop
end

return ShopService

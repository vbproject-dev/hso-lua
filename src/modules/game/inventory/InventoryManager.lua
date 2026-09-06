local InventoryManager = {}


function InventoryManager.refresh(player)
    InventoryManager.updateInventory(player, player.inventory, 4)
    InventoryManager.updateInventory(player, player.inventory, 7)
    InventoryManager.updateInventory(player, player.inventory, 3)
end

function InventoryManager.updateInventory(player, inventory, type)
    local packet = Packet.new(16)
    if type == 3 then
        packet:writeByte(0)
        packet:writeByte(3)
        packet:writeLong(player.gold)
        packet:writeInt(player.gem)
        packet:writeByte(3)

        local equipments = inventory:findByCategory(3)
        log("inventory 3 size %d", equipments:size())
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

return InventoryManager

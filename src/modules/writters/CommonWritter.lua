local Cmd           = require("network.Cmd")
local GameData      = require("database.GameData")
local CommonWritter = {}

function CommonWritter.sendBytes(session, cmd, bytes)
    return try(function()
        local packet = Packet.new(cmd)
        packet:writeBytes(bytes)
        session:send(packet)
    end)
end

function CommonWritter.noticeBox(session, text)
    return try(function()
        local packet = Packet.new(Cmd.NOTICE_BOX)
        packet:writeUTF(text)
        packet:writeUTF("")
        packet:writeByte(15)
        session:send(packet)
    end)
end

function CommonWritter.updateData(session, count, size)
    return try(function()
        local packet = Packet.new(Cmd.UPDATE_DATA)
        packet:writeShort(count)
        packet:writeShort(size)
        session:send(packet)
    end)
end

function CommonWritter.sendPartData(session, data)
    return try(function()
        local packet = Packet.new(-52)
        packet:writeByte(data.type)
        packet:writeShort(data.id)
        packet:writeInt(#data.image)
        packet:writeBytes(data.image)
        packet:writeBytes(data.imageData)
        session:send(packet)
    end)
end

function CommonWritter.monsterCatalog(session)
    return try(function()
        local packet = Packet.new(Cmd.CATALOG_MONSTER)
        packet:writeShort(GameData.monsters:size())
        GameData.monsters:forEach(function(monster)
            packet:writeShort(monster.id)
            packet:writeUTF(monster.name)
            packet:writeByte(monster.level)
            packet:writeInt(monster.hp)
            packet:writeByte(monster.type_move)
        end)

        local bytes = FileUtils.readBytes("msg/monster_template")
        if not bytes then
            log("File not found: msg/monster_template")
            return
        end

        packet:writeBytes(bytes)

        session:send(packet)
    end)
end

function CommonWritter.itemTemplate(session)
    return try(function()
        local packet = Packet.new(Cmd.ITEM_TEMPLATE)

        -- ITEM POTION

        packet:writeShort(GameData.potions:size())
        GameData.potions:forEach(function(item)
            packet:writeShort(item.id)
            packet:writeShort(item.icon)
            packet:writeLong(item.price)
            packet:writeUTF(item.name)
            packet:writeUTF(item.description)
            packet:writeByte(item.potion_type)
            packet:writeByte(item.price_type)
            packet:writeByte(item.sell)
            packet:writeShort(item.value)
            packet:writeBoolean(item.can_trade == 1)
        end)

        -- ITEM OPTIONS
        packet:writeByte(GameData.options:size())
        GameData.options:forEach(function(op)
            packet:writeUTF(op.name)
            packet:writeByte(op.color)
            packet:writeByte(op.percent and 1 or 0)
        end)

        -- ITEM MATERIAL
        packet:writeShort(GameData.materials:size())
        GameData.materials:forEach(function(item)
            packet:writeShort(item.id)
            packet:writeShort(item.icon)
            packet:writeLong(item.price)
            packet:writeUTF(item.name)
            packet:writeUTF(item.description)
            packet:writeByte(item.material_type)
            packet:writeByte(item.price_type)
            packet:writeByte(item.sell)
            packet:writeShort(item.value)
            packet:writeBoolean(item.can_trade == 1)
            packet:writeByte(item.color)
        end)

        -- PRICE SETTINGS
        local cfg = GameData.getSetting("config")

        packet:writeShort(cfg.price_sell_potion)
        packet:writeShort(cfg.price_sell_item)
        packet:writeShort(cfg.heso_level)
        packet:writeShort(cfg.heso_color)
        packet:writeShort(cfg.price_sell_quest)
        packet:writeShort(cfg.max_price_item)
        packet:writeShort(cfg.price_clan_icon)
        packet:writeByte(cfg.price_chat_world)

        -- PET TEMPLATE
        packet:writeByte(#cfg.pet_template)
        for _, pet in ipairs(cfg.pet_template) do
            packet:writeShort(pet.id)
            packet:writeByte(pet.type)
        end

        -- CRAFT MATERIAL
        packet:writeByte(#cfg.craft_material)
        for _, id in ipairs(cfg.craft_material) do
            packet:writeShort(id)
        end

        session:send(packet)
    end)
end

function CommonWritter.nameServer(session)
    return try(function()
        local packet = Packet.new(Cmd.NAME_SERVER)

        packet:writeByte(GameData.maps:size())
        GameData.maps:forEach(function(map)
            packet:writeUTF(map.name)
        end)

        packet:writeByte(1)
        packet:writeUTF("Nothing")

        local cfg = GameData.getSetting("config")
        packet:writeByte(#cfg.upgrade_materials)
        for _, id in ipairs(cfg.upgrade_materials) do
            packet:writeShort(id)
        end

        packet:writeByte(#cfg.upgrade_levels)
        for _, data in ipairs(cfg.upgrade_levels) do
            packet:writeByte(data.level)
            packet:writeInt(data.gold)
            packet:writeShort(data.gem)
            for _, id in ipairs(data.value) do
                packet:writeByte(id)
            end
        end

        session:send(packet)
    end)
end

function CommonWritter.loadImage(session, data)
    return try(function()
        local packet = Packet.new(Cmd.LOAD_IMAGE)
        packet:writeShort(data.id)
        packet:writeBytes(data.bytes)
        session:send(packet)
    end)
end

function CommonWritter.fillRectUpdate(session, type)
    return try(function()
        local packet = Packet.new(Cmd.FILL_REC_UPDATE_TIME)
        packet:writeByte(type)
        if type == 3 or type == 5 then
            packet:writeByte(0)
        end
        session:send(packet)
    end)
end

function CommonWritter.changeMap(player)
    if not player then return false end

    return try(function()
        local map = player:getMap()
        local packet = Packet.new(Cmd.CHANGE_MAP)
        packet:writeShort(map.id)
        packet:writeShort(player.location.x / 24)
        packet:writeShort(player.location.y / 24)

        packet:writeBytes(player:getMap():toBytes())

        packet:writeByte(0)
        packet:writeByte(player.zone.id)
        packet:writeByte(map.type)
        packet:writeBoolean(map.isCity)
        packet:writeBoolean(map.isShowHs)

        player:send(packet)
    end)
end

function CommonWritter.listSkill(session)
    local player = session:get("player")
    if not player then
        return false
    end

    local skills = GameData.getSkills(player.class)

    if not skills then
        log("Not found skills for class: " .. player.class)
        return false
    end

    return try(function()
        local packet = Packet.new(Cmd.LIST_SKILL)
        packet:writeByte(skills:size())

        skills:forEach(function(skill)
            packet:writeByte(skill.sid)
            packet:writeByte(skill.icon_id)
            packet:writeUTF(skill.name)
            packet:writeByte(skill.type)
            packet:writeShort(skill.attack_range)
            packet:writeUTF(skill.description)
            packet:writeByte(skill.buff_type)
            packet:writeByte(skill.sub_effect_type)
            packet:writeByte(#skill.levels)
            for _, lv in ipairs(skill.levels) do
                packet:writeShort(lv.mpCost)
                packet:writeShort(lv.requiredLevel)
                packet:writeInt(lv.cooldown)
                packet:writeInt(lv.buffDuration)
                packet:writeByte(lv.subEffectPercent)
                packet:writeShort(lv.subEffectDuration)
                packet:writeShort(lv.bonusHp)
                packet:writeShort(lv.bonusMp)

                packet:writeByte(#lv.options)
                for _, op in ipairs(lv.options) do
                    packet:writeByte(op.id)
                    packet:writeInt(op.value)
                end

                packet:writeByte(lv.targetCount)
                packet:writeShort(lv.castRange)
            end

            packet:writeShort(skill.performDuration)
            packet:writeByte(skill.paintType)
        end)

        session:send(packet)
    end)
end

function CommonWritter.updateHealth(player)
    return try(function()
        local packet = Packet.new(Cmd.PLAYER_SUCKHOE)
        packet:writeInt(32000) -- Stamina Points
        packet:writeInt(0)     -- Arena Points
        player:send(packet)
    end)
end

function CommonWritter.sendQuest(player)
    return try(function()
        local packet = Packet.new(Cmd.QUEST)
        packet:writeByte(10)
        packet:writeByte(10)
        packet:writeByte(10)
        player:send(packet)
    end)
end

function CommonWritter:loginRms(player)
    if not player then return false end

    local data = player.rms
    return try(function()
        local packet = Packet.new(55)
        packet:writeByte(1)
        packet:writeShort(2)
        packet:writeByte(-1)
        packet:writeByte(0)
        player:send(packet)

        packet = Packet.new(55)
        packet:writeByte(2)

        if player:getMap().id == 0 and player.level < 2 then
            packet:writeShort(0)
        else
            packet:writeShort(1)
            packet:writeByte(0)
        end
        player:send(packet)

        if #data[1] > 0 then
            local bytes = string.char(table.unpack(data[1]))
            packet = Packet.new(55)
            packet:writeByte(0)
            packet:writeShort(#data[1])
            packet:writeBytes(bytes)
            player:send(packet)
        end

        if #data[2] > 0 then
            local bytes = string.char(table.unpack(data[2]))
            packet = Packet.new(55)
            packet:writeByte(3)
            packet:writeShort(#data[2])
            packet:writeBytes(bytes)
            player:send(packet)
        end
    end)
end

return CommonWritter

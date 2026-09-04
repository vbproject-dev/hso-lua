local Cmd            = require("network.Cmd")
local GameData       = require("database.GameData")
local Player         = require("modules.game.entities.Player")
local CommonResponse = {}

function CommonResponse.loginFail(session, text)
    return try(function()
        local packet = Packet.new(Cmd.LOGIN_FAIL)
        packet:writeUTF(text)
        packet:writeByte(0)
        session:send(packet)
    end)
end

function CommonResponse.noticeBox(session, text)
    return try(function()
        local packet = Packet.new(Cmd.NOTICE_BOX)
        packet:writeUTF(text)
        packet:writeUTF("")
        packet:writeByte(15)
        session:send(packet)
    end)
end

function CommonResponse.saveLogin(session, user, pass)
    return try(function()
        local packet = Packet.new(31)
        packet:writeUTF(user)
        packet:writeUTF(pass)
        session:send(packet)
    end)
end

function CommonResponse.updateData(session, count, size)
    return try(function()
        local packet = Packet.new(Cmd.UPDATE_DATA)
        packet:writeShort(count)
        packet:writeShort(size)
        session:send(packet)
    end)
end

function CommonResponse.sendPartData(session, data)
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

function CommonResponse.selectCharacter(session)
    return try(function()
        local account = session:get("account")

        local db = require("core.MySQL").instance()
        local charactersData, err = db:from("player"):where("account_id", account.id):getAll()

        if err then
            log("Failed to get characters: " .. tostring(err))
            return false
        end
        local characters = ArrayList.new()
        for __, data in ipairs(charactersData) do
            characters:add(Player.new(data))
        end

        local packet = Packet.new(Cmd.SELECT_CHAR)

        packet:writeByte(characters:size())
        characters:forEach(function(player)
            packet:writeInt(player.id)
            packet:writeUTF(player.name)

            packet:writeByte(player.info.head)
            packet:writeByte(player.info.hair)
            packet:writeByte(player.info.eye)

            packet:writeByte(player.wearing:size())
            player.wearing:forEach(function(item)
                packet:writeByte(item.info.type)
                packet:writeByte(item.info.part)
            end)

            packet:writeShort(player.level)
            packet:writeByte(player.class)
            packet:writeByte(0)
            packet:writeByte(0)

            -- Clan
            packet:writeShort(-1)
        end)
        session:send(packet)
    end)
end

function CommonResponse.monsterCatalog(session)
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

function CommonResponse.itemTemplate(session)
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

function CommonResponse.nameServer(session)
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

function CommonResponse.loadImage(session, data)
    return try(function()
        local packet = Packet.new(Cmd.LOAD_IMAGE)
        packet:writeShort(data.id)
        packet:writeBytes(data.bytes)
        session:send(packet)
    end)
end

return CommonResponse

local Cmd            = require("network.Cmd")
local GameData       = require("database.GameData")
local Player         = require("modules.game.entities.Player")
local CommonResponse = {}

function CommonResponse.sendBytes(session, cmd, bytes)
    return try(function()
        local packet = Packet.new(cmd)
        packet:writeBytes(bytes)
        session:send(packet)
    end)
end

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

function CommonResponse.fillRectUpdate(session, type)
    return try(function()
        local packet = Packet.new(Cmd.FILL_REC_UPDATE_TIME)
        packet:writeByte(type)
        if type == 3 or type == 5 then
            packet:writeByte(0)
        end
        session:send(packet)
    end)
end

function CommonResponse.mainCharInfo(session)
    return try(function()
        local player = session:get("player")
        if not player then return end

        local packet = Packet.new(Cmd.MAIN_CHAR_INFO)

        packet:writeShort(player.id)
        packet:writeUTF(player.name)
        packet:writeInt(player.hp)
        packet:writeInt(player.maxHp)
        packet:writeInt(player.mp)
        packet:writeInt(player.maxMp)
        packet:writeByte(player.info.head)
        packet:writeByte(player.class)
        packet:writeByte(player.info.eye)
        packet:writeByte(player.info.hair)

        local attr = { 0, 1, 2, 3, 4, 7, 8, 9, 10, 11, 14, 15, 16, 17, 18, 19, 20, 28, 33, 34, 35, 36, 40, 29, 30, 31, 32, 181 }

        packet:writeByte(#attr)
        for _, value in ipairs(attr) do
            packet:writeByte(value)
            packet:writeInt(0)
        end

        packet:writeShort(player.level)
        packet:writeShort(0) -- EXP PERCENT
        packet:writeShort(player.info.potential_point)
        packet:writeShort(player.info.skill_point)

        -- Bonus STATS
        packet:writeShort(0)
        packet:writeShort(0)
        packet:writeShort(0)
        packet:writeShort(0)

        -- Skill lv
        for __, id in ipairs(player.info.skill) do
            packet:writeByte(id)
        end

        -- Bonus skill lv
        for __, id in ipairs(player.info.skill) do
            packet:writeByte(0)
        end

        -- Guild
        packet:writeShort(-1)

        -- Fashion
        local fashion = { -1, -1, -1, -1, -1, -1, -1 }
        packet:writeByte(#fashion)
        for _, id in ipairs(fashion) do
            packet:writeShort(id)
        end

        packet:writeByte(0)
        packet:writeShort(-1)
        packet:writeByte(1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)
        packet:writeShort(-1)

        session:send(packet)
    end)
end

function CommonResponse.changeMap(session)
    return try(function()
        local player = session:get("player")
        if not player then return end
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
    end)
end

return CommonResponse

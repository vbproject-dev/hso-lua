local Player           = require "modules.game.entities.Player"
local Cmd              = require "network.Cmd"
local CharacterWritter = {}

function CharacterWritter.selectCharacter(session)
    return try(function()
        local account = session:get("account")


        local charactersData, err = loadTable("player", { account_id = account.id })

        if err then
            log("Failed to get characters: " .. tostring(err))
            return false
        end

        local characters = charactersData:map(function(data)
            return Player.new(data)
        end)

        local packet = Packet.new(Cmd.SELECT_CHAR)

        packet:writeByte(characters:size())
        characters:forEach(function(player)
            packet:writeInt(player.id)
            packet:writeUTF(player.name)

            packet:writeByte(player.info.head)
            packet:writeByte(player.info.hair)
            packet:writeByte(player.info.eye)

            local wearing = player.wearing:filter(function(item) return item ~= nil end)
            packet:writeByte(wearing:size())
            wearing:forEach(function(item)
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

function CharacterWritter.mainCharInfo(player)
    if not player then return false end
    return try(function()
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

        -- STATS
        packet:writeShort(0)
        packet:writeShort(0)
        packet:writeShort(0)
        packet:writeShort(0)

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

        packet:writeByte(0)   -- TypePK
        packet:writeShort(0)  -- Point PK
        packet:writeByte(126) -- MaxBag

        -- Guild
        packet:writeShort(-1)

        packet:writeUTF("A2")
        packet:writeLong(0)

        -- Fashion
        packet:writeByte(player.fashion:size())
        player.fashion:forEach(function(id)
            packet:writeShort(id)
        end)

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

        player:send(packet)
    end)
end

return CharacterWritter

local Player           = require "modules.game.entities.Player"
local Cmd              = require "network.Cmd"
local StatIds          = require "modules.game.stats.StatIds"
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

            packet:writeByte(player.part.head)
            packet:writeByte(player.part.hair)
            packet:writeByte(player.part.eye)

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
        packet:writeByte(player.part.head)
        packet:writeByte(player.class)
        packet:writeByte(player.part.eye)
        packet:writeByte(player.part.hair)

        local attributesInfo = {
            StatIds.PHYSICAL_DAMAGE,
            StatIds.ICE_DAMAGE,
            StatIds.FIRE_DAMAGE,
            StatIds.LIGHTNING_DAMAGE,
            StatIds.POISON_DAMAGE,
            StatIds.PLUS_PHYSICAL_DAMAGE,
            StatIds.PLUS_ICE_DAMAGE,
            StatIds.PLUS_FIRE_DAMAGE,
            StatIds.PLUS_LIGHTNING_DAMAGE,
            StatIds.PLUS_POISON_DAMAGE,

            StatIds.DEFENSE,
            StatIds.PLUS_DEFENSE,
            StatIds.PHYSICAL_RESIST,
            StatIds.ICE_RESIST,
            StatIds.FIRE_RESIST,
            StatIds.LIGHTNING_RESIST,
            StatIds.POISON_RESIST,

            StatIds.PLUS_MANA,
            StatIds.CRITICAL_RATE,
            StatIds.EVADE,
            StatIds.REFLECT_DAM,
            StatIds.PIERCING_ATTACK,
            StatIds.BASIC_DAMAGE,

            StatIds.REPLENISH_LIFE,
            StatIds.REGENERATE_MANA,
            StatIds.LIFE_STEAL,
            StatIds.MANA_STEAL,

        }

        packet:writeByte(#attributesInfo)
        for _, value in ipairs(attributesInfo) do
            packet:writeByte(value)
            packet:writeInt(player.stats:get(value))
        end

        packet:writeShort(player.level)
        packet:writeShort(0) -- EXP PERCENT
        packet:writeShort(player.potentialPoints)
        packet:writeShort(player.skillPoints)

        -- STATS
        packet:writeShort(player.strength)
        packet:writeShort(player.dexterity)
        packet:writeShort(player.vitality)
        packet:writeShort(player.intelligence)

        -- Bonus STATS
        packet:writeShort(0)
        packet:writeShort(0)
        packet:writeShort(0)
        packet:writeShort(0)

        -- Skill lv
        player.skills:forEach(function(skill)
            packet:writeByte(skill.level)
        end)

        -- Bonus skill lv , dummy for now
        player.skills:forEach(function(skill)
            packet:writeByte(0)
        end)

        packet:writeByte(player.typePK)   -- TypePK
        packet:writeShort(player.pointPK) -- Point PK
        packet:writeByte(126)             -- MaxBag

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

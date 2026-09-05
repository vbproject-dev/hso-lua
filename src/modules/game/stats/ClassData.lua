--[[
    ClassData

    Growth is keyed by (classId, typeId) -> 8 combinations total:

        ASSASSIN/PHYSICAL   ASSASSIN/MAGICAL
        WARRIOR /PHYSICAL   WARRIOR /MAGICAL
        GUNNER  /PHYSICAL   GUNNER  /MAGICAL
        MAGE    /PHYSICAL   MAGE    /MAGICAL

    Each combo grants primary attributes (STR/DEX/VIT/INT) + Defense --
    AttributeFormulas.compute() turns those into combat stats. The
    PHYSICAL row of a class leans its growth into STR/DEX (feeds Physical
    Damage / Crit / Evade); the MAGICAL row leans into INT, which
    AttributeFormulas routes into that class's *signature element*
    (see MAGIC_ELEMENT below) instead of Physical Damage.

    Each row also grants flat "Basic Damage" (stat id 40) per level. Basic
    Damage is intentionally separate from the STR/INT pipeline: it's the
    character's innate damage floor that grows just from leveling, on top
    of whatever Physical/elemental damage their build produces -- and
    equipment can add to it directly too, since it's an ordinary flat stat
    in the item_option table (no code change needed for gear to grant it).

    Note this is NOT how potential points work -- STR/DEX/VIT/INT growth
    here is automatic (tied to level), separate from the +4 potential
    points per level the player spends manually via
    Player:allocatePotentialPoint() into a different layer
    (stats.attributes). Both layers get summed together before
    AttributeFormulas runs, so it doesn't matter to the formulas which
    layer an attribute point came from.

    Tune every number here freely -- this is example balancing, not a
    fixed contract. The one thing other code depends on is the shape:
    getBaseStats() returns { [statId] = value } for
    STR/DEX/VIT/INT/DEFENSE/BASIC_DAMAGE.
]]

local StatIds = require("modules.game.stats.StatIds")
local ClassIds = require("modules.game.entities.ClassIds")

local CLASS = ClassIds.CLASS
local TYPE = ClassIds.TYPE

local ClassData = {}

-- [classId][typeId] -> per-level growth
local GROWTH = {

    [CLASS.WARRIOR] = {
        [TYPE.PHYSICAL] = { strength = 5, dexterity = 1, vitality = 4, intelligence = 0, defense = 3, basicDamage = 10 },
        [TYPE.MAGICAL]  = { strength = 2, dexterity = 1, vitality = 3, intelligence = 4, defense = 2, basicDamage = 7 },
    },
    [CLASS.ASSASSIN] = {
        [TYPE.PHYSICAL] = { strength = 2, dexterity = 5, vitality = 2, intelligence = 0, defense = 1, basicDamage = 8 },
        [TYPE.MAGICAL]  = { strength = 0, dexterity = 3, vitality = 2, intelligence = 4, defense = 1, basicDamage = 6 },
    },
    [CLASS.MAGE] = {
        [TYPE.PHYSICAL] = { strength = 2, dexterity = 2, vitality = 2, intelligence = 3, defense = 1, basicDamage = 7 },
        [TYPE.MAGICAL]  = { strength = 0, dexterity = 0, vitality = 2, intelligence = 6, defense = 1, basicDamage = 6 },
    },
    [CLASS.GUNNER] = {
        [TYPE.PHYSICAL] = { strength = 1, dexterity = 5, vitality = 2, intelligence = 1, defense = 1, basicDamage = 8 },
        [TYPE.MAGICAL]  = { strength = 0, dexterity = 3, vitality = 2, intelligence = 4, defense = 1, basicDamage = 6 },
    },

}

-- Each class's signature element -- this is what a MAGICAL build's
-- Intelligence converts into (via AttributeFormulas). Pick whatever fits
-- your game's fantasy per class; PHYSICAL builds never use this, they
-- always feed Physical Damage regardless of class.
local MAGIC_ELEMENT = {
    [CLASS.WARRIOR]  = StatIds.FIRE_DAMAGE,
    [CLASS.ASSASSIN] = StatIds.POISON_DAMAGE,
    [CLASS.MAGE]     = StatIds.ICE_DAMAGE,
    [CLASS.GUNNER]   = StatIds.LIGHTNING_DAMAGE,
}

local DEFAULT_GROWTH = GROWTH[CLASS.WARRIOR][TYPE.PHYSICAL]
local DEFAULT_ELEMENT = StatIds.FIRE_DAMAGE

--- @return table { [statId] = value } base STR/DEX/VIT/INT/DEFENSE/BASIC_DAMAGE at this class/type/level
function ClassData.getBaseStats(classId, typeId, level)
    local row = GROWTH[classId] and GROWTH[classId][typeId] or DEFAULT_GROWTH

    return {
        [StatIds.STRENGTH]     = row.strength * level,
        [StatIds.DEXTERITY]    = row.dexterity * level,
        [StatIds.VITALITY]     = row.vitality * level,
        [StatIds.INTELLIGENCE] = row.intelligence * level,
        [StatIds.DEFENSE]      = row.defense * level,
        [StatIds.BASIC_DAMAGE] = row.basicDamage * level,
    }
end

--- Which elemental damage stat id this class's Intelligence feeds when
-- the player's combat type is MAGICAL. Ignored for PHYSICAL builds.
function ClassData.getMagicElement(classId)
    return MAGIC_ELEMENT[classId] or DEFAULT_ELEMENT
end

return ClassData

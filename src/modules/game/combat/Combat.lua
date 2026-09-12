local DamageType = require "modules.game.combat.DamageType"
local StatIds    = require "modules.game.stats.StatIds"
local Combat     = {}

function Combat.dealDamageTo(player, target, skill)
    if target:isDead() then return end

    local baseDamage = Combat.calculateBaseDamage(player.stats, skill:getDamageType())
    local skillDamage = Combat.calculateSkillDamage(baseDamage, skill)


    log("Deal " .. skillDamage .. " damage to " .. target.name)
end

function Combat.calculateBaseDamage(stats, damageType)
    local basic = stats:get(StatIds.BASIC_DAMAGE)
    local element = 0

    if damageType == DamageType.PHYSICAL then
        element = stats:get(StatIds.PHYSICAL_DAMAGE)
    elseif damageType == DamageType.FIRE then
        element = stats:get(StatIds.PHYSICAL_DAMAGE)
    elseif damageType == DamageType.ICE then
        element = stats:get(StatIds.ICE_DAMAGE)
    elseif damageType == DamageType.POISON then
        element = stats:get(StatIds.POISON)
    elseif damageType == DamageType.LIGHTING then
        element = stats:get(StatIds.LIGHTNING_DAMAGE)
    elseif damageType == DamageType.LIGHT then
        element = stats:get(StatIds.HOLY_DAMAGE)
    elseif damageType == DamageType.DARK then
        element = stats:get(StatIds.DARKNEST_DAMAGE)
    end

    return basic + element
end

function Combat.calculateSkillDamage(baseDamage, skill)
    local flatDmg = 0
    local percentBonus = 0

    for _, op in ipairs(skill.levelData.options) do
        local type = op.id
        if type == StatIds.PHYSICAL_DAMAGE
            or type == StatIds.FIRE_DAMAGE
            or type == StatIds.ICE_DAMAGE
            or type == StatIds.POISON_DAMAGE
            or type == StatIds.LIGHTNING_DAMAGE
            or type == StatIds.HOLY_DAMAGE
            or type == StatIds.DARKNEST_DAMAGE then
            flatDmg = flatDmg + op.value
        elseif type == StatIds.PLUS_PHYSICAL_DAMAGE
            or type == StatIds.PLUS_ICE_DAMAGE
            or type == StatIds.PLUS_LIGHTNING_DAMAGE
            or type == StatIds.PLUS_FIRE_DAMAGE
            or type == StatIds.PLUS_POISON_DAMAGE
            or type == StatIds.PLUS_HOLY_DAMAGE
            or type == StatIds.PLUS_DARKEST_DAMAGE then
            percentBonus = percentBonus + op.value
        end
    end

    local percentRate = percentBonus / 10000
    local skillDamage = math.floor(baseDamage * (1 + percentRate) + 0.5) + flatDmg

    return math.max(0, skillDamage)
end

return Combat

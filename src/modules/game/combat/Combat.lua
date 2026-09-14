local DamageType = require "modules.game.combat.DamageType"
local StatIds    = require "modules.game.stats.StatIds"
local Combat     = {}

function Combat.dealDamageTo(player, target, skill)
    if target:isDead() then return end

    local baseDamage = Combat.calculateBaseDamage(player.stats, skill:getDamageType())
    local skillDamage = Combat.calculateSkillDamage(baseDamage, skill)


    local damageContext = {
        damage = skillDamage,
        damageType = skill:getDamageType(),
        isPenetrated = false,
        isEvaded = false,
        lifesteal = 0,
        manasteal = 0
    }

    local textDamage = {}

    -- Normal Damage
    table.insert(textDamage, { id = 0, damage = skillDamage })
    if Combat.isPenetration(target.stats) then
        local penDamage = 0
        damageContext.isPenetrated = true
        table.insert(textDamage, { id = 3, damage = penDamage })
    end

    if Combat.isCritical(player.stats) then
        damageContext.damage = math.floor(damageContext.damage * 1.5 + 0.5)
        table.insert(textDamage, { id = 4, damage = damageContext.damage })
    end
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

function Combat.isCritical(stats)
    return math.random(10000) <= stats:get(StatIds.CRITICAL_RATE)
end

function Combat.isPenetration(stats)
    return math.random(10000) <= stats:get(StatIds.PIERCING_ATTACK)
end

function Combat.isEvade(stats)
    return math.random(10000) <= stats:get(StatIds.EVADE)
end

function Combat.calculateLifesteal(stats, damage)
    return math.floor(damage * stats:get(StatIds.LIFE_STEAL) / 10000)
end

function Combat.calculateManaSteal(stats, damage)
    return math.floor(damage * stats:get(StatIds.MANA_STEAL) / 10000)
end

function Combat.calculatePenetrationDamage(stats, damage)
    return math.floor(damage * stats:get(StatIds.PIERCING_ATTACK) / 10000 + 0.5)
end

return Combat

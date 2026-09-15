local DamageType  = require "modules.game.combat.DamageType"
local StatIds     = require "modules.game.stats.StatIds"
local GameWritter = require "modules.writters.GameWritter"
local Combat      = {}

function Combat.dealDamageTo(player, target, skill)
    if target:isDead() then
        log("target %d is dead", target.id)
        return
    end

    local baseDamage = Combat.calculateBaseDamage(player.stats, skill:getDamageType())
    local skillDamage = Combat.calculateSkillDamage(baseDamage, skill)
    local finalDamage = 0
    local textDamage = {}


    if Combat.isEvade(target.stats) then
        table.insert(textDamage, { id = 0, value = 0 })
        finalDamage = 0
    else
        local result = Combat.calculateFinalDamage(player.stats, target.stats, skillDamage, skill:getDamageType())


        finalDamage = result.damage

        if result.isPenetration then
            table.insert(textDamage, { id = 1, value = finalDamage })
        end

        -- Critical Hit
        if Combat.isCritical(player.stats) then
            finalDamage = math.floor(result.damage * 1.5 + 0.5)
            table.insert(textDamage, { id = 4, value = finalDamage })
        else
            table.insert(textDamage, { id = 0, value = finalDamage })
        end

        target:takeDamage(finalDamage)

        -- Reflect Damage
        if not target:isDead() then
            local reflect = Combat.calculateReflectDamage(target.stats, finalDamage)
            if reflect > 0 then
                player:takeDamage(reflect)
                table.insert(textDamage, { id = 5, value = reflect })
            end
        end

        -- Lifesteal
        if not player:isDead() then
            local lifesteal = Combat.calculateLifesteal(player.stats, finalDamage)
            if lifesteal > 0 then
                player.hp = math.min(player.maxHp, player.hp + lifesteal)
                table.insert(textDamage, { id = 2, value = lifesteal })
            end
        end

        -- Manasteal
        if not player:isDead() then
            local manasteal = Combat.calculateManaSteal(player.stats, finalDamage)
            if manasteal > 0 then
                player.mp = math.min(player.maxMp, player.mp + manasteal)
                table.insert(textDamage, { id = 3, value = manasteal })
            end
        end
    end

    log(player.name .. " deal " .. finalDamage .. " damage to " .. target.id .. " damage " .. finalDamage)
    target.zone:forEachPlayer(function(other)
        GameWritter.fireMonster(other, {
            attacker = player,
            target = target,
            skill = skill,
            finalDamage = finalDamage,
            textDamage = textDamage,
        })
    end)
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

function Combat.isPenetration()
    return math.random(100) <= 30
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

function Combat.calculateReflectDamage(stats, damage)
    return math.floor(damage * stats:get(StatIds.REFLECT_DAM) / 10000 + 0.5)
end

function Combat.calculateFinalDamage(attackerStats, stats, damage, damageType)
    local damage = math.max(0, damage or 0)
    local reduction = 0
    local reduceResist = 0
    local blockDamage = 0
    local penetration = 0

    local context = {
        isPenetration = false,
        damage = 0,
    }

    if damageType == DamageType.PHYSICAL then
        reduction = stats:get(StatIds.PHYSICAL_RESIST)
        reduceResist = stats:get(StatIds.REDUCE_PHYSICAL_RESIST)
        blockDamage = stats:get(StatIds.BLOCK_PHYSICAL_DAMAGE)
    elseif damageType == DamageType.FIRE then
        reduction = stats:get(StatIds.FIRE_RESIST)
        reduceResist = stats:get(StatIds.REDUCE_FIRE_RESIST)
        blockDamage = stats:get(StatIds.BLOCK_FIRE_DAMAGE)
    elseif damageType == DamageType.ICE then
        reduction = stats:get(StatIds.ICE_RESIST)
        reduceResist = stats:get(StatIds.REDUCE_ICE_RESIST)
        blockDamage = stats:get(StatIds.BLOCK_ICE_DAMAGE)
    elseif damageType == DamageType.POISON then
        reduction = stats:get(StatIds.POISON_RESIST)
        reduceResist = stats:get(StatIds.REDUCE_POISON_RESIST)
        blockDamage = stats:get(StatIds.BLOCK_POISON_DAMAGE)
    elseif damageType == DamageType.LIGHTING then
        reduction = stats:get(StatIds.LIGHTNING_RESIST)
        reduceResist = stats:get(StatIds.REDUCE_LIGHTNING_RESIST)
        blockDamage = stats:get(StatIds.BLOCK_LIGHTNING_DAMAGE)
    elseif damageType == DamageType.LIGHT then
        reduction = stats:get(StatIds.HOLY_RESIST)
    elseif damageType == DamageType.DARK then
        reduction = stats:get(StatIds.DARKEST_RESIST)
    end

    reduction = math.max(0, reduction - reduceResist)

    if Combat.isPenetration() then
        penetration = attackerStats:get(StatIds.PIERCING_ATTACK)
        context.isPenetration = true
    end

    damage = damage * (1 - reduction / 10000)

    if context.isPenetration and penetration > 0 then
        damage = damage * (1 - penetration / 10000)
    end

    damage = damage * (1 - blockDamage / 10000)

    context.damage = math.max(0, math.floor(damage + 0.5))

    return context
end

return Combat

local StatIds = require("modules.game.stats.StatIds")
local ClassIds = require("modules.game.entities.ClassIds")

local S = StatIds
local C = ClassIds.CLASS
local AttributeFormulas = {}

function AttributeFormulas.compute(class, flatSums)
    local str = flatSums[S.STRENGTH] or 0
    local dex = flatSums[S.DEXTERITY] or 0
    local vit = flatSums[S.VITALITY] or 0
    local intel = flatSums[S.INTELLIGENCE] or 0

    if class == C.WARRIOR then
        return {
            [S.CRITICAL_RATE] = str * 0.02,
            [S.BASIC_DAMAGE] = str * 0.02,
            [S.PHYSICAL_DAMAGE] = str * 4,
            [S.FIRE_DAMAGE] = str * 4,
            [S.EVADE] = dex * 0.02,
            [S.DEFENSE] = dex * 20,
            [S.PLUS_DEFENSE] = dex * 0.01,
            [S.REFLECT_DAM] = vit * 0.02,
            [S.HP] = vit * 320,
            [S.PIERCING_ATTACK] = intel * 0.02,
            [S.MP] = intel * 10
        }
    elseif class == C.ASSASSIN then
        return {
            [S.CRITICAL_RATE] = str * 0.02,
            [S.BASIC_DAMAGE] = str * 0.02,
            [S.PHYSICAL_DAMAGE] = str * 4,
            [S.POISON_DAMAGE] = str * 4,
            [S.EVADE] = dex * 0.02,
            [S.DEFENSE] = dex * 22,
            [S.PLUS_DEFENSE] = dex * 0.01,
            [S.REFLECT_DAM] = vit * 0.02,
            [S.HP] = vit * 300,
            [S.PIERCING_ATTACK] = intel * 0.02,
            [S.MP] = intel * 10
        }
    elseif class == C.MAGE then
        return {
            [S.CRITICAL_RATE] = str * 0.02,
            [S.BASIC_DAMAGE] = str * 0.02,
            [S.EVADE] = dex * 0.02,
            [S.DEFENSE] = dex * 20,
            [S.PLUS_DEFENSE] = dex * 0.01,
            [S.HP] = vit * 310,
            [S.MP] = vit + intel * 11,
            [S.PHYSICAL_DAMAGE] = intel * 4,
            [S.ICE_DAMAGE] = intel * 4,
            [S.PLUS_PHYSICAL_DAMAGE] = intel * 0.018,
            [S.PLUS_ICE_DAMAGE] = intel * 0.018,
            [S.PIERCING_ATTACK] = intel * 0.02
        }
    elseif class == C.GUNNER then
        return {
            [S.CRITICAL_RATE] = str * 0.02,
            [S.BASIC_DAMAGE] = str * 0.02,
            [S.EVADE] = dex * 0.02,
            [S.DEFENSE] = dex * 22,
            [S.PLUS_DEFENSE] = dex * 0.01,
            [S.REFLECT_DAM] = vit * 0.02,
            [S.HP] = vit * 300,
            [S.PHYSICAL_DAMAGE] = intel * 4,
            [S.LIGHTNING_DAMAGE] = intel * 4,
            [S.PLUS_PHYSICAL_DAMAGE] = intel * 0.018,
            [S.PLUS_LIGHTNING_DAMAGE] = intel * 0.018,
            [S.MP] = intel * 11,
            [S.PIERCING_ATTACK] = intel * 0.02
        }
    end

    return {}
end

return AttributeFormulas

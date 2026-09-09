local StatIds = require("modules.game.stats.StatIds")

local AttributeFormulas = {}

function AttributeFormulas.compute(flatSums, percentSums)
    local str   = flatSums[StatIds.STRENGTH] or 0
    local dex   = flatSums[StatIds.DEXTERITY] or 0
    local vit   = flatSums[StatIds.VITALITY] or 0
    local intel = flatSums[StatIds.INTELLIGENCE] or 0

    return {
        [StatIds.BASIC_DAMAGE]    = str * 4,
        [StatIds.PHYSICAL_DAMAGE] = str * 4,
        [StatIds.HP]              = vit * 310,
        [StatIds.MP]              = intel * 11,

        [StatIds.CRITICAL_RATE]   = str * 10,
        [StatIds.EVADE]           = dex * 20,
        [StatIds.DEFENSE]         = dex * 20,
        [StatIds.PLUS_DEFENSE]    = dex * 10,
        [StatIds.REFLECT_DAM]     = vit * 20,
        [StatIds.PIERCING_ATTACK] = intel * 10,
    }
end

return AttributeFormulas

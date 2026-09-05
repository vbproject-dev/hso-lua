--[[
    AttributeFormulas

    "Primary stat -> combat stat" conversion, the classic ARPG-style layer
    sitting on top of class/level/equipment/buffs.

    Strength always feeds Physical Damage and Intelligence always feeds a
    magic element -- but WHICH element depends on the player's class (see
    ClassData.getMagicElement), so this function takes that as a
    parameter instead of hardcoding one. Player wires this up once per
    instance (see Player:ctor) via StatManager:setDerivedFormula(fn).

    Tune the multipliers to your own balance -- the important part is the
    wiring: this function is handed the fully-summed flat/percent totals
    (from every layer, including equipment/buffs that grant +Strength
    etc.) and returns extra flat/percent contributions to merge in.
]]

local StatIds = require("modules.game.stats.StatIds")

local AttributeFormulas = {}

--- @param flatSums     table of { [statId] = summed flat value }
-- @param percentSums  table of { [statId] = summed percent value }
-- @param magicElementId  stat id this player's Intelligence converts into
--                        (from ClassData.getMagicElement(player.class))
-- @return table { [statId] = value } extra contributions from attributes
function AttributeFormulas.compute(flatSums, percentSums, magicElementId)
    local str    = flatSums[StatIds.STRENGTH] or 0
    local dex    = flatSums[StatIds.DEXTERITY] or 0
    local vit    = flatSums[StatIds.VITALITY] or 0
    local intel  = flatSums[StatIds.INTELLIGENCE] or 0

    local result = {
        [StatIds.PHYSICAL_DAMAGE] = str * 2,    -- 1 STR -> +2 physical damage
        [StatIds.HP]              = vit * 210,  -- 1 VIT -> +210 max HP
        [StatIds.MP]              = intel * 5,  -- 1 INT -> +5 max MP
        [StatIds.CRITICAL_RATE]   = dex * 0.02, -- 1 DEX -> +0.02% crit rate
        [StatIds.EVADE]           = dex * 0.02, -- 1 DEX -> +0.02% evade
    }

    if magicElementId then
        -- 1 INT -> +3 damage in this class's signature element
        result[magicElementId] = (result[magicElementId] or 0) + intel * 3
    end

    return result
end

return AttributeFormulas

local GameData      = require("database.GameData")
local StatIds       = require("modules.game.stats.StatIds")

local StatDefs      = {}

local flatToPercent = {}
local percentToFlat = {}

function StatDefs.pair(flatId, percentId)
    flatToPercent[flatId] = percentId
    percentToFlat[percentId] = flatId
end

local FLAT_PERCENT_PAIRS = {
    { StatIds.PHYSICAL_DAMAGE,  StatIds.PLUS_PHYSICAL_DAMAGE },  -- Physical Damage <-> + Physical Damage
    { StatIds.ICE_DAMAGE,       StatIds.PLUS_ICE_DAMAGE },       -- Ice Damage <-> + Ice Damage
    { StatIds.FIRE_DAMAGE,      StatIds.PLUS_FIRE_DAMAGE },      -- Fire Damage <-> + Fire Damage
    { StatIds.LIGHTNING_DAMAGE, StatIds.PLUS_LIGHTNING_DAMAGE }, -- Lightning Damage <-> + Lightning Damage
    { StatIds.POISON_DAMAGE,    StatIds.PLUS_POISON_DAMAGE },    -- Poison Damage <-> + Poison Damage
    { StatIds.DARKNEST_DAMAGE,  StatIds.PLUS_DARKEST_DAMAGE },   -- Darknest Damage <-> + Darkest Damage
    { StatIds.HOLY_DAMAGE,      StatIds.PLUS_HOLY_DAMAGE },      -- Holy Damage <-> + Holy Damage
    { StatIds.DEFENSE,          StatIds.PLUS_DEFENSE },          -- Defense <-> + Defense
    { StatIds.HP,               StatIds.PLUS_LIFE },             -- HP <-> + Life
    { StatIds.MP,               StatIds.PLUS_MANA },             -- MP <-> + Mana
}
for _, p in ipairs(FLAT_PERCENT_PAIRS) do
    StatDefs.pair(p[1], p[2])
end



local cache = {}

--- Raw def row: { id, name, color, percent, bonus_upgrade }
function StatDefs.get(id)
    local cached = cache[id]
    if cached ~= nil then
        return cached or nil
    end
    local def = GameData.getOption(id)
    cache[id] = def or false
    return def
end

--- Call this if GameData.options is ever reloaded at runtime (e.g. a live
-- content reload / GM tool), so stale lookups aren't served.
function StatDefs.clearCache()
    cache = {}
end

function StatDefs.name(id)
    local def = StatDefs.get(id)
    return def and def.name or ("Unknown stat #" .. tostring(id))
end

function StatDefs.isPercent(id)
    local def = StatDefs.get(id)
    return def ~= nil and def.percent == 1
end

function StatDefs.bonusUpgrade(id)
    local def = StatDefs.get(id)
    return def and def.bonus_upgrade or 0
end

function StatDefs.color(id)
    local def = StatDefs.get(id)
    return def and def.color or 0
end

function StatDefs.flatIdFor(percentId)
    return percentToFlat[percentId]
end

function StatDefs.percentIdFor(flatId)
    return flatToPercent[flatId]
end

return StatDefs

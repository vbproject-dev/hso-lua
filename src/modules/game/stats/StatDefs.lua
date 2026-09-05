--[[
    StatDefs

    Thin wrapper around GameData.options (your item_option table) that adds
    the two things the stat engine needs beyond plain metadata lookup:

      1. A memoized get(id)/isPercent(id)/bonusUpgrade(id) so StatManager
         isn't doing a linear GameData.options:findFirst() scan on every
         single stat access.

      2. An EXPLICIT flat <-> percent-modifier pairing table.

    IMPORTANT: pairing is intentionally NOT auto-derived from names (e.g.
    stripping a "+ " prefix). The real item_option table reuses the same
    name for unrelated ids in at least 21 places (id 61/124/125/126/127 are
    all called "Enchanted", id 34 and 99 are both "Evade", id 16 and 102
    are both "Physical resist", etc). Guessing pairs from names would
    silently apply the wrong multiplier to the wrong stat. Instead, only
    the pairs listed in FLAT_PERCENT_PAIRS below behave as
    "final = flat * (1 + percent/100)" -- every other stat (crit rate,
    evade, life steal, resists, proc chances, status flags, ...) is just
    summed as-is across layers, which is what those columns actually mean
    in this table.

    If you add a new genuine flat/percent pair later, register it with
    StatDefs.pair(flatId, percentId) -- e.g. during boot, right after
    GameData.load().
]]

local GameData = require("modules.game.data.GameData")

local StatDefs = {}

-- id -> id, built from FLAT_PERCENT_PAIRS below
local flatToPercent = {}
local percentToFlat = {}

function StatDefs.pair(flatId, percentId)
    flatToPercent[flatId] = percentId
    percentToFlat[percentId] = flatId
end

-- Known, verified pairs from the real item_option table (data/stat_defs.json):
--   0-6   elemental damage           <-> 7-13  "+ <Element> Damage" (%)
--   14    Defense                    <-> 15    "+ Defense" (%)
--   231   HP (max HP)                <-> 27    "+ Life" (%)
--   232   MP (max MP)                <-> 28    "+ Mana" (%)
local FLAT_PERCENT_PAIRS = {
    { 0, 7 },   -- Physical Damage <-> + Physical Damage
    { 1, 8 },   -- Ice Damage <-> + Ice Damage
    { 2, 9 },   -- Fire Damage <-> + Fire Damage
    { 3, 10 },  -- Lightning Damage <-> + Lightning Damage
    { 4, 11 },  -- Poison Damage <-> + Poison Damage
    { 5, 12 },  -- Darknest Damage <-> + Darkest Damage
    { 6, 13 },  -- Holy Damage <-> + Holy Damage
    { 14, 15 }, -- Defense <-> + Defense
    { 231, 27 },-- HP <-> + Life
    { 232, 28 },-- MP <-> + Mana
}
for _, p in ipairs(FLAT_PERCENT_PAIRS) do
    StatDefs.pair(p[1], p[2])
end

-- ---------------------------------------------------------------------
-- Lookup (memoized against GameData.options)
-- ---------------------------------------------------------------------

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

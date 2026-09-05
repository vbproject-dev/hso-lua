--[[
    StatManager

    Combines multiple stat "layers" into one final, computed Stats:

      base       - derived from class/level (recalculated on level up)
      equipment  - sum of everything currently worn (recalculated on equip/unequip)
      buffs      - any number of independent, optionally-timed layers
                   (potions, skills, auras, debuffs, ...)

    Calculation rule: for every flat stat id, find its paired "+ percent"
    stat id (via StatDefs) and apply:

        final = flatSum * (1 + percentSum / 100)

    Results are cached until something calls `markDirty()` (add/remove a
    buff, change equipment, change base stats, or a buff naturally expires).
]]

local Stats = require("modules.game.stats.Stats")
local StatDefs = require("modules.game.stats.StatDefs")

local StatManager = class("StatManager")

function StatManager:ctor()
    self.base = Stats.new()
    self.equipment = Stats.new()
    self.attributes = Stats.new() -- allocated primary attribute points (STR/DEX/VIT/INT, ...)
    self.buffs = {}   -- [key] = { stats = Stats, expireAt = number|nil }
    self.final = Stats.new()
    self.dirty = true

    -- Optional hook: fn(flatSums, percentSums) -> { [statId] = value, ... }
    -- Lets a specific game inject "primary attributes -> combat stats"
    -- formulas (e.g. 1 Vitality -> +10 HP) without this generic stats
    -- engine needing to know those formulas itself. See AttributeFormulas.
    self.derivedFormula = nil
end

function StatManager:setDerivedFormula(fn)
    self.derivedFormula = fn
    self:markDirty()
end

function StatManager:markDirty()
    self.dirty = true
end

-- ---------------------------------------------------------------------
-- Buffs / temporary stats
-- ---------------------------------------------------------------------

--- Add (or replace) a named temporary stat layer.
-- @param key        unique identifier for this buff, e.g. "potion_str", "skill_rage"
-- @param statsData  table of { [statId] = value, ... }
-- @param duration   seconds, or nil/false for a permanent layer (until removeBuff is called)
-- @param now        current time (os.time() or your game clock); defaults to os.time()
function StatManager:addBuff(key, statsData, duration, now)
    now = now or os.time()
    local s = Stats.new()
    for id, value in pairs(statsData) do
        s:set(id, value)
    end
    self.buffs[key] = {
        stats = s,
        expireAt = duration and (now + duration) or nil,
    }
    self:markDirty()
end

function StatManager:hasBuff(key)
    return self.buffs[key] ~= nil
end

function StatManager:removeBuff(key)
    if self.buffs[key] then
        self.buffs[key] = nil
        self:markDirty()
        return true
    end
    return false
end

function StatManager:removeAllBuffs()
    self.buffs = {}
    self:markDirty()
end

--- Call this periodically (e.g. every server tick, or every second) to
-- expire timed buffs. Cheap no-op if nothing changed.
function StatManager:update(now)
    now = now or os.time()
    local changed = false
    for key, buff in pairs(self.buffs) do
        if buff.expireAt and now >= buff.expireAt then
            self.buffs[key] = nil
            changed = true
        end
    end
    if changed then
        self:markDirty()
    end
    return changed
end

-- ---------------------------------------------------------------------
-- Calculation
-- ---------------------------------------------------------------------

function StatManager:calculate()
    if not self.dirty then
        return self.final
    end

    local flatSums = {}
    local percentSums = {}

    local function collect(layer)
        for id, value in pairs(layer:all()) do
            if StatDefs.isPercent(id) then
                percentSums[id] = (percentSums[id] or 0) + value
            else
                flatSums[id] = (flatSums[id] or 0) + value
            end
        end
    end

    collect(self.base)
    collect(self.equipment)
    collect(self.attributes)
    for _, buff in pairs(self.buffs) do
        collect(buff.stats)
    end

    -- Derived stats (e.g. primary attributes -> combat stats) see the
    -- fully-summed totals from every other layer, so equipment/buffs that
    -- grant +Strength etc. correctly flow through into their formulas.
    if self.derivedFormula then
        local derived = self.derivedFormula(flatSums, percentSums) or {}
        for id, value in pairs(derived) do
            if StatDefs.isPercent(id) then
                percentSums[id] = (percentSums[id] or 0) + value
            else
                flatSums[id] = (flatSums[id] or 0) + value
            end
        end
    end

    self.final:reset()

    for id, flatValue in pairs(flatSums) do
        local percentId = StatDefs.percentIdFor(id)
        local percentValue = percentId and (percentSums[percentId] or 0) or 0
        self.final:set(id, flatValue * (1 + percentValue / 100))
    end

    -- Percent stats that have no matching flat stat still get exposed
    -- (rare, but avoids silently dropping data if a % stat has no base).
    for id, percentValue in pairs(percentSums) do
        if not StatDefs.flatIdFor(id) then
            self.final:set(id, percentValue)
        end
    end

    self.dirty = false
    return self.final
end

function StatManager:get(id)
    return self:calculate():get(id)
end

function StatManager:all()
    return self:calculate():all()
end

return StatManager

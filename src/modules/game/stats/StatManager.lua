local Stats = require("modules.game.stats.Stats")
local StatDefs = require("modules.game.stats.StatDefs")

local StatManager = class("StatManager")

function StatManager:ctor(class)
    self.class = class
    self.equipment = Stats.new()  -- Attribute from equipment
    self.attributes = Stats.new() -- Base Attribute based from STR, DEX, VIT, INT
    self.skills = Stats.new()     -- Pasive Skills
    self.buffs = {}               -- Buffs temporary attributes

    self.derivedFormula = nil
end

function StatManager:setDerivedFormula(fn)
    self.derivedFormula = fn
end

function StatManager:addBuff(key, statsData, duration, now)
    now = now or os.time()

    local stats = Stats.new()

    for id, value in pairs(statsData) do
        stats:set(id, value)
    end

    self.buffs[key] = {
        stats = stats,
        expireAt = duration and (now + duration) or nil,
    }
end

function StatManager:hasBuff(key)
    return self.buffs[key] ~= nil
end

function StatManager:removeBuff(key)
    if not self.buffs[key] then
        return false
    end

    self.buffs[key] = nil
    return true
end

function StatManager:removeAllBuffs()
    self.buffs = {}
end

function StatManager:update(now)
    now = now or os.time()

    local changed = false

    for key, buff in pairs(self.buffs) do
        if buff.expireAt and now >= buff.expireAt then
            self.buffs[key] = nil
            changed = true
        end
    end

    return changed
end

function StatManager:calculate()
    local flatSums = {}
    local percentSums = {}

    local function collect(stats)
        for id, value in pairs(stats:all()) do
            if StatDefs.isPercent(id) then
                percentSums[id] = (percentSums[id] or 0) + value
            else
                flatSums[id] = (flatSums[id] or 0) + value
            end
        end
    end

    collect(self.equipment)
    collect(self.attributes)
    collect(self.skills)
    for _, buff in pairs(self.buffs) do
        collect(buff.stats)
    end

    if self.derivedFormula then
        local derived = self.derivedFormula(self.class, flatSums) or {}

        for id, value in pairs(derived) do
            if StatDefs.isPercent(id) then
                percentSums[id] = (percentSums[id] or 0) + value
            else
                flatSums[id] = (flatSums[id] or 0) + value
            end
        end
    end

    local final = Stats.new()

    for id, flatValue in pairs(flatSums) do
        local percentId = StatDefs.percentIdFor(id)
        local percentValue = percentId and (percentSums[percentId] or 0) or 0

        final:set(id, flatValue * (1 + percentValue / 100))
    end

    for id, percentValue in pairs(percentSums) do
        final:set(id, percentValue)
    end

    return final
end

function StatManager:get(id)
    return self:calculate():get(id)
end

function StatManager:getBonusAttribute(id)
    local value = self.equipment:get(id) + self.skills:get(id)

    for _, buff in pairs(self.buffs) do
        value = value + buff.stats:get(id)
    end

    return value
end

function StatManager:all()
    return self:calculate():all()
end

function StatManager:reset()
    self.attributes:reset()
    self.equipment:reset()
    self.skills:reset()
    self.buffs = {}
end

return StatManager

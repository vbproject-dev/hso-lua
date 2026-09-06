local ClassIds = require "modules.game.entities.ClassIds"
local Skill = class("Skill")

Skill.PHYSICAL_SKILLS = {
    [0] = true,
    [1] = true,
    [3] = true,
    [5] = true,
    [7] = true,
    [19] = true
}

function Skill:ctor(level, data)
    self.level = level
    self.id = data.sid
    self.levels = ArrayList.new(data.levels)
    self.type = data.type
    self.buffType = data.buffType
    self.role = data.role
    self.levelData = level > 0 and self.levels:get(level - 1) or {}
    self.lastUsedTime = 0

    log("skill id %d curLevel %d of %d", self.id, level, self.levels:size())
end

function Skill:upgrade(playerLevel, value)
    local targetLevel = math.min(self.level + value, self.levels:size())
    local newLevel = self.level

    for lv = self.level + 1, targetLevel do
        if not self:canLearn(lv, playerLevel) then break end
        newLevel = lv
    end

    if newLevel == self.level then return false end

    self.level = newLevel
    self.levelData = self.levels:get(newLevel - 1)
    return true
end

function Skill:canUpgrade(playerLevel, value)
    local targetLevel = math.min(self.level + value, self.levels:size())

    for lv = self.level + 1, targetLevel do
        if not self:canLearn(lv, playerLevel) then
            return false
        end
    end

    return true
end

function Skill:isOnCooldown()
    if self.lastUsedTime == 0 then return false end

    local elapsedTime = os.time() * 1000 - self.lastUsedTime
    local adjustedCooldown = math.max(0, self.levelData.cooldown - 1000)

    return elapsedTime < adjustedCooldown
end

function Skill:getRemainingCooldown()
    if not self:isOnCooldown() then return 0 end

    local elapsedTime = os.time() * 1000 - self.lastUsedTime
    local adjustedCooldown = math.max(0, self.levelData.cooldown - 1000)

    return math.max(0, adjustedCooldown - elapsedTime)
end

function Skill:onUse()
    self.lastUsedTime = os.time() * 1000
end

function Skill:resetCooldown()
    self.lastUsedTime = 0
end

function Skill:isMaxLevel()
    return self.level >= self.levels:size()
end

function Skill:getType()
    return self.type or -1
end

function Skill:getMaxTarget()
    return self.levelData and self.levelData.targetCount or 0
end

function Skill:isPhysicalSkill(skillId)
    return Skill.PHYSICAL_SKILLS[skillId] == true
end

function Skill:isBuffSkill()
    return self.type == 1 or self.type == 2
end

function Skill:getDamageType()
    if self:isPhysicalSkill(self.id) then
        return ClassIds.TYPE.PHYSICAL
    end

    if self.role == 0 then
        return ClassIds.ELEMENT.FIRE
    elseif self.role == 1 then
        return ClassIds.ELEMENT.POISON
    elseif self.role == 2 then
        return ClassIds.ELEMENT.ICE
    elseif self.role == 3 then
        return ClassIds.ELEMENT.LIGHTING
    end
end

function Skill:canLearn(level, playerLevel)
    if level <= 0 or level > self.levels:size() then
        return false
    end

    local skillLevel = self.levels:get(level - 1)
    return skillLevel ~= nil and playerLevel >= skillLevel.requiredLevel
end

return Skill

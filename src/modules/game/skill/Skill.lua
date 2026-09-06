local Skill = class("Skill")

Skill.PHYSICAL_SKILLS = {
    [0] = true,
    [1] = true,
    [3] = true,
    [5] = true,
    [7] = true,
    [19] = true
}

function Skill:ctor(skillId, currentLevel, role)
    self.skillId = skillId
    self.currentLevel = currentLevel
    self.lastUsedTime = 0
    self.role = role
    self.skillData = nil
end

function Skill:getCurrentLevelData()
    local skill = self:getSkillData()
    return skill and skill:getLevel(self.currentLevel - 1) or nil
end

function Skill:getSkillData()
    if not self.skillData then
        self.skillData = GameData.getSkill(self.role, self.skillId)
    end
    return self.skillData
end

function Skill:upgrade(playerLevel, value)
    local skill = self:getSkillData()
    if not skill then return false end

    local maxLevel = #skill.levels
    local targetLevel = math.min(self.currentLevel + value, maxLevel)
    local newLevel = self.currentLevel

    for lv = self.currentLevel + 1, targetLevel do
        if not skill:canLearn(lv, playerLevel) then
            break
        end
        newLevel = lv
    end

    if newLevel == self.currentLevel then
        return false
    end

    self.currentLevel = newLevel
    return true
end

function Skill:canUpgrade(playerLevel, value)
    local skill = self:getSkillData()
    if not skill then return false end

    local maxLevel = #skill.levels
    local targetLevel = math.min(self.currentLevel + value, maxLevel)

    for lv = self.currentLevel + 1, targetLevel do
        if not skill:canLearn(lv, playerLevel) then
            return false
        end
    end

    return true
end

function Skill:isOnCooldown()
    local levelData = self:getCurrentLevelData()
    if not levelData then
        return true
    end

    if self.lastUsedTime == 0 then
        return false
    end

    local elapsedTime = os.time() * 1000 - self.lastUsedTime
    local adjustedCooldown = math.max(0, levelData.cooldown - 1000)

    return elapsedTime < adjustedCooldown
end

function Skill:getRemainingCooldown()
    if not self:isOnCooldown() then
        return 0
    end

    local levelData = self:getCurrentLevelData()
    if not levelData then
        return 0
    end

    local elapsedTime = os.time() * 1000 - self.lastUsedTime
    local adjustedCooldown = math.max(0, levelData.cooldown - 1000)

    return math.max(0, adjustedCooldown - elapsedTime)
end

function Skill:onUse()
    self.lastUsedTime = os.time() * 1000
end

function Skill:resetCooldown()
    self.lastUsedTime = 0
end

function Skill:isMaxLevel()
    local skill = self:getSkillData()
    return skill and self.currentLevel >= #skill.levels or false
end

function Skill:getType()
    local skill = self:getSkillData()
    return skill and skill.type or -1
end

function Skill:getTargetCount()
    local levelData = self:getCurrentLevelData()
    return levelData and levelData.targetCount or 0
end

function Skill:isPhysicalSkill(skillId)
    return Skill.PHYSICAL_SKILLS[skillId] == true
end

function Skill:isBuffSkill()
    local skill = self:getSkillData()
    if not skill then return false end

    return skill.type == 1 or skill.type == 2
end

function Skill:createBuff()
    local lvData = self:getCurrentLevelData()
    local skill = self:getSkillData()

    if not lvData or not skill then
        return nil
    end

    if lvData.buffDuration <= 0 then
        return nil
    end

    local buff = BuffEffect.new(
        self.skillId,
        skill.iconId,
        skill.buffType,
        lvData.buffDuration
    )

    if lvData.options then
        for _, option in ipairs(lvData.options) do
            if option then
                local statType = StatType.fromValue(option.id)

                if statType then
                    buff:addStatModifier(statType, option.value)
                end
            end
        end
    end

    return buff
end

function Skill:getDamageType()
    if self:isPhysicalSkill(self.skillId) then
        return DamageType.PHYSICAL
    end

    if self.role == 0 then
        return DamageType.FIRE
    elseif self.role == 1 then
        return DamageType.POISON
    elseif self.role == 2 then
        return DamageType.ICE
    elseif self.role == 3 then
        return DamageType.LIGHTING
    end

    error("Unexpected role: " .. tostring(self.role))
end

return Skill

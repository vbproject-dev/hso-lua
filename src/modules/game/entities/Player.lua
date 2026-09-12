local BaseObject        = require("modules.game.entities.BaseObject")
local Equipment         = require("modules.game.items.Equipment")
local Inventory         = require("modules.game.inventory.Inventory")
local EquipType         = require("modules.game.items.EquipType")
local CommonWritter     = require("modules.writters.CommonWritter")
local GameData          = require("database.GameData")
local Skill             = require("modules.game.skill.Skill")
local StatManager       = require("modules.game.stats.StatManager")
local StatIds           = require("modules.game.stats.StatIds")
local AttributeFormulas = require("modules.game.stats.AttributeFormulas")
local StatDefs          = require("modules.game.stats.StatDefs")
local ObjectType        = require("modules.game.entities.ObjectType")
local Combat            = require("modules.game.combat.Combat")

local Player            = class("Player", BaseObject)

function Player:ctor(data)
    Player.super.ctor(self, data)
    self.type = ObjectType.PLAYER
    self.id = data.id or 0
    self.accountId = data.account_id or 0
    self.class = data.class or 0
    self.level = data.level or 1
    self.exp = data.exp or 0
    self.gold = data.gold or 0
    self.gem = data.gem or 0
    self.part = data.part or {}
    self.rms = data.rms or { {}, {} }
    self.strength = data.strength or 5
    self.dexterity = data.dexterity or 5
    self.vitality = data.vitality or 5
    self.intelligence = data.intelligence or 5

    self.stats = StatManager.new(self.class)
    self.stats:setDerivedFormula(function(class, flatSums, percentSums)
        return AttributeFormulas.compute(class, flatSums, percentSums)
    end)

    self.potentialPoints = data.potential_points or 0
    self.skillPoints = data.skill_points or 0
    self.typePK = -1
    self.pointPK = 0
    self.pointArena = 0
    self.stamina = 32000

    self.fashion = ArrayList.new(data.fashion or { -1, -1, -1, -1, -1, -1, -1 })

    self.wearing = ArrayList.new()
    for i = 0, 23 do
        self.wearing:add(nil)
    end

    for _, itemData in pairs(data.wearing or {}) do
        local item = Equipment.create(itemData)
        if item then
            local slot = EquipType.getAvailableSlot(item.info.type, self.wearing)
            if slot then
                self.wearing:set(slot, item)
            end
        end
    end


    self.inventory = Inventory.new(data.inventory or {})
    self.bank = Inventory.new(data.bank or {})

    local skillLevelData = data.skill or {}
    self.skills = ArrayList.new()
    local skillsData = GameData.getSkills(self.class)
    skillsData:forEachIndexed(function(index, skillData)
        local level = skillLevelData[index + 1]
        self.skills:add(Skill.new(level, skillData))
    end)

    -- Game States
    self.hp = 0
    self.maxHp = 0
    self.mp = 0
    self.maxMp = 0
    self.bonusAtkSkill = 0
    self.bonusBuffSkill = 0
    self.online = false
    self.session = nil

    -- Game States
    self.lastWarpTime = 0
    self.shop = nil
    self.menu = nil
    self:recalculateStats()
end

function Player:setSession(session)
    self.session = session
end

function Player:getSession()
    return self.session
end

function Player:wear(item, slot)
    if slot and not EquipType.isValid(slot, item.info.type) then
        return CommonWritter.noticeBox(self.session, "Invalid equipment slot")
    end

    slot = slot or EquipType.getSlot(item.info.type)
    if not slot then
        return CommonWritter.noticeBox(self.session, "Invalid equipment type")
    end

    if item.info.role ~= 5 and item.info.role ~= self.class then
        return CommonWritter.noticeBox(self.session, "Invalid class")
    end

    local old = self.wearing:get(slot)

    if old and self.inventory:isFull() then
        return CommonWritter.noticeBox(self.session, "Inventory is full")
    end

    self.inventory:remove(item)
    if old then self.inventory:add(old) end
    self.wearing:set(slot, item)
    self:recalculateStats()
    return true
end

function Player:unwear(slot)
    local item = self.wearing:get(slot)
    if not item then return nil end

    self.wearing:set(slot, nil)
    self:recalculateStats()
    return item
end

function Player:getWearing(slot)
    return self.wearing:get(slot)
end

function Player:isSlotEmpty(slot)
    return not self.wearing:get(slot)
end

function Player:useMoney(moneyType, amount)
    amount = amount or 0

    if amount <= 0 then
        return false
    end

    if moneyType == 0 then
        if self.gold < amount then
            return false
        end

        self.gold = self.gold - amount
        return true
    elseif moneyType == 1 then
        if self.gem < amount then
            return false
        end

        self.gem = self.gem - amount
        return true
    end

    return false
end

function Player:addMoney(moneyType, amount)
    amount = amount or 0

    if amount <= 0 then
        return false
    end

    if moneyType == 0 then
        self.gold = self.gold + amount
        return true
    elseif moneyType == 1 then
        self.gem = self.gem + amount
        return true
    end

    return false
end

function Player:send(packet)
    if self.session then
        self.session:send(packet)
    end
end

function Player:wearingData()
    local packet = Packet.new()
    packet:writeShort(self.id)
    packet:writeByte(self.wearing:size())
    self.wearing:forEachIndexed(function(index, item)
        if not item then
            packet:writeByte(-1)
        else
            packet:writeByte(index)
            packet:writeUTF(item.info.name)
            packet:writeByte(item.info.role)
            packet:writeByte(item.info.type)
            packet:writeShort(item.info.icon)
            packet:writeByte(item.info.part)
            packet:writeByte(item.plus)
            packet:writeShort(item.info.level)
            packet:writeByte(item.color)

            packet:writeByte(item.options:size())
            item.options:forEach(function(op)
                packet:writeByte(op.id)
                packet:writeInt(op.value)
            end)

            -- lock
            packet:writeByte(1)
        end
    end)

    -- Pet
    packet:writeByte(-1)

    packet:writeByte(self.fashion:size())
    self.fashion:forEach(function(id)
        packet:writeShort(id)
    end)
    return packet:getData()
end

function Player:resetAttributes()
    self.strength = 4
    self.dexterity = 4
    self.vitality = 4
    self.intelligence = 4
    self.potentialPoints = (self.level - 1) * 4
    self:recalculateStats()
end

function Player:resetSkills()
    self.skills:forEach(function(skill)
        skill.level = skill.id == 0 and 1 or 0
    end)

    self.skillPoints = self.level
    self:recalculateStats()

    return true
end

function Player:recalculateStats()
    self.stats.attributes:reset()
    self.stats.equipment:reset()
    self.stats.skills:reset()

    self.stats.attributes:set(StatIds.STRENGTH, self.strength)
    self.stats.attributes:set(StatIds.DEXTERITY, self.dexterity)
    self.stats.attributes:set(StatIds.VITALITY, self.vitality)
    self.stats.attributes:set(StatIds.INTELLIGENCE, self.intelligence)

    self.wearing:forEach(function(item)
        if item then
            item.options:forEach(function(opt)
                self.stats.equipment:add(opt.id, opt.value)
            end)
        end
    end)


    local pasiveSkills = self.skills:filter(function(skill) return skill.type == 2 and skill.level > 0 end) -- Collect pasive skills
    pasiveSkills:forEach(function(skill)
        local levelData = skill.levelData
        if levelData then
            for __, data in ipairs(levelData.options) do
                self.stats.skills:add(data.id, data.value)
            end
        end
    end)

    local final = self.stats:calculate()

    self.maxHp = final:get(StatIds.HP) or 0
    self.maxMp = final:get(StatIds.MP) or 0
    self.hp = self.maxHp
    self.mp = self.maxMp

    self.bonusAtkSkill = final:get(StatIds.ATTACK_SKILL) or 0
    self.bonusBuffSkill = final:get(StatIds.DEFEND_SKILL) or 0
    self.skills:forEach(function(skill)
        skill:applyBonusLevel(skill:isBuffSkill() and self.bonusBuffSkill or self.bonusAtkSkill)
    end)
end

function Player:useSkill(skill, target)
    if not skill or skill.level <= 0 then return false end
    if not target then return false end

    if skill:isOnCooldown() then return false end
    if self.mp < skill.levelData.mpCost then return false end

    self.mp = math.max(0, self.mp - skill.levelData.mpCost)

    Combat.dealDamageTo(self, target, skill)
    skill:onUse()
end

function Player:toTable()
    return {
        class = self.class,
        level = self.level,
        exp = self.exp,
        gold = self.gold,
        gem = self.gem,
        strength = self.strength,
        dexterity = self.dexterity,
        vitality = self.vitality,
        intelligence = self.intelligence,
        potential_points = self.potentialPoints,
        skill_points = self.skillPoints,
        skill = JSON.fromTable(self.skills:map(function(skill) return skill.level end):toTable()),
        location = JSON.fromTable({
            x = self.x,
            y = self.y,
            map = self.mapId
        }),
        part = JSON.fromTable(self.part),
        rms = JSON.fromTable(self.rms),

        -- Filter only non null value
        wearing = JSON.fromTable(self.wearing:filter(function(item)
            return item ~= nil
        end):toTable(function(item)
            return item:toWearingTable()
        end)),

        inventory = self.inventory:toJson(),
        bank = self.bank:toJson()
    }
end

return Player

local BaseObject        = require("modules.game.entities.BaseObject")
local GameData          = require("database.GameData")
local ObjectType        = require("modules.game.entities.ObjectType")
local StatManager       = require("modules.game.stats.StatManager")
local AttributeFormulas = require("modules.game.stats.AttributeFormulas")
local StatIds           = require("modules.game.stats.StatIds")
local Monster           = class("Monster", BaseObject)

function Monster:ctor(data)
    Monster.super.ctor(self, data)
    self.type = ObjectType.MONSTER
    self.template = GameData.getMonster(data.tempId)
    self.x = data.x
    self.y = data.y

    self.level = self.template.level
    self.hp = self.template.hp
    self.maxHp = self.template.hp
    self.color = 0       -- 1: blue, 2: yellow
    self.refreshTime = 3 -- 3 sec

    self.target = nil
    self.attackTime = 3 -- attacking delay in seconds

    self.stats = StatManager.new(4)
    self.stats:setDerivedFormula(function(class, flatSums)
        return AttributeFormulas.compute(class, flatSums)
    end)

    self:recalculateStats()
end

function Monster:recalculateStats()
    self.stats.attributes:reset()

    self.stats.attributes:set(StatIds.STRENGTH, self.level * 2)
    self.stats.attributes:set(StatIds.DEXTERITY, self.level * 2)
    self.stats.attributes:set(StatIds.VITALITY, self.level * 2)
    self.stats.attributes:set(StatIds.INTELLIGENCE, self.level * 2)


    self.maxHp = self.stats:get(StatIds.HP) or 0
    self.maxMp = self.stats:get(StatIds.MP) or 0
    self.hp = self.maxHp
    self.mp = self.maxMp
end

function Monster:update(dt)
    if self:isDead() then
        self.refreshTime = self.refreshTime - dt

        if self.refreshTime <= 0 then
            self.target = nil
            self.hp = self.maxHp
            self.mp = self.maxMp
            self.refreshTime = 3
        end

        return
    end

    if self.target then
        self.attackTime = self.attackTime - dt
        if self.attackTime <= 0 then
            -- Attack target here
            self.attackTime = 3
        end
    end
end

return Monster

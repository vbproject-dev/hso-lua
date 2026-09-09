local BaseObject = require("modules.game.entities.BaseObject")
local GameData   = require("database.GameData")
local ObjectType = require("modules.game.entities.ObjectType")

local Monster    = class("Monster", BaseObject)

function Monster:ctor(data)
    Monster.super.ctor(self, data)
    self.type = ObjectType.MONSTER
    self.template = GameData.getMonster(data.tempId)
    self.x = data.x
    self.y = data.y

    self.hp = self.template.hp
    self.maxHp = self.template.hp
    self.color = 0       -- 1: blue, 2: yellow
    self.refreshTime = 3 -- 3 sec
end

return Monster

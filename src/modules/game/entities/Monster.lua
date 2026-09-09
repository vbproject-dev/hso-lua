local BaseObject = require("modules.game.entities.BaseObject")
local GameData   = require("database.GameData")

local Monster    = class("Monster", BaseObject)

function Monster:ctor(data)
    Monster.super.ctor(self, data)

    self.type = 1
    self.template = GameData.getMonster(data.tempId)
    self.x = data.x
    self.y = data.y

    self.hp = self.template.hp
    self.maxHp = self.template.hp
    self.color = 1       -- 1: blue, 2: yellow
    self.refreshTime = 3 -- 3 sec
end

return Monster

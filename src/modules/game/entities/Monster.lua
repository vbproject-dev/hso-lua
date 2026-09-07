local BaseObject = require("modules.game.entities.BaseObject")
local GameData   = require("database.GameData")

local Monster    = class("Monster", BaseObject)

function Monster:ctor(data)
    Monster.super.ctor(self, data)

    self.type = 1
    self.template = GameData.getMonster(data.tempId)
    self.x = data.x
    self.y = data.y
end

return Monster

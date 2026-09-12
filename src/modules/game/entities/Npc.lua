local BaseObject = require("modules.game.entities.BaseObject")
local GameData   = require("database.GameData")
local ObjectType = require("modules.game.entities.ObjectType")
local Npc        = class("Npc", BaseObject)

function Npc:ctor(data)
    Npc.super.ctor(self, data)
    self.type = ObjectType.NPC

    self.template = GameData.getNpc(data.id)
    self.x = data.x
    self.y = data.y
end

function Npc:getShop(id)
    return self.shops:findFirst(function(shop) return shop.id == id end)
end

return Npc

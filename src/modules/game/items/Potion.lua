local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local Potion = class("Potion", Item)

function Potion:ctor(data)
    Potion.super.ctor(self, data)
    self.category = 4
    self.quantity = math.min(self.quantity, 3200)
    self.info = GameData.getPotionn(self.id)
end

function Potion:toTable()
    return {
        id = self.id,
        quantity = self.quantity,
        category = self.category
    }
end

return Potion

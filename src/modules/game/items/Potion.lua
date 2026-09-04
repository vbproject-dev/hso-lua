local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local Potion = class("Potion", Item)

function Potion:ctor(data)
    Potion.super.ctor(self, data)
    self.category = 4
    self.info = GameData.getPotionn(self.id)
end

return Potion

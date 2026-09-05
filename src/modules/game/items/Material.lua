local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local Material = class("Material", Item)

function Material:ctor(data)
    Material.super.ctor(self, data)
    self.category = 7
    self.quantity = math.min(self.quantity, 3200)
    self.info = GameData.getMaterial(self.id)
end

function Material:toTable()
    return {
        id = self.id,
        quantity = self.quantity,
        category = self.category
    }
end

return Material

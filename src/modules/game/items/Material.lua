local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local Material = class("Material", Item)

function Material:ctor(data)
    Material.super.ctor(self, data)
    self.category = 7
    self.info = GameData.getMaterial(self.id)
end

return Material

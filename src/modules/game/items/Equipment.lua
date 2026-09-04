local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local Equipment = class("Equipment", Item)

function Equipment:ctor(data)
    Equipment.super.ctor(self, data)
    self.category = 3
    self.info = GameData.getEquipment(self.id)
    self.options = data.options or ArrayList.new(self.info.option)
    self.plus = data.plus or 0
    self.color = data.color or self.info.color
end

function Equipment:toWearingTable()
    return {
        id = self.id,
        plus = self.plus,
        color = self.color,
        options = self.options:toTable()
    }
end

function Equipment:toInventoryTable()
    return {
        category = self.category,
        id = self.id,
        quantity = self.quantity,
        plus = self.plus,
        color = self.color,
        options = self.options:toTable()
    }
end

return Equipment

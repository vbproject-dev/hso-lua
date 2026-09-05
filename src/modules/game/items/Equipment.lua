local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local Equipment = class("Equipment", Item)

function Equipment:ctor(data)
    Equipment.super.ctor(self, data)
    self.category = 3
    self.info = GameData.getEquipment(self.id)
    self.options = data.options or ArrayList.new(self.info.option)
    self.plus = data.plus or 0
    self.slot = data.slot
    self.color = data.color or self.info.color
    self.lock = data.lock or false
    self.expired = data.expired or -1
end

function Equipment:toWearingTable()
    return {
        id = self.id,
        plus = self.plus,
        color = self.color,
        lock = self.lock,
        slot = self.slot,
        expired = self.expired,
        options = self.options:toTable()
    }
end

function Equipment:toInventoryTable()
    return {
        category = self.category,
        id = self.id,
        quantity = self.quantity,
        plus = self.plus,
        lock = self.lock,
        color = self.color,
        expired = self.expired,
        options = self.options:toTable()
    }
end

return Equipment

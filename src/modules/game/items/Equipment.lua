local Item = require("modules.game.items.Item")
local GameData = require("database.GameData")
local EquipType = require("modules.game.items.EquipType")
local Equipment = class("Equipment", Item)

function Equipment:ctor(data)
    Equipment.super.ctor(self, data)
    self.category = 3
    self.info = GameData.getEquipment(self.id)
    self.options = ArrayList.new(data.options or self.info.option)
    self.plus = data.plus or 0
    self.color = data.color or self.info.color
    self.lock = data.lock or false
    self.expired = data.expired or 0
end

function Equipment.create(data)
    local info = GameData.getEquipment(data.id)
    if not info then return nil end
    return Equipment.new(data, info)
end

function Equipment:toWearingTable()
    return {
        id = self.id,
        plus = self.plus,
        color = self.color,
        lock = self.lock,
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

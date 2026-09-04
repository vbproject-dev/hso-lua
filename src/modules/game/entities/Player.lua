local BaseObject = require("modules.game.entities.BaseObject")
local Equipment = require("modules.game.items.Equipment")

local Player = class("Player", BaseObject)

function Player:ctor(data)
    Player.super.ctor(self, data)
    self.accountId = data.account_id or 0
    self.class = data.class or 0
    self.level = data.level or 1
    self.exp = data.exp or 0
    self.gold = data.gold or 0
    self.gem = data.gem or 0
    self.info = data.info or {}

    self.wearing = ArrayList.new()
    for _, item in ipairs(data.wearing or {}) do
        self.wearing:add(Equipment.new(item))
    end
    self.inventory = ArrayList.new()
    self.bank = ArrayList.new()
end

function Player:toTable()
    return {
        class = self.class,
        level = self.level,
        exp = self.exp,
        gold = self.gold,
        gem = self.gem,
        info = self.info,
        wearing = self.wearing:toTable(function(item) return item:toTable() end),
        inventory = self.inventory:toTable(function(item) return item:toTable() end),
        bank = self.bank:toTable(function(item) return item:toTable() end),
    }
end

return Player

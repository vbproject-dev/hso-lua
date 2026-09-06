local Equipment = require "modules.game.items.Equipment"
local Potion    = require "modules.game.items.Potion"
local Material  = require "modules.game.items.Material"
local Item      = require "modules.game.items.Item"
local Inventory = class("Inventory")

function Inventory:ctor(data, capacity)
    self.data = ArrayList.new()
    for __, item in ipairs(data or {}) do
        self.data:add(self:createItem(item))
    end

    self.maxSize = capacity or 126
end

function Inventory:createItem(data)
    if data.category == 3 then
        return Equipment.new(data)
    elseif data.category == 4 then
        return Potion.new(data)
    elseif data.category == 7 then
        return Material.new(data)
    end

    return Item.new(data)
end

function Inventory:size()
    return self.data:size()
end

function Inventory:isEmpty()
    return self.data:size() == 0
end

function Inventory:isFull()
    return self.maxSize > 0 and self.data:size() >= self.maxSize
end

function Inventory:add(item)
    if not item then return false end

    if item.category == 4 or item.category == 7 then
        local existing = self:findById(item.id)
        if existing then
            existing.quantity = math.min(existing.quantity + item.quantity, 3200)
            return true
        end
    end

    if self:isFull() then return false end

    self.data:add(item)
    return true
end

function Inventory:remove(item, quantity)
    if not item then return false end

    local existing = self:findById(item.id)
    if not existing then return false end

    if existing.category == 4 or existing.category == 7 then
        existing.quantity = existing.quantity - (quantity or 1)
        if existing.quantity <= 0 then
            self.data:remove(existing)
        end
        return true
    end

    return self.data:remove(existing)
end

function Inventory:get(index)
    return self.data:get(index)
end

function Inventory:find(predicate)
    return self.data:findFirst(predicate)
end

function Inventory:findById(id)
    return self.data:findFirst(function(item)
        return item.id == id
    end)
end

function Inventory:findByCategory(category)
    return self.data:filter(function(item)
        return item.category == category
    end)
end

function Inventory:contains(item)
    return self.data:contains(item)
end

function Inventory:clear()
    self.data:clear()
end

function Inventory:forEach(callback)
    self.data:forEach(callback)
end

function Inventory:getRemainingSlot()
    return math.max(0, self.maxSize - self.data:size())
end

function Inventory:toTable()
    return self.data:toTable(function(item)
        if item.category == 3 then
            return item:toInventoryTable()
        end
        return item:toTable()
    end)
end

function Inventory:all()
    return self.data
end

return Inventory

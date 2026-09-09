local Equipment = require "modules.game.items.Equipment"
local Potion    = require "modules.game.items.Potion"
local Material  = require "modules.game.items.Material"
local Inventory = class("Inventory")

function Inventory:ctor(data, capacity)
    self.maxSize = capacity or 126
    self.data = ArrayList.new()
    for __, item in ipairs(data or {}) do
        self.data:add(self:createItem(item))
    end
end

function Inventory:createItem(data)
    local item
    if data.category == 3 then
        item = Equipment.new(data)
    elseif data.category == 4 then
        item = Potion.new(data)
    elseif data.category == 7 then
        item = Material.new(data)
    end

    return item
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
        local existing = self:findById(item.id, item.category)
        if existing then
            existing.quantity = math.min(existing.quantity + item.quantity, 3200)
            return true
        end
    end

    if self:isFull() then return false end

    self.data:add(item)
    return true
end

function Inventory:addFrom(id, category, quantity)
    local item

    if category == 4 then
        item = Potion.new({ id = id, quantity = quantity or 1 })
    elseif category == 7 then
        item = Material.new({ id = id, quantity = quantity or 1 })
    else
        item = Equipment.new({ id = id })
    end

    return self:add(item)
end

function Inventory:remove(item, quantity)
    if not item then return false end

    local existing = self:findById(item.id, item.category)
    if not existing then return false end

    if existing.category == 4 or existing.category == 7 then
        existing.quantity = existing.quantity - (quantity or item.quantity) -- Remove completly if no given quantity
        if existing.quantity <= 0 then
            self.data:remove(existing)
        end
        return true
    end

    return self.data:remove(existing)
end

function Inventory:get(index, category)
    local current = 0

    return self.data:findFirst(function(item)
        if item.category ~= category then
            return false
        end

        if current == index then
            return true
        end

        current = current + 1
        return false
    end)
end

function Inventory:find(predicate)
    return self.data:findFirst(predicate)
end

function Inventory:findById(id, category)
    return self.data:findFirst(function(item)
        return item.id == id and item.category == category
    end)
end

function Inventory:findByCategory(category)
    return self.data:filter(function(item)
        return item.category == category
    end)
end

function Inventory:forEachCategory(category, callback)
    local index = 0

    self.data:forEach(function(item)
        if item.category == category then
            callback(index, item)
            index = index + 1
        end
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
        if iskindof(item, "Equipment") then
            return item:toInventoryTable()
        else
            return item:toTable()
        end
    end)
end

function Inventory:toJson()
    return JSON.fromTable(self:toTable())
end

function Inventory:all()
    return self.data
end

return Inventory

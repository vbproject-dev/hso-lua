local Item = require("modules.game.items.Item")
local Equipment = require("modules.game.items.Equipment")
local Material = require("modules.game.items.Material")
local Potion = require("modules.game.items.Potion")

local InventoryManager = {}

function InventoryManager.createItem(data)
    if data.category == 3 then
        return Equipment.new(data)
    elseif data.category == 4 then
        return Potion.new(data)
    elseif data.category == 7 then
        return Material.new(data)
    end

    return Item.new(data)
end

-- function InventoryManager.createItem(id, quantity, category)
--     if category == 3 then
--         return Equipment.new(data)
--     elseif category == 4 then
--         return Potion.new(data)
--     elseif category == 7 then
--         return Material.new(data)
--     end

--     return Item.new(data)
-- end

function InventoryManager.load(inventory, data)
    for _, itemData in ipairs(data or {}) do
        inventory:add(InventoryManager.createItem(itemData))
    end
end

return InventoryManager

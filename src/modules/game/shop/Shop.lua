local Shop = class("Shop")
function Shop:ctor(data)
    self.id = data.id
    self.name = data.name
    self.category = data.category
    self.items = ArrayList.new()

    local GameData = require "database.GameData"
    for __, item in ipairs(data.items or {}) do
        local itemData = GameData.getItem(item.itemId, data.category)
        if itemData then
            local shop = {
                id = item.itemId,
                price = item.price or itemData.price,
                priceType = item.priceType or itemData.price_type,
                duration = item.duration or 0,
            }

            self.items:add(shop)
        end
    end
end

return Shop

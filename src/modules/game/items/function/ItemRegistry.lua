local PotionHandler = require("modules.game.items.function.PotionHandler")
local MaterialHandler = require("modules.game.items.function.MaterialHandler")

local ItemRegistry = {
    [4] = PotionHandler,
    [7] = MaterialHandler
}

function ItemRegistry.get(itemId, category)
    local handler = ItemRegistry[category]

    if not handler then
        return nil
    end

    return handler[itemId]
end

return ItemRegistry

local CommonWritter = require "modules.writters.CommonWritter"
local GameWritter   = require "modules.writters.GameWritter"
local Shop          = require("modules.game.shop.Shop")
local GameData      = require("database.GameData")

local ShopService   = {}

function ShopService.openShop(player, id)
    local shopData = GameData.getShop(id)
    if not shopData then
        CommonWritter.noticeBox(player.session, "Shop not found")
        return
    end
    player.shop = Shop.new(shopData)
    GameWritter.openShop(player)
end

function ShopService.buyItem(player, request)
    local type = request.type
    local id = request.id
    local quantity = request.quantity or 1
    local category = player.shop.category
    local item = player.shop.items:findFirst(function(item)
        return item.id == id
    end)


    if not item then
        CommonWritter.noticeBox(player.session, "Item not found")
        return
    end

    local price = item.price * quantity
    if player:useMoney(item.priceType, price) then
        player.inventory:addFrom(item.id, category, quantity)
        GameWritter.updateInventory(player)
        CommonWritter.noticeBox(player.session, "Purchase completed")
        return
    end

    CommonWritter.noticeBox(player.session, "Not enough money")
end

return ShopService

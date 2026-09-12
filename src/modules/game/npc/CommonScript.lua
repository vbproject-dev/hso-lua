local ShopService = require("modules.game.shop.ShopService")

return {
    onTalk = function(player, zone, npcId)
        log("CommonScript onTalk: " .. player.id .. ", " .. zone.id .. ", " .. npcId)

        if npcId == -74 or npcId == -3 then
            ShopService.openShop(player, 0)
        end
    end
}

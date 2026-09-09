return {
    onTalk = function(player, zone, npcId)
        local GameData    = require "database.GameData"
        local ShopService = require "modules.game.service.ShopService"

        local shop        = GameData.getShop(npcId)

        if shop then
            ShopService.openShop(player, shop)
        end
    end
}

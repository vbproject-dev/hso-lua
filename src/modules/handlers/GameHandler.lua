local Cmd           = require "network.Cmd"
local GameWritter   = require "modules.writters.GameWritter"
local GameWorld     = require "modules.game.world.GameWorld"
local CommonWritter = require "modules.writters.CommonWritter"
local HandlerGuard  = require "modules.handlers.HandlerGuard"
local GameHandler   = {}


function GameHandler.onUseItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local item = player.inventory:get(request.index, 3)

        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        if player:wear(item, request.slot) then
            GameWritter.updateInventory(player)
            zone:broadcast(Packet.new(Cmd.CHAR_WEARING, player:wearingData()))
        end
    end)
end

function GameHandler.onMove(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        player:setPosition(request.x, request.y)

        local warp = zone.map:getWarpAt(request.x, request.y)
        if warp then
            local now = os.time()
            if now >= (player.lastWarpTime or 0) then
                player.lastWarpTime = now + 2
                player:setPosition(warp.toX, warp.toY)
                GameWorld.instance():joinMap(player, warp.toMap)
            end
            return
        end

        zone:forEachPlayer(function(other)
            GameWritter.objectMove(other, player)
        end, player)
    end)
end

function GameHandler.onDeleteItem(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local item = player.inventory:get(request.itemId, request.category)
        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        if request.action == 1 then
            -- sell item
            local GameData  = require "database.GameData"
            local cfg       = GameData.getSetting("config")
            local priceSell = (request.category == 4 or request.category == 7) and
                (cfg.price_sell_potion * item.quantity) or
                (cfg.price_sell_item * item.quantity)
            player:addMoney(0, priceSell)
        end

        if not player.inventory:remove(item) then
            CommonWritter.noticeBox(session, "Failed to delete item")
            return
        end

        GameWritter.updateInventory(player)
    end)
end

function GameHandler.onMonsterInfo(session, request)
    return HandlerGuard.withZone(session, function(player, zone)
        local monster = zone:getObject(1, request.id)
        if not monster then
            return
        end

        GameWritter.monsterInfo(player, monster)
    end)
end

return {
    [Cmd.OBJECT_MOVE] = GameHandler.onMove,
    [Cmd.USE_ITEM] = GameHandler.onUseItem,
    [Cmd.DELETE_ITEM] = GameHandler.onDeleteItem,
    [Cmd.MONSTER_INFO] = GameHandler.onMonsterInfo,
}

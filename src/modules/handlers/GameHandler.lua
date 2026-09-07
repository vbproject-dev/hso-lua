local Cmd           = require "network.Cmd"
local GameWritter   = require "modules.writters.GameWritter"
local GameWorld     = require "modules.game.world.GameWorld"
local CommonWritter = require "modules.writters.CommonWritter"
local GameHandler   = {}

local function withZone(session, callback)
    local player = session:get("player")
    if not player or not player:getZone() then
        return false
    end

    local zone = player:getZone()
    return try(function()
        callback(player, zone)
    end)
end

function GameHandler.onUseItem(session, request)
    log("onUseItem index %d slot %d", request.index, request.slot)
    return withZone(session, function(player, zone)
        local item = player.inventory:get(request.index)

        log("Item type %d", item.type)
        if not item then
            CommonWritter.noticeBox(session, "Item not found")
            return
        end

        if player:wear(item, request.slot) then
            zone:broadcast(Packet.new(Cmd.CHAR_WEARING, player:wearingData()))
        end
    end)
end

function GameHandler.onMove(session, request)
    return withZone(session, function(player, zone)
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

return {
    [Cmd.OBJECT_MOVE] = GameHandler.onMove,
    [Cmd.USE_ITEM] = GameHandler.onUseItem,
}

local Cmd = require "network.Cmd"
local WorldWritter = {}

local function withPlayer(session, callback)
    local player = session:get("player")
    if not player then return end

    local zone = player:getZone()
    if not zone then return end

    return try(function()
        return callback(player, zone)
    end)
end


return WorldWritter

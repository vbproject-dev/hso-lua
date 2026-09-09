local HandlerGuard = {}
function HandlerGuard.withZone(session, callback)
    local player = session:get("player")
    if not player or not player:getZone() then
        return false
    end

    local zone = player:getZone()
    return try(function()
        callback(player, zone)
    end)
end

function HandlerGuard.withPlayer(session, callback)
    local player = session:get("player")
    if not player or not player:getZone() then
        return false
    end
    return try(function()
        callback(player)
    end)
end

return HandlerGuard

local ModuleRegistry = require("core.ModuleRegistry")

local NpcRegistry = {
    handlers = {}
}

function NpcRegistry.load(npcId, scriptName)
    local success, handler = xpcall(function()
        return ModuleRegistry.get(scriptName)
    end, debug.traceback)

    if not success then
        log("[NpcRegistry] Failed to load NPC %d script '%s':\n%s", npcId, scriptName, handler)
        return false
    end

    if type(handler) ~= "table" then
        log("[NpcRegistry] Invalid NPC handler for %d: %s", npcId, scriptName)
        return false
    end

    NpcRegistry.handlers[npcId] = handler

    return true
end

function NpcRegistry.get(npcId)
    return NpcRegistry.handlers[npcId]
end

function NpcRegistry.has(npcId)
    return NpcRegistry.handlers[npcId] ~= nil
end

function NpcRegistry.clear()
    NpcRegistry.handlers = {}
end

return NpcRegistry

local ModuleRegistry = require("core.ModuleRegistry")

local NpcScriptRegistry = {
    handlers = {},
    common = nil,
}

function NpcScriptRegistry.load(npcId, scriptName)
    local success, handler = xpcall(function()
        return ModuleRegistry.get(scriptName)
    end, debug.traceback)

    if not success then
        log("[NpcScriptRegistry] Failed to load NPC %d script '%s':\n%s", npcId, scriptName, handler)
        return false
    end

    if type(handler) ~= "table" then
        log("[NpcScriptRegistry] Invalid NPC handler for %d: %s", npcId, scriptName)
        return false
    end

    NpcScriptRegistry.handlers[npcId] = handler

    return true
end

function NpcScriptRegistry.loadCommon(scriptName)
    local success, handler = xpcall(function()
        return ModuleRegistry.get(scriptName)
    end, debug.traceback)

    if not success then
        log("[NpcScriptRegistry] Failed to load common script '%s':\n%s", scriptName, handler)
        return false
    end

    NpcScriptRegistry.common = handler
    return true
end

function NpcScriptRegistry.get(npcId)
    return NpcScriptRegistry.handlers[npcId] or NpcScriptRegistry.common
end

function NpcScriptRegistry.has(npcId)
    return NpcScriptRegistry.handlers[npcId] ~= nil
end

function NpcScriptRegistry.clear()
    NpcScriptRegistry.handlers = {}
end

return NpcScriptRegistry

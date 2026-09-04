local HandlerRegistry = {
    common = {}
}

function HandlerRegistry.load(module)
    if module.common then
        for command, handler in pairs(module.common) do
            if type(handler) ~= "function" then
                error("[HandlerRegistry] Invalid common handler: " .. tostring(command))
            end

            HandlerRegistry.common[command] = handler
        end
    end
end

function HandlerRegistry.loadAll(rows)
    HandlerRegistry.clear()

    for _, row in ipairs(rows) do
        local module = require(row.module)
        HandlerRegistry.load(module)
    end
end

function HandlerRegistry.get(command)
    return HandlerRegistry.common[command]
end

function HandlerRegistry.has(command)
    return HandlerRegistry.common[command] ~= nil
end

function HandlerRegistry.clear()
    HandlerRegistry.common = {}
end

function HandlerRegistry.reload(rows)
    local previousCommon = HandlerRegistry.common

    local success, err = xpcall(function()
        for _, row in ipairs(rows) do
            package.loaded[row.module] = nil
        end

        HandlerRegistry.loadAll(rows)
    end, debug.traceback)

    if not success then
        HandlerRegistry.common = previousCommon

        log("[HandlerRegistry] Reload failed:\n%s", err)
        return false
    end

    log("[HandlerRegistry] Handlers reloaded")
    return true
end

return HandlerRegistry

local MySQL    = require "core.MySQL"

_G.loadTable   = function(tableName, where)
    local db = MySQL.instance()
    local query = db:from(tableName)

    if where then
        local field, value = next(where)
        query = query:where(field, value)
    end

    local data, err = query:getAll()

    if err then
        return false, err
    end

    local list = ArrayList.new(data)

    log("[Table] %d rows Loaded from %s", list:size(), tableName)

    return list
end

_G.updateTable = function(tableName, data, where)
    local field, value = next(where)
    local db = MySQL.instance()

    local result, err = db:from(tableName):where(field, value):update(data)

    if err then
        return false, err
    end

    return true
end

_G.findTable   = function(tableName, where)
    local field, value = next(where)
    local db = MySQL.instance()
    local data, err = db:from(tableName):where(field, value):getFirst()

    if err then
        return false, err
    end

    return data
end

_G.insertTable = function(tableName, data)
    local db = MySQL.instance()
    local result, err = db:from(tableName):insert(data)

    if err then
        return false, err
    end

    return result
end

_G.try         = function(func)
    local status, err = xpcall(func, debug.traceback)

    if not status then
        log(tostring(err))
        return false
    end

    return true
end
_G.reload      = function(name)
    local modules = {}

    for moduleName in pairs(package.loaded) do
        if moduleName == name
            or moduleName:sub(1, #name + 1) == name .. "." then
            modules[#modules + 1] = moduleName
        end
    end

    -- Unload
    for _, moduleName in ipairs(modules) do
        package.loaded[moduleName] = nil
    end

    -- Reload
    table.sort(modules)

    for _, moduleName in ipairs(modules) do
        local ok, err = pcall(require, moduleName)

        if not ok then
            return false, moduleName .. ": " .. tostring(err)
        end
    end

    return true
end

local MySQL  = require "database.MySQL"

_G.loadTable = function(tableName)
    local db = MySQL.instance()
    local data, err = db:from(tableName):getAll()

    if err then
        return false, err
    end

    local list = ArrayList.new(data)

    log("[Table] %d rows Loaded from %s", list:size(), tableName)

    return list
end

_G.try       = function(func)
    local status, err = xpcall(func, debug.traceback)

    if not status then
        log(tostring(err))
        return false
    end

    return true
end

local FileService = require "web.features.files.FileService"

local FileController = {}


function FileController:list(request)
    local path = request.query and request.query.path

    local files, err = FileService:list(path)

    if not files then
        return { error = err }
    end

    return files
end

function FileController:get(request)
    local path = request.query and request.query.path

    if not path then
        return { error = "Missing path" }
    end

    local content, err = FileService:read(path)

    if not content then
        return { error = err }
    end

    local extension = FileService:getExtension(path)

    if extension == "json" then
        local data, parseErr = JSON.toTable(content)

        if not data then
            return { error = parseErr or "Invalid JSON" }
        end

        content = data
    end

    return {
        path = path,
        content = content
    }
end

function FileController:create(request)
    local data = JSON.toTable(request.body)

    if not data or not data.path then
        return { error = "Invalid request" }
    end

    local ok, err =
        FileService:create(data.path, data.content)

    if not ok then
        return { error = err }
    end

    return { success = true }
end

function FileController:save(request)
    local data = JSON.toTable(request.body)

    if not data or not data.path then
        return { error = "Invalid request" }
    end

    local ok, err =
        FileService:save(data.path, data.content)

    if not ok then
        return { error = err }
    end

    return { success = true }
end

function FileController:delete(request)
    local path = request.query and request.query.path

    if not path then
        return { error = "Missing path" }
    end

    local ok, err =
        FileService:delete(path)

    if not ok then
        return { error = err }
    end

    return { success = true }
end

return FileController

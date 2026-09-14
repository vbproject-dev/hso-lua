local FileController = require("web.features.files.FileController")

local FileApi = {}

function FileApi:get(request)
    if request.path == "/api/files" then
        return FileController:list(request)
    end

    if request.path == "/api/file" then
        return FileController:get(request)
    end
end

function FileApi:post(request)
    if request.path == "/api/file" then
        return FileController:create(request)
    end
end

function FileApi:put(request)
    if request.path == "/api/file" then
        return FileController:save(request)
    end
end

function FileApi:delete(request)
    if request.path == "/api/file" then
        return FileController:delete(request)
    end
end

return FileApi

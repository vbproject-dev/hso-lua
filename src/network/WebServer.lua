local Config = require("core.Config")
local FileController = require("web.FileController")

local WebServer = class("WebServer")

function WebServer:ctor()
    self.server = HttpServer.new()
end

function WebServer:init()
    local config = Config.load("config.json")
    if not config then
        return false
    end

    self.server:staticFiles("/", "web")

    self.server:setHandler({
        onGet = function(request)
            return self:onGet(request)
        end,

        onPost = function(request)
            return self:onPost(request)
        end,

        onPut = function(request)
            return self:onPut(request)
        end,

        onDelete = function(request)
            return self:onDelete(request)
        end
    })

    self.server:start(config.web.port)

    return true
end

function WebServer:onGet(request)
    if request.path == "/api/files" then
        return FileController:list(request)
    end

    if request.path == "/api/file" then
        return FileController:get(request)
    end
end

function WebServer:onPost(request)
    if request.path == "/api/file" then
        return FileController:create(request)
    end
end

function WebServer:onPut(request)
    if request.path == "/api/file" then
        return FileController:save(request)
    end
end

function WebServer:onDelete(request)
    if request.path == "/api/file" then
        return FileController:delete(request)
    end
end

function WebServer:update(dt)
    self.server:pollEvents()
end

return WebServer

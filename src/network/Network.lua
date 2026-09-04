local HandlerRegistry = require("core.HandlerRegistry")
local Cmd             = require("network.Cmd")

local Network         = class("Network")

function Network:ctor(onDisconnect)
    self.onDisconnect = onDisconnect
end

function Network:start(port)
    server:setPort(port)
    server:useHso()

    server:setHandler({
        onConnect = function(session)
            log("[Network] %s connected", session:getRemoteAddress())
        end,

        onMessage = function(session, packet)
            self:handle(session, packet)
        end,

        onDisconnect = function(session)
            if self.onDisconnect then
                self.onDisconnect(session)
            end
        end,

        onError = function(session, err)
            log("[Network] error from %s reason: %s", session:getRemoteAddress(), tostring(err))
        end
    })

    server:start()
end

function Network:handle(session, packet)
    local command = packet:getCmd()
    local handler = HandlerRegistry.get(command)

    if not handler then
        log("[Network] Unknown command %s", Cmd.getName(command))
        return false
    end

    local success, err = xpcall(handler, debug.traceback, session, packet)

    if not success then
        log("[Network] Handler error\n  Command: %s\n  Remote: %s\n  Error:\n%s", Cmd.getName(command),
            tostring(session:getRemoteAddress()), err)
        return false
    end

    return true
end

return Network

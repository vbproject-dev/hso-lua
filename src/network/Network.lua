local HandlerRegistry = require("core.HandlerRegistry")
local Cmd             = require("network.Cmd")
local ModuleRegistry  = require("core.ModuleRegistry")


local MAX_PACKETS_PER_SECOND = 15
local BAN_SECONDS = 60

local Network = class("Network")

function Network:ctor(onDisconnect)
    self.onDisconnect = onDisconnect
    self.rateLimits = {}
    self.blockedIps = {}
end

function Network:start(port)
    server:setPort(port)
    server:useHso()

    server:setHandler({
        onConnect = function(session)
            local ip = session:getRemoteAddress():match("^(.-):%d+$")
            log("[Network] %s connected", ip)
        end,

        onMessage = function(session, packet)
            if not self:allowPacket(session) then
                local ip = session:getRemoteAddress():match("^(.-):%d+$")
                log("[Network] Blocking IP %s for packet flooding", ip)
                self:blockIp(ip)

                session:close()
                return
            end

            self:handle(session, packet)
        end,

        onDisconnect = function(session)
            self.rateLimits[session] = nil
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

function Network:allowPacket(session)
    local now = os.time()
    local rate = self.rateLimits[session]

    if not rate then
        rate = {
            count = 0,
            time = now
        }

        self.rateLimits[session] = rate
    end

    if now ~= rate.time then
        rate.time = now
        rate.count = 0
    end

    rate.count = rate.count + 1

    if rate.count > MAX_PACKETS_PER_SECOND then
        return false
    end

    return true
end

function Network:blockIp(ip)
    self.blockedIps[ip] = os.time() + BAN_SECONDS
end

function Network:isBlocked(ip)
    local expiresAt = self.blockedIps[ip]

    if not expiresAt then
        return false
    end

    if os.time() >= expiresAt then
        self.blockedIps[ip] = nil
        return false
    end

    return true
end

function Network:handle(session, packet)
    local command = packet:getCmd()
    local handler = HandlerRegistry.get(command)

    if not handler then
        log("[Network] Unknown command %s", Cmd.getName(command))
        return false
    end

    local PacketReader = ModuleRegistry.get("network.PacketReader")
    local reader = PacketReader[command]
    local request = reader and reader(packet) or {}

    local success, err = xpcall(handler, debug.traceback, session, request)

    if not success then
        log("[Network] Handler error\n  Command: %s\n  Remote: %s\n  Error:\n%s", Cmd.getName(command),
            tostring(session:getRemoteAddress()), err)
        return false
    end

    return true
end

return Network

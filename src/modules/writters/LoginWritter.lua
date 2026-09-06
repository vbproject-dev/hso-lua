local Cmd = require "network.Cmd"
local LoginWritter = {}

function LoginWritter.loginFail(session, text)
    return try(function()
        local packet = Packet.new(Cmd.LOGIN_FAIL)
        packet:writeUTF(text)
        packet:writeByte(0)
        session:send(packet)
    end)
end

function LoginWritter.saveLogin(session, user, pass)
    return try(function()
        local packet = Packet.new(31)
        packet:writeUTF(user)
        packet:writeUTF(pass)
        session:send(packet)
    end)
end

return LoginWritter

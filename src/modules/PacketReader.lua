local Cmd = require "network.Cmd"
local PacketReader = {}

function PacketReader.onLogin(packet)
    return {
        user = packet:readUTF(),
        pass = packet:readUTF(),
        version = packet:readUTF(),
        clinePro = packet:readUTF(),
        pro = packet:readUTF(),
        agent = packet:readUTF(),
        zoom = packet:readByte(),
        device = packet:readByte(),
        id = packet:readInt(),
        area = packet:readByte(),
        isPC = packet:readByte(),
        indexRes = packet:readByte(),
        indexInfoLogin = packet:readByte(),
        fakeByte = packet:readByte(),
        indexCharPar = packet:readShort()
    }
end

return {
    [Cmd.LOGIN] = PacketReader.onLogin
}

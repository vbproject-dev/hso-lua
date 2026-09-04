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

function PacketReader.onLoadImage(packet)
    return {
        id = packet:readShort(),
    }
end

function PacketReader.onLoadPartImage(packet)
    return {
        type = packet:readByte(),
        id = packet:readShort(),
    }
end

return {
    [Cmd.LOGIN] = PacketReader.onLogin,
    [Cmd.LOAD_IMAGE] = PacketReader.onLoadImage,
    [Cmd.LOAD_IMAGE_DATA_PART_CHAR] = PacketReader.onLoadPartImage,
}

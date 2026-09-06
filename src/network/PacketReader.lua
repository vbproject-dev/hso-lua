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

function PacketReader.onCreateChar(packet)
    return {
        class = packet:readByte(),
        name = packet:readUTF(),
        hair = packet:readByte(),
        eye = packet:readByte(),
        head = packet:readByte(),
    }
end

function PacketReader.onSelectChar(packet)
    return {
        type = packet:readByte(),
        id = packet:readInt(),
    }
end

function PacketReader.onSaveRmsServer(packet)
    local type = packet:readByte()
    local id = packet:readByte()
    local size = packet:readShort()

    return {
        type = type,
        id = id,
        size = size,
        data = size > 0 and packet:readBytes(size) or nil
    }
end

return {
    [Cmd.LOGIN] = PacketReader.onLogin,
    [Cmd.LOAD_IMAGE] = PacketReader.onLoadImage,
    [Cmd.LOAD_IMAGE_DATA_PART_CHAR] = PacketReader.onLoadPartImage,
    [Cmd.CREATE_CHAR] = PacketReader.onCreateChar,
    [Cmd.SELECT_CHAR] = PacketReader.onSelectChar,
    [Cmd.SAVE_RMS_SERVER] = PacketReader.onSaveRmsServer,
}

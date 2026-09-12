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

function PacketReader.onMove(packet)
    return {
        x = packet:readShort(),
        y = packet:readShort(),
    }
end

function PacketReader.onUseItem(packet)
    return {
        index = packet:readByte(),
        slot = packet:readByte(),
    }
end

function PacketReader.onDeleteItem(packet)
    return {
        category = packet:readByte(),
        itemId = packet:readShort(),
        action = packet:readByte(),
    }
end

function PacketReader.onAddBaseSkillPoint(packet)
    return {
        action = packet:readByte(),
        index = packet:readByte(),
        value = packet:available() > 0 and packet:readShort() or 1
    }
end

function PacketReader.onNpcInfo(packet)
    return {
        id = packet:readByte()
    }
end

function PacketReader.onMonsterInfo(packet)
    return {
        id = packet:readShort()
    }
end

function PacketReader.onBuyItem(packet)
    return {
        type = packet:readByte(),
        id = packet:readShort(),
        quantity = packet:readShort(),
    }
end

function PacketReader.onDynamicMenu(packet)
    return {
        npcId = packet:readShort(),
        menuId = packet:readByte(),
        index = packet:readByte(),
    }
end

function PacketReader.onUsePotion(packet)
    return {
        itemId = packet:readShort(),
    }
end

function PacketReader.onFireMonster(packet)
    return {
        skillId = packet:readByte(),
        type = packet:readByte(),
        targetId = packet:readShort(),
    }
end

return {
    [Cmd.LOGIN] = PacketReader.onLogin,
    [Cmd.LOAD_IMAGE] = PacketReader.onLoadImage,
    [Cmd.LOAD_IMAGE_DATA_PART_CHAR] = PacketReader.onLoadPartImage,
    [Cmd.CREATE_CHAR] = PacketReader.onCreateChar,
    [Cmd.SELECT_CHAR] = PacketReader.onSelectChar,
    [Cmd.SAVE_RMS_SERVER] = PacketReader.onSaveRmsServer,

    [Cmd.OBJECT_MOVE] = PacketReader.onMove,
    [Cmd.USE_ITEM] = PacketReader.onUseItem,
    [Cmd.DELETE_ITEM] = PacketReader.onDeleteItem,
    [Cmd.ADD_BASE_SKILL_POINT] = PacketReader.onAddBaseSkillPoint,
    [Cmd.NPC_INFO] = PacketReader.onNpcInfo,
    [Cmd.MONSTER_INFO] = PacketReader.onMonsterInfo,
    [Cmd.BUY_ITEM] = PacketReader.onBuyItem,
    [Cmd.DYNAMIC_MENU] = PacketReader.onDynamicMenu,
    [Cmd.USE_POTION] = PacketReader.onUsePotion,
    [Cmd.FIRE_MONSTER] = PacketReader.onFireMonster,
}

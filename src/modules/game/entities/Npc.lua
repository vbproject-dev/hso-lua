local BaseObject = require("modules.game.entities.BaseObject")
local GameData   = require("database.GameData")
local Npc        = class("Npc", BaseObject)

function Npc:ctor(data)
    Npc.super.ctor(self, data)
    self.type = 2

    self.template = GameData.getNpc(data.id)
    self.x = data.x
    self.y = data.y
end

function Npc:toBytes()
    local packet = Packet.new()
    packet:writeUTF(self.template.name)
    packet:writeUTF(self.template.dialog_name)
    packet:writeByte(self.template.id)
    packet:writeByte(self.template.image_id)
    packet:writeShort(self.x)
    packet:writeShort(self.y)
    packet:writeByte(self.template.w_block)
    packet:writeByte(self.template.h_block)
    packet:writeByte(self.template.total_frame)
    packet:writeByte(self.template.big_avatar)
    packet:writeUTF(self.template.dialog_text)
    packet:writeByte(self.template.person)
    packet:writeByte(self.template.show_hp)
    return packet:getData()
end

return Npc

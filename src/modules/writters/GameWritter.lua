local Cmd = require "network.Cmd"
local GameWritter = {}

function GameWritter.objectMove(other, mover)
    local packet = Packet(Cmd.OJECT_MOVE)
    packet:writeByte(mover.type)

    if iskindof(mover, "Monster") then
        packet:writeShort(mover.templateId)
    else
        packet:writeShort(0)
    end

    packet:writeShort(mover.id)
    packet:writeShort(mover.x)
    packet:writeShort(mover.y)
    packet:writeByte(0)

    other:send(packet)
end

function GameWritter.npcBig(player, npcList)
    local packet = Packet.new(Cmd.NPC_BIG)
    packet:writeByte(npcList:size())
    npcList:forEach(function(npc)
        packet:writeBytes(npc:toBytes())
    end)
    player:send(packet)
end

return GameWritter

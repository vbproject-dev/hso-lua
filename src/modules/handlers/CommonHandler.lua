local Cmd           = require("network.Cmd")
local CommonWritter = require("modules.writters.CommonWritter")
local PartManager   = require("database.PartManager")
local CommonHandler = {}

function CommonHandler.onNameServer(session, request)
    CommonWritter.monsterCatalog(session)
    CommonWritter.itemTemplate(session)
    CommonWritter.nameServer(session)

    return true
end

function CommonHandler.onLoadImage(session, request)
    local IconLoader = require("utils.IconLoader")
    local bytes = IconLoader.getIcon(session:get("zoom"), request.id)
    if not bytes then
        return false
    end

    return CommonWritter.loadImage(session, { id = request.id, bytes = bytes })
end

function CommonHandler.onLoadPartImage(session, request)
    local data = PartManager.getByZoom(session:get("zoom"), request.type, request.id)
    if not data then
        return false
    end

    return CommonWritter.sendPartData(session, data)
end

function CommonHandler.onSaveRms(session, request)
    local player = session:get("player")

    if not player or request.size <= 0 then
        return false
    end

    local data = { request.data:byte(1, -1) }
    if request.id == 0 then
        player.rms[1] = data
    elseif request.id == 3 and request.size == 11 then
        player.rms[2] = data
    end

    return true
end

function CommonHandler.onHealth(session, request)
    local player = session:get("player")
    if not player then
        return false
    end

    return CommonWritter.updateHealth(player)
end

return {

    [Cmd.NAME_SERVER] = CommonHandler.onNameServer,
    [Cmd.LOAD_IMAGE] = CommonHandler.onLoadImage,
    [Cmd.LOAD_IMAGE_DATA_PART_CHAR] = CommonHandler.onLoadPartImage,
    [Cmd.SAVE_RMS_SERVER] = CommonHandler.onSaveRms,
    [Cmd.PLAYER_SUCKHOE] = CommonHandler.onHealth,

}

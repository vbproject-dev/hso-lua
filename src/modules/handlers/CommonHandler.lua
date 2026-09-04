local Cmd            = require("network.Cmd")
local CommonResponse = require("modules.response.CommonResponse")
local PartManager    = require("database.PartManager")
local MySQL          = require("core.MySQL")
local GameData       = require("database.GameData")
local CommonHandler  = {}

local BODY           = {}

function CommonHandler.onLogin(session, request)
    local user, pass = request.user, request.pass

    -- Check if the account exists and the password is correct


    local db = MySQL.instance()
    local account, err = db:from("account"):where("username", user):getFirst()

    if not account then
        return CommonResponse.loginFail(session, "Account not found")
    end

    local Md5 = require("utils.Md5")
    if not Md5.verifyMD5(pass, account.password) then
        return CommonResponse.loginFail(session, "Incorrect password")
    end

    CommonResponse.saveLogin(session, user, pass)

    -- Check if the client need to receive an update
    local count = PartManager.getPartCount(request.zoom)
    if count ~= request.indexCharPar then
        local parts = PartManager.getAllByZoom(request.zoom):filter(function(part)
            return part.type ~= 113
        end)

        if not CommonResponse.updateData(session, count, parts:size()) then
            return false
        end

        parts:forEach(function(part)
            if not CommonResponse.sendPartData(session, part) then
                return false
            end
        end)
    end


    -- Update the last login and the IP address of the account
    account.ip_address = session:getRemoteAddress():match("^(.-):%d+$")
    account.last_login = os.date("%Y-%m-%d %H:%M:%S")
    local result, err = db:from("account"):where("id", account.id):update({
        ip_address = account.ip_address,
        last_login = account.last_login
    })

    if not result then
        log("Failed to update account: %s" .. tostring(err))
        return false
    end

    -- Set the session data
    session:set("zoom", request.zoom)
    session:set("account", account)

    -- Get the characters associated to the account
    local characters, err = db:from("player"):where("account_id", account.id):getAll()

    if err then
        log("Failed to get characters: " .. tostring(err))
        return false
    end

    -- Send the login success response

    CommonResponse.loginSuccess(session, characters)
    return true
end

function CommonHandler.onNameServer(session, request)
    CommonResponse.monsterCatalog(session)
    CommonResponse.itemTemplate(session)
    CommonResponse.nameServer(session)

    return true
end

function CommonHandler.onLoadImage(session, request)
    local IconLoader = require("utils.IconLoader")
    local bytes = IconLoader.getIcon(session:get("zoom"), request.id)
    if not bytes then
        return false
    end

    return CommonResponse.loadImage(session, { id = request.id, bytes = bytes })
end

function CommonHandler.onLoadPartImage(session, request)
    local data = PartManager.getByZoom(session:get("zoom"), request.type, request.id)
    if not data then
        return false
    end

    return CommonResponse.sendPartData(session, data)
end

function CommonHandler.onCreateChar(session, request)
    if #request.name < 4 or #request.name > 15 then
        return CommonResponse.noticeBox(session, "Name must be between 4 and 15 characters")
    end

    if request.class < 0 or request.class > 3 then
        return CommonResponse.noticeBox(session, "Invalid class")
    end

    -- Validation data
    local HEAD = { 0, 1 }
    local EYE = request.class < 2 and { 8, 9 } or { 10, 11 }
    local HAIR = request.class < 2 and { 0, 1 } or { 2, 3 }
    local items = {
        [0] = { 0, 80, 20 },
        [1] = { 5, 105, 145 },
        [2] = { 10, 90, 50, 130 },
        [3] = { 15, 95, 55, 135 }
    }

    -- Check if the values are valid
    local function contains(list, value)
        for _, v in ipairs(list) do
            if v == value then return true end
        end
        return false
    end

    if not contains(HEAD, request.head) then
        return CommonResponse.noticeBox(session, "Invalid head")
    end

    if not contains(EYE, request.eye) then
        return CommonResponse.noticeBox(session, "Invalid eye")
    end

    if not contains(HAIR, request.hair) then
        return CommonResponse.noticeBox(session, "Invalid hair")
    end

    -- Prepare the equipment
    local wearing = {}
    for __, id in pairs(items[request.class]) do
        local item = GameData.getEquipment(id)
        if item then
            wearing[#wearing + 1] = {
                id = item.id,
                type = item.type,
                part = item.part,
                level = item.level,
                color = item.color,
                options = item.option,
                plus = 0
            }
        end
    end

    -- Create the character
    local db = MySQL.instance()
    local account = session:get("account")

    local char, err = db:from("player"):where("name", request.name):getFirst()
    if char then
        return CommonResponse.noticeBox(session, "Character name already exists")
    end

    local result, err = db:from("player"):insert({
        name = request.name:lower(),
        account_id = account.id,
        class = request.class,
        level = 1,
        exp = 0,
        gold = 1000,
        gem = 100,
        wearing = JSON.fromTable(wearing),
        bag = "[]",
        bank = "[]",
        location = JSON.fromTable({ map = 0, x = 132, y = 132 }),
        info = JSON.fromTable({
            head = request.head,
            eye = request.eye,
            hair = request.hair,
            str = 4,
            dex = 4,
            vit = 4,
            int = 4,
        })
    })

    if not result then
        log("Failed to create character: " .. tostring(err))
        return CommonResponse.noticeBox(session, "Failed to create character")
    end

    -- Get the characters associated to the account
    local characters, err = db:from("player"):where("account_id", account.id):getAll()

    if err then
        log("Failed to get characters: " .. tostring(err))
        return false
    end

    -- Send the login success response

    return CommonResponse.loginSuccess(session, characters)
end

return {
    common = {
        [Cmd.LOGIN] = CommonHandler.onLogin,
        [Cmd.NAME_SERVER] = CommonHandler.onNameServer,
        [Cmd.LOAD_IMAGE] = CommonHandler.onLoadImage,
        [Cmd.LOAD_IMAGE_DATA_PART_CHAR] = CommonHandler.onLoadPartImage,
        [Cmd.CREATE_CHAR] = CommonHandler.onCreateChar
    }
}

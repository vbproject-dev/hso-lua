local Cmd            = require "network.Cmd"
local PacketReader   = require "modules.PacketReader"
local CommonResponse = require "modules.response.CommonResponse"
local PartManager    = require "database.PartManager"

local CommonHandler  = {}

function CommonHandler.onLogin(session, packet)
    local request = PacketReader[Cmd.LOGIN](packet)

    local user, pass = request.user, request.pass

    -- Check if the account exists and the password is correct

    local MySQL = require("core.MySQL")
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

    -- Send the login success response
    --CommonResponse.loginSuccess(session)
    return true
end

function CommonHandler.onNameServer(session, packet)
    CommonResponse.monsterCatalog(session)
    CommonResponse.itemTemplate(session)
    CommonResponse.nameServer(session)
end

return {
    common = {
        [Cmd.LOGIN] = CommonHandler.onLogin,
        [Cmd.NAME_SERVER] = CommonHandler.onNameServer,
    }
}

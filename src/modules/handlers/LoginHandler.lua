local CommonWritter    = require "modules.writters.CommonWritter"
local PartManager      = require "database.PartManager"
local Cmd              = require "network.Cmd"
local LoginWritter     = require "modules.writters.LoginWritter"
local CharacterWritter = require "modules.writters.CharacterWritter"
local LoginHandler     = {}

function LoginHandler.onLogin(session, request)
    local user, pass = request.user, request.pass

    -- Check if the account exists and the password is correct

    local account, err = findTable("account", { username = user })

    if not account then
        return LoginWritter.loginFail(session, "Account not found")
    end

    local Md5 = require("utils.Md5")
    if not Md5.verifyMD5(pass, account.password) then
        return LoginWritter.loginFail(session, "Incorrect password")
    end

    LoginWritter.saveLogin(session, user, pass)

    -- Check if the client need to receive an update
    local count = PartManager.getPartCount(request.zoom)
    if count ~= request.indexCharPar then
        local parts = PartManager.getAllByZoom(request.zoom):filter(function(part)
            return part.type ~= 113
        end)

        if not CommonWritter.updateData(session, count, parts:size()) then
            return false
        end

        parts:forEach(function(part)
            if not CommonWritter.sendPartData(session, part) then
                return false
            end
        end)
    end


    -- Update the last login and the IP address of the account
    account.ip_address = session:getRemoteAddress():match("^(.-):%d+$")
    account.last_login = os.date("%Y-%m-%d %H:%M:%S")
    local result, err = updateTable("account", {
        ip_address = account.ip_address,
        last_login = account.last_login
    }, { id = account.id })

    if not result then
        log("Failed to update account: %s" .. tostring(err))
        return false
    end

    -- Set the session data
    session:set("zoom", request.zoom)
    session:set("account", account)

    log("Zoom %s", tostring(session:get("zoom")))
    return CharacterWritter.selectCharacter(session)
end

return {

    [Cmd.LOGIN] = LoginHandler.onLogin,


}

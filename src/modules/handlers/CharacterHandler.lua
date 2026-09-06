local Cmd              = require "network.Cmd"
local CommonWritter    = require "modules.writters.CommonWritter"
local GameData         = require "database.GameData"
local Equipment        = require "modules.game.items.Equipment"
local GameWorld        = require "modules.game.world.GameWorld"
local Player           = require "modules.game.entities.Player"
local InventoryManager = require "modules.game.inventory.InventoryManager"
local CharacterWritter = require "modules.writters.CharacterWritter"
local CharacterHandler = {}

function CharacterHandler.onCreateChar(session, request)
    if #request.name < 4 or #request.name > 15 then
        return CommonWritter.noticeBox(session, "Name must be between 4 and 15 characters")
    end

    if request.class < 0 or request.class > 3 then
        return CommonWritter.noticeBox(session, "Invalid class")
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
        return CommonWritter.noticeBox(session, "Invalid head")
    end

    if not contains(EYE, request.eye) then
        return CommonWritter.noticeBox(session, "Invalid eye")
    end

    if not contains(HAIR, request.hair) then
        return CommonWritter.noticeBox(session, "Invalid hair")
    end

    -- Prepare the equipment

    local wearing = ArrayList.new()
    for _, id in pairs(items[request.class]) do
        if GameData.getEquipment(id) then
            wearing:add(Equipment.new({ id = id }):toWearingTable())
        end
    end

    -- Create the character

    local account = session:get("account")

    local char, err = findTable("player", { name = request.name })
    if char then
        return CommonWritter.noticeBox(session, "Character name already exists")
    end

    local result, err = insertTable("player", {
        name = request.name:lower(),
        account_id = account.id,
        class = request.class,
        level = 1,
        exp = 0,
        gold = 1000,
        gem = 100,
        wearing = JSON.fromTable(wearing:toTable()),
        inventory = "[]",
        bank = "[]",
        location = JSON.fromTable({ map = 0, x = 132, y = 132 }),
        rms = "[[],[]]",
        strength = 5,
        dexterity = 5,
        vitality = 5,
        intelligence = 5,
        skill = JSON.fromTable({ 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }),
        skill_points = 0,
        potential_points = 0,
        part = JSON.fromTable({
            head = request.head,
            eye = request.eye,
            hair = request.hair,
        })
    })

    if not result then
        log("Failed to create character: " .. tostring(err))
        return CommonWritter.noticeBox(session, "Failed to create character")
    end


    return CharacterWritter.selectCharacter(session)
end

function CharacterHandler.onSelectChar(session, request)
    local account = session:get("account")

    local character, err = findTable("player", { id = request.id })
    if not character then
        log("Failed to find character: " .. tostring(err))
        return CommonWritter.noticeBox(session, "Character not found")
    end

    if character.account_id ~= account.id then
        log("Character does not belong to account: " .. account.id .. " != " .. character.account_id)
        return CommonWritter.noticeBox(session, "Character does not belong to you")
    end

    local player = Player.new(character)
    session:set("player", player)

    GameWorld.instance():registerPlayer(player, session)

    CommonWritter.sendQuest(player)
    CommonWritter.fillRectUpdate(session, 3)
    CommonWritter.sendBytes(session, Cmd.LOGIN, FileUtils.readBytes("msg/table_map"))
    InventoryManager.refresh(player)

    local map = GameWorld.instance():joinMap(player, player.mapId, 0)
    if not map then
        log("Failed to join map: " .. player.mapId)
        return CommonWritter.noticeBox(session, "Map not found")
    end

    if not CommonWritter.listSkill(session) then
        log("Failed to send list skills")
        return false
    end

    if not CommonWritter.loginRms(player) then
        log("Failed to send login RMS")
        return false
    end


    return CommonWritter.fillRectUpdate(session, 5)
end

return {
    [Cmd.CREATE_CHAR] = CharacterHandler.onCreateChar,
    [Cmd.SELECT_CHAR] = CharacterHandler.onSelectChar,
}

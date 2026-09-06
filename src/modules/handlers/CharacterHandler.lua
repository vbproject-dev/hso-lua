local Cmd              = require "network.Cmd"
local CommonWritter    = require "modules.writters.CommonWritter"
local GameData         = require "database.GameData"
local Equipment        = require "modules.game.items.Equipment"
local MySQL            = require "core.MySQL"
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
    local db = MySQL.instance()
    local account = session:get("account")

    local char, err = db:from("player"):where("name", request.name):getFirst()
    if char then
        return CommonWritter.noticeBox(session, "Character name already exists")
    end

    local result, err = db:from("player"):insert({
        name = request.name:lower(),
        account_id = account.id,
        class = request.class,
        level = 1,
        exp = 0,
        gold = 1000,
        gem = 100,
        wearing = JSON.fromTable(wearing:toTable()),
        bag = "[]",
        bank = "[]",
        location = JSON.fromTable({ map = 0, x = 132, y = 132 }),
        rms = "[[],[]]",
        info = JSON.fromTable({
            head = request.head,
            eye = request.eye,
            hair = request.hair,
            str = 5,
            dex = 5,
            vit = 5,
            int = 5,
            skill = { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            skill_point = 0,
            potential_point = 0,
        })
    })

    if not result then
        log("Failed to create character: " .. tostring(err))
        return CommonWritter.noticeBox(session, "Failed to create character")
    end


    return CommonWritter.selectCharacter(session)
end

function CharacterHandler.onSelectChar(session, request)
    local db = MySQL.instance()
    local account = session:get("account")

    local character, err = db:from("player"):where("id", request.id):getFirst()
    if not character then
        return CommonWritter.noticeBox(session, "Character not found")
    end

    if character.account_id ~= account.id then
        return CommonWritter.noticeBox(session, "Character does not belong to you")
    end

    local player = Player.new(character)
    session:set("player", player)

    GameWorld.instance():registerPlayer(player, session)

    CommonWritter.sendQuest(player)
    CharacterWritter.mainCharInfo(player)
    CommonWritter.fillRectUpdate(session, 3)
    CommonWritter.sendBytes(session, Cmd.LOGIN, FileUtils.readBytes("msg/table_map"))
    InventoryManager.refresh(player)

    local map = GameWorld.instance():joinMap(player, player.location.map, 0)
    if not map then
        return CommonWritter.noticeBox(session, "Map not found")
    end

    CommonWritter.listSkill(session)
    CommonWritter.loginRms(player)
    CommonWritter.fillRectUpdate(session, 5)

    return true
end

return {
    [Cmd.CREATE_CHAR] = CharacterHandler.onCreateChar,
    [Cmd.SELECT_CHAR] = CharacterHandler.onSelectChar,
}

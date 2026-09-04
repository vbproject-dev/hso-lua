local IconLoader = {}

local IconType = {
    ITEM_MAP = "ITEM_MAP",
    MONSTER = "MONSTER",
    EQUIPMENT = "EQUIPMENT",
    NPC = "NPC",
    POTION = "POTION",
    QUEST = "QUEST",
    MATERIAL = "MATERIAL",
    SKILL = "SKILL",
    CLAN = "CLAN",
    ARC_CLAN = "ARC_CLAN",
    PET_ICON = "PET_ICON",
    PET_IMAGE = "PET_IMAGE",
    MOUNT = "MOUNT",
    UNKNOWN = "UNKNOWN"
}

local ITEM_MAP_OFFSET = 0
local MONSTER_OFFSET = 1000
local EQUIPMENT_OFFSET = 2000
local NPC_OFFSET = 3000
local POTION_OFFSET = 4000
local QUEST_OFFSET = 5000
local MATERIAL_OFFSET = 5500
local SKILL_OFFSET = 6000
local ICON_CLAN_OFFSET = 7000
local ICON_ARC_CLAN_OFFSET = 9500
local PET_ICON_OFFSET = 10000
local PET_IMAGE_OFFSET = 10200
local MOUNT_OFFSET = 10700
local NEW_EQUIPMENT_OFFSET = 13000

local ICON_CACHE = {}
local CACHE_EXPIRE = 30 * 60

local function key(zoom, iconId)
    return zoom .. ":" .. iconId
end

local function cleanupCache()
    local now = os.time()

    for cacheKey, entry in pairs(ICON_CACHE) do
        if now - entry.time >= CACHE_EXPIRE then
            ICON_CACHE[cacheKey] = nil
        end
    end
end

local function loadFromDisk(cacheKey)
    local zoom, iconId = cacheKey:match("^(%d+):(%d+)$")

    if not zoom then
        return nil
    end

    zoom = tonumber(zoom)
    iconId = tonumber(iconId)

    local path = IconLoader.buildIconPath(zoom, iconId)

    if not FileUtils.exists(path) then
        log("[ICON] Missing: %s", path)
        return nil
    end

    return FileUtils.readBytes(path)
end

function IconLoader.getIcon(zoom, iconId)
    cleanupCache()

    local cacheKey = key(zoom, iconId)
    local entry = ICON_CACHE[cacheKey]

    if entry then
        entry.time = os.time()
        return entry.data
    end

    local data = loadFromDisk(cacheKey)

    if data then
        ICON_CACHE[cacheKey] = {
            data = data,
            time = os.time()
        }
    end

    return data
end

function IconLoader.resolveIcon(iconId)
    if iconId >= NEW_EQUIPMENT_OFFSET then return IconType.EQUIPMENT end
    if iconId >= MOUNT_OFFSET then return IconType.MOUNT end
    if iconId >= PET_IMAGE_OFFSET then return IconType.PET_IMAGE end
    if iconId >= PET_ICON_OFFSET then return IconType.PET_ICON end
    if iconId >= ICON_ARC_CLAN_OFFSET then return IconType.ARC_CLAN end
    if iconId >= ICON_CLAN_OFFSET then return IconType.CLAN end
    if iconId >= SKILL_OFFSET then return IconType.SKILL end
    if iconId >= MATERIAL_OFFSET then return IconType.MATERIAL end
    if iconId >= QUEST_OFFSET then return IconType.QUEST end
    if iconId >= POTION_OFFSET then return IconType.POTION end
    if iconId >= NPC_OFFSET then return IconType.NPC end
    if iconId >= EQUIPMENT_OFFSET then return IconType.EQUIPMENT end
    if iconId >= MONSTER_OFFSET then return IconType.MONSTER end
    if iconId >= ITEM_MAP_OFFSET then return IconType.ITEM_MAP end
    return IconType.UNKNOWN
end

function IconLoader.getLocalId(iconId)
    if iconId >= NEW_EQUIPMENT_OFFSET then return iconId - EQUIPMENT_OFFSET end
    if iconId >= MOUNT_OFFSET then return iconId - MOUNT_OFFSET end
    if iconId >= PET_IMAGE_OFFSET then return iconId - PET_IMAGE_OFFSET end
    if iconId >= PET_ICON_OFFSET then return iconId - PET_ICON_OFFSET end
    if iconId >= ICON_ARC_CLAN_OFFSET then return iconId - ICON_ARC_CLAN_OFFSET end
    if iconId >= ICON_CLAN_OFFSET then return iconId - ICON_CLAN_OFFSET end
    if iconId >= SKILL_OFFSET then return iconId - SKILL_OFFSET end
    if iconId >= MATERIAL_OFFSET then return iconId - MATERIAL_OFFSET end
    if iconId >= QUEST_OFFSET then return iconId - QUEST_OFFSET end
    if iconId >= POTION_OFFSET then return iconId - POTION_OFFSET end
    if iconId >= NPC_OFFSET then return iconId - NPC_OFFSET end
    if iconId >= EQUIPMENT_OFFSET then return iconId - EQUIPMENT_OFFSET end
    if iconId >= MONSTER_OFFSET then return iconId - MONSTER_OFFSET end
    return iconId
end

function IconLoader.getGlobalId(type, localId)
    if type == IconType.ITEM_MAP then return ITEM_MAP_OFFSET + localId end
    if type == IconType.MONSTER then return MONSTER_OFFSET + localId end
    if type == IconType.EQUIPMENT then return EQUIPMENT_OFFSET + localId end
    if type == IconType.NPC then return NPC_OFFSET + localId end
    if type == IconType.POTION then return POTION_OFFSET + localId end
    if type == IconType.QUEST then return QUEST_OFFSET + localId end
    if type == IconType.MATERIAL then return MATERIAL_OFFSET + localId end
    if type == IconType.SKILL then return SKILL_OFFSET + localId end
    if type == IconType.CLAN then return ICON_CLAN_OFFSET + localId end
    if type == IconType.ARC_CLAN then return ICON_ARC_CLAN_OFFSET + localId end
    if type == IconType.PET_ICON then return PET_ICON_OFFSET + localId end
    if type == IconType.PET_IMAGE then return PET_IMAGE_OFFSET + localId end
    if type == IconType.MOUNT then return MOUNT_OFFSET + localId end
    return localId
end

function IconLoader.getIconIdByCategory(zoom, type)
    local dir = string.format("icons/x%d/%s", zoom, type:lower())

    if not FileUtils.directoryExists(dir) then
        return {}
    end

    local result = {}

    for _, filePath in ipairs(FileUtils.listFiles(dir, false)) do
        local fileName = filePath:match("([^/\\]+)$")

        if fileName and fileName:sub(-4) == ".png" then
            local id = tonumber(fileName:sub(1, -5))

            if id then
                result[#result + 1] = id
            end
        end
    end

    table.sort(result)
    return result
end

function IconLoader.buildIconPath(zoom, iconId)
    local folder = IconLoader.resolveIcon(iconId)

    return string.format(
        "icons/x%d/%s/%d.png",
        zoom,
        folder:lower(),
        IconLoader.getLocalId(iconId)
    )
end

function IconLoader.saveIcon(zoom, iconId, bytes)
    local path = IconLoader.buildIconPath(zoom, iconId)

    FileUtils.createDirectories(path:match("^(.*)[/\\]"))
    FileUtils.writeBytes(path, bytes)

    ICON_CACHE[key(zoom, iconId)] = nil

    return path
end

function IconLoader.getNextLocalId(zoom, type)
    local dir = string.format("icons/x%d/%s", zoom, type:lower())

    if not FileUtils.directoryExists(dir) then
        return 1
    end

    local maxId = 0

    for _, filePath in ipairs(FileUtils.listFiles(dir, false)) do
        local fileName = filePath:match("([^/\\]+)$")

        if fileName and fileName:sub(-4) == ".png" then
            local id = tonumber(fileName:sub(1, -5))

            if id and id > maxId then
                maxId = id
            end
        end
    end

    return maxId + 1
end

return IconLoader

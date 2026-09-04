local PartManager = {}

local BASE_DIR = "part"
local CACHE_EXPIRE = 5 * 60
local PART_CACHE = {}
local PART_COUNT = {}
local function key(variant, type, id)
    return variant .. ":" .. type .. ":" .. id
end

local function resolveVariant(zoomLv)
    if zoomLv == 2 then return "x2" end
    if zoomLv == 3 then return "x3" end
    if zoomLv == 4 then return "x4" end
    return "x1"
end

local function cleanupCache()
    local now = os.time()

    for cacheKey, entry in pairs(PART_CACHE) do
        if now - entry.time >= CACHE_EXPIRE then
            PART_CACHE[cacheKey] = nil
        end
    end
end


local function loadFromLocalDiskLegacy(variant, type, id)
    local baseName = string.format("%d_%d", type, id)
    local imagePath = string.format("%s/%s/img/%s.png", BASE_DIR, variant, baseName)
    local dataPath = string.format("%s/%s/data/%s", BASE_DIR, variant, baseName)

    if not FileUtils.exists(imagePath) then
        return nil
    end

    if not FileUtils.exists(dataPath) then
        return nil
    end

    local imageBytes = FileUtils.readBytes(imagePath)
    local dataBytes = FileUtils.readBytes(dataPath)

    local part = {
        type = type,
        id = id,
        image = imageBytes,
        imageData = dataBytes
    }


    return part
end

local function loadFromDisk(cacheKey)
    local variant, type, id = cacheKey:match("^([^:]+):([^:]+):([^:]+)$")

    if not variant then
        return nil
    end

    type = tonumber(type)
    id = tonumber(id)

    return loadFromLocalDiskLegacy(variant, type, id)
end

function PartManager.getByZoom(zoomLv, type, id)
    cleanupCache()

    local variant = resolveVariant(zoomLv)
    local cacheKey = key(variant, type, id)
    local entry = PART_CACHE[cacheKey]

    if entry then
        return entry.data
    end

    local part = loadFromDisk(cacheKey)

    if part then
        PART_CACHE[cacheKey] = {
            data = part,
            time = os.time()
        }
    end

    return part
end

function PartManager.loadPartsByType(zoomLv, type)
    cleanupCache()

    local variant = resolveVariant(zoomLv)
    local imageDir = string.format("%s/%s/img", BASE_DIR, variant)
    local result = ArrayList.new()

    if not FileUtils.directoryExists(imageDir) then
        return result
    end

    local files = FileUtils.listFiles(imageDir, false)
    local prefix = tostring(type) .. "_"

    for _, filePath in ipairs(files) do
        local fileName = filePath:match("([^/\\]+)$")

        if fileName and fileName:sub(1, #prefix) == prefix and fileName:sub(-4) == ".png" then
            local baseName = fileName:sub(1, -5)
            local fileType, id = baseName:match("^(%d+)_(%d+)$")

            if fileType and id then
                local part = PartManager.getByZoom(zoomLv, tonumber(fileType), tonumber(id))

                if part then
                    result:add(part)
                end
            end
        end
    end

    result:sort(function(a, b)
        return a.id < b.id
    end)

    return result
end

function PartManager.getAllByZoom(zoomLv)
    cleanupCache()

    local variant = resolveVariant(zoomLv)
    local imageDir = string.format("%s/%s/img", BASE_DIR, variant)
    local result = ArrayList.new()

    if not FileUtils.directoryExists(imageDir) then
        return result
    end

    local files = FileUtils.listFiles(imageDir, false)

    for _, filePath in ipairs(files) do
        local fileName = filePath:match("([^/\\]+)$")

        if fileName and fileName:sub(-4) == ".png" then
            local baseName = fileName:sub(1, -5)
            local type, id = baseName:match("^(%d+)_(%d+)$")

            if type and id then
                local part = PartManager.getByZoom(zoomLv, tonumber(type), tonumber(id))

                if part then
                    result:add(part)
                end
            end
        end
    end

    result:sort(function(a, b)
        return a.id < b.id
    end)

    return result
end

function PartManager.getPartCount(zoomLv)
    local count = PART_COUNT[zoomLv]

    if count then
        return count
    end

    local variant = resolveVariant(zoomLv)
    local imageDir = string.format("%s/%s/img", BASE_DIR, variant)

    if not FileUtils.directoryExists(imageDir) then
        PART_COUNT[zoomLv] = 0
        return 0
    end

    local files = FileUtils.listFiles(imageDir, false)
    count = 0

    for _, filePath in ipairs(files) do
        local fileName = filePath:match("([^/\\]+)$")

        if fileName and fileName:match("^%d+_%d+%.png$") then
            count = count + 1
        end
    end

    PART_COUNT[zoomLv] = count
    return count
end

return PartManager

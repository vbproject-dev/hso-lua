-- src/core/Config.lua
-- Loads and parses the JSON configuration file.

local Config = {}

function Config.load(path)
    path = path or "config.json"

    if not FileUtils.exists(path) then
        log("[Config] Cannot open config file: %s", path)
        return nil
    end

    local content = FileUtils.readText(path)
    local data = JSON.toTable(content)

    if not data then
        log("[Config] Failed to parse config file: %s", path)
        return nil
    end

    log("[Config] Loaded from: %s", path)

    return data
end

return Config

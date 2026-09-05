local GameData = {
    settings = ArrayList.new(),
    monsters = ArrayList.new(),
    equipments = ArrayList.new(),
    materials = ArrayList.new(),
    potions = ArrayList.new(),
    options = ArrayList.new(),
    maps = ArrayList.new(),
    npcs = ArrayList.new(),
    skills = ArrayList.new()
}

function GameData.load()
    local datasets = {
        { table = "monster",        field = "monsters" },
        { table = "settings",       field = "settings" },
        { table = "item_equipment", field = "equipments" },
        { table = "item_material",  field = "materials" },
        { table = "item_potion",    field = "potions" },
        { table = "item_option",    field = "options" },
        { table = "map_data",       field = "maps" },
        { table = "npc",            field = "npcs" },
        { table = "skill",          field = "skills" }
    }

    for _, dataset in ipairs(datasets) do
        local result, err = loadTable(dataset.table)

        if not result then
            log("Failed to load %s: %s", dataset.table, err)

            return false
        end

        GameData[dataset.field] = result
    end

    return true
end

function GameData.getSetting(name)
    local setting = GameData.settings:findFirst(function(data) return data.name == name end)
    return setting and setting.data
end

function GameData.getEquipment(id)
    return GameData.equipments:findFirst(function(data) return data.id == id end)
end

function GameData.getMaterial(id)
    return GameData.materials:findFirst(function(data) return data.id == id end)
end

function GameData.getPotion(id)
    return GameData.potions:findFirst(function(data) return data.id == id end)
end

function GameData.getNpc(id)
    return GameData.npcs:findFirst(function(data) return data.id == id end)
end

function GameData.getSkill(id)
    return GameData.skills:findFirst(function(data) return data.id == id end)
end

function GameData.getOption(id)
    return GameData.options:findFirst(function(data) return data.id == id end)
end

return GameData

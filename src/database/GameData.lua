local GameData = {
    settings = ArrayList.new(),
    monsters = ArrayList.new(),
    equipments = ArrayList.new(),
    materials = ArrayList.new(),
    potions = ArrayList.new(),
    options = ArrayList.new(),
}

function GameData.load()
    local datasets = {
        { table = "monster",        field = "monsters" },
        { table = "settings",       field = "settings" },
        { table = "item_equipment", field = "equipments" },
        { table = "item_material",  field = "materials" },
        { table = "item_potion",    field = "potions" },
        { table = "item_option",    field = "options" },
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
    return GameData.settings:findFirst(function(data) return data.name == name end).data
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

return GameData

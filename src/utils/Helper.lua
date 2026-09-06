local Helper = {}

function Helper.tableToString(data)
    return string.char(table.unpack(data))
end

function Helper.stringToTable(str)
    local data = {}
    for i = 1, #str do data[i] = str:byte(i) end
    return data
end

return Helper

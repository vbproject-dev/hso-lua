local FileService = {}

function FileService:list(path)
    local files, err = File.list(path)

    if not files then
        return nil, err
    end

    local result = {}

    for _, path in ipairs(files) do
        local info, err = File.info(path)

        if not info then
            return nil, err
        end

        result[#result + 1] = info
    end

    return result
end

function FileService:read(path)
    local content, err = File.read(path)
    if not content then
        return nil, err
    end
    return content
end

function FileService:create(path, content)
    return File.write(path, content or "")
end

function FileService:save(path, content)
    return File.write(path, content or "")
end

function FileService:delete(path)
    return File.remove(path, false)
end

return FileService

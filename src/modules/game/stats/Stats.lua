--[[
    Stats

    A plain id -> value bag. This is your original class, unchanged, with
    one addition: `mergeInto(target)`, used by StatManager to fold several
    Stats layers (base / equipment / buffs) together.
]]

local Stats = class("Stats")

function Stats:ctor()
    self.data = {}
end

function Stats:reset()
    self.data = {}
end

function Stats:get(id)
    return self.data[id] or 0
end

function Stats:set(id, value)
    self.data[id] = value
end

function Stats:add(id, value)
    self.data[id] = (self.data[id] or 0) + value
end

function Stats:remove(id, value)
    self.data[id] = (self.data[id] or 0) - value
end

function Stats:clear(id)
    self.data[id] = nil
end

function Stats:has(id)
    return self.data[id] ~= nil
end

function Stats:all()
    return self.data
end

-- Add every value in this Stats instance onto `target` (another Stats).
function Stats:mergeInto(target)
    for id, value in pairs(self.data) do
        target:add(id, value)
    end
end

-- Convenience for debugging / logging.
function Stats:toString(StatDefs)
    local parts = {}
    for id, value in pairs(self.data) do
        local name = StatDefs and StatDefs.get(id) and StatDefs.get(id).name or ("id=" .. tostring(id))
        table.insert(parts, string.format("%s=%s", name, tostring(value)))
    end
    return table.concat(parts, ", ")
end

return Stats

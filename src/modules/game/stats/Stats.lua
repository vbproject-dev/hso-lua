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

return Stats

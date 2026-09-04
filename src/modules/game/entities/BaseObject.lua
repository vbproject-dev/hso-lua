local BaseObject = class("BaseObject")

function BaseObject:ctor(data)
    self.id = data.id or 0
    self.name = data.name or ""
    self.location = data.location or {}
end

return BaseObject

local BaseObject = class("BaseObject")

function BaseObject:ctor(data)
    self.id = data.id or 0
    self.name = data.name or ""
    self.location = data.location or {}
    self.mapId = self.location.map or -1
    self.x = self.location.x or 0
    self.y = self.location.y or 0
end

return BaseObject

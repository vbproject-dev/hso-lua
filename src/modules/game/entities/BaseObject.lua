local BaseObject = class("BaseObject")

function BaseObject:ctor(data)
    self.id = data.id or 0
    self.name = data.name or ""
    self.location = data.location or {}
    self.mapId = self.location.map or -1
    self.x = self.location.x or 0
    self.y = self.location.y or 0

    self.zone = nil
end

function BaseObject:setPosition(x, y)
    self.x = x
    self.y = y
end

function BaseObject:setZone(zone)
    self.zone = zone
    if zone then
        self.mapId = self.zone:getMap().id
    end
end

function BaseObject:getZone()
    return self.zone
end

function BaseObject:getMap()
    return self.zone and self.zone.map or nil
end

return BaseObject

local BaseObject = class("BaseObject")

function BaseObject:ctor(data)
    self.id = data.id or 0
    self.name = data.name or ""
    self.location = data.location or {}
    self.mapId = self.location.map or -1
    self.x = self.location.x or 0
    self.y = self.location.y or 0

    self.hp = 0
    self.maxHp = 0
    self.mp = 0
    self.maxMp = 0
    self.zone = nil
    self.stats = nil
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

function BaseObject:takeDamage(damage)
    if self:isDead() then
        return 0
    end

    local damage = math.max(0, damage or 0)
    local actualDamage = math.min(self.hp, damage)

    self.hp = self.hp - actualDamage

    return actualDamage
end

function BaseObject:distanceTo(target)
    local dx = self.x - target.x
    local dy = self.y - target.y
    return math.sqrt(dx * dx + dy * dy)
end

function BaseObject:isInDistance(target, distance)
    return self:distanceTo(target) <= distance
end

function BaseObject:isDead() return self.hp <= 0 end

return BaseObject

local DamageType = {
    PHYSICAL = { 0, 7 },
    FIRE = { 1, 8 },
    ICE = { 2, 9 },
    POISON = { 3, 10 },
    LIGHTING = { 4, 11 },
    LIGHT = { 5, 12 },
    DARK = { 6, 13 }
}

local LOOKUP = {}

for damageType, ids in pairs(DamageType) do
    for _, id in ipairs(ids) do
        LOOKUP[id] = damageType
    end
end

function DamageType.fromValue(id)
    return LOOKUP[id] or DamageType.PHYSICAL
end

return DamageType

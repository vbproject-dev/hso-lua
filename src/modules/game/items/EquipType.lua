local Slot = require("modules.game.items.Slot")

local EquipType = {
    [Slot.ARMOR] = { 0 },
    [Slot.LEG] = { 1 },
    [Slot.HELMET] = { 2 },
    [Slot.GLOVE] = { 3 },
    [Slot.RING_1] = { 4 },
    [Slot.RING_2] = { 4 },
    [Slot.NECKLACE] = { 5 },
    [Slot.BOOTS] = { 6 },
    [Slot.WING] = { 7 },
    [Slot.WEAPON] = { 8, 9, 10, 11 },
    [Slot.PET] = { 14 },
    [Slot.COSTUME] = { 15 },
    [Slot.FASHION_MEDAL] = { 16 },
    [Slot.FASHION_MASK] = { 21 },
    [Slot.FASHION_WING] = { 22 },
    [Slot.FASHION_CLOAK] = { 23 },
    [Slot.FASHION_WEAPON] = { 24 },
    [Slot.FASHION_HAIR] = { 25 },
    [Slot.FASHION_HEADPHONE] = { 26 },
    [Slot.FASHION_CROWN] = { 26 },
    [Slot.FASHION_TITLE] = { 27 },
    [Slot.FASHION_BODY] = { 28 },
    [Slot.FASHION_MOUNT] = { 29 },
    [Slot.FASHION_12] = { 30 }
}

function EquipType.getSlot(type)
    for slot, types in pairs(EquipType) do
        for _, value in ipairs(types) do
            if value == type then
                return slot
            end
        end
    end
end

function EquipType.getAvailableSlot(type, wearing)
    for slot, types in pairs(EquipType) do
        for _, value in ipairs(types) do
            if value == type and not wearing:get(slot) then
                return slot
            end
        end
    end
end

function EquipType.isValid(slot, type)
    for _, value in ipairs(EquipType[slot] or {}) do
        if value == type then
            return true
        end
    end
    return false
end

return EquipType

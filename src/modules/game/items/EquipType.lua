local Slot = require "modules.game.items.Slot"
local EquipType = {
    [0] = { Slot.ARMOR },
    [1] = { Slot.LEG },
    [2] = { Slot.HELMET },
    [3] = { Slot.GLOVE },
    [4] = { Slot.RING_1, Slot.RING_2 },
    [5] = { Slot.NECKLACE },
    [6] = { Slot.BOOTS },
    [7] = { Slot.WING },
    [8] = { Slot.WEAPON },
    [9] = { Slot.WEAPON },
    [10] = { Slot.WEAPON },
    [11] = { Slot.WEAPON },
    [14] = { Slot.PET },
    [15] = { Slot.COSTUME },
    [16] = { Slot.FASHION_MEDAL },
    [21] = { Slot.FASHION_MASK },
    [22] = { Slot.FASHION_WING },
    [23] = { Slot.FASHION_CLOAK },
    [24] = { Slot.FASHION_WEAPON },
    [25] = { Slot.FASHION_HAIR },
    [26] = { Slot.FASHION_HEADPHONE, Slot.FASHION_CROWN },
    [27] = { Slot.FASHION_TITLE },
    [28] = { Slot.FASHION_BODY },
    [29] = { Slot.FASHION_MOUNT },
    [30] = { Slot.FASHION_12 }
}

return EquipType

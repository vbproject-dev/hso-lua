--[[
    ClassIds

    Two independent choices a character has:

      CLASS - the job: Assassin / Warrior / Gunner / Mage
      TYPE  - the build within that job: Physical or Magical

    They're orthogonal (any class can be Physical or Magical) so they're
    stored as two separate fields on Player (`class`, `combatType`) rather
    than 8 separate class ids. See ClassData.lua for how each of the 8
    (class, type) combinations grows stats differently.
]]

return {
    CLASS = {
        WARRIOR  = 0,
        ASSASSIN = 1,
        MAGE     = 2,
        GUNNER   = 3,
    },
    TYPE = {
        PHYSICAL = 0,
        MAGICAL  = 1,
    },
}

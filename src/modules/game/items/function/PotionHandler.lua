local PotionHandler = {}

function PotionHandler.heal(player, item)
    return false
end

function PotionHandler.resetAttributes(player, item)
    player:resetAttributes()
    player.inventory:remove(item, 1)
    return true
end

function PotionHandler.resetSkills(player, item)
    player:resetSkills()
    player.inventory:remove(item, 1)
    return true
end

-- [ITEM_ID] = function(player, item) end
return {
    [0] = PotionHandler.heal,
    [6] = PotionHandler.resetAttributes,
    [7] = PotionHandler.resetSkills,
}

config = {}

config.debug = false -- set to true to enable debug prints

-- simple reward lists for each loot box type
config.lootBoxes = {
    ammocratet1 = {
        rewards = {
            {item = 'ammo-9', min = 50, max = 150, chance = 40},
            {item = 'ammo-50', min = 50, max = 150, chance = 40},
            {item = 'ammo-shotgun', min = 15, max = 35, chance = 20}
        }
    },
    
    ammocratet2 = {
        rewards = {
            {item = 'ammo-9', min = 100, max = 250, chance = 30},
            {item = 'ammo-50', min = 100, max = 200, chance = 30},
            {item = 'ammo-rifle', min = 50, max = 150, chance = 25},
            {item = 'ammo-shotgun', min = 20, max = 50, chance = 15}
        }
    },
    
    ammocratet3 = {
        rewards = {
            {item = 'ammo-rifle', min = 150, max = 300, chance = 35},
            {item = 'ammo-rifle2', min = 100, max = 250, chance = 35},
            {item = 'ammo-9', min = 200, max = 400, chance = 20},
            {item = 'ammo-50', min = 150, max = 300, chance = 10}
        }
    },
    
    -- other loot box types to show the general system
    medicalbox = {
        rewards = {
            {item = 'bandage', min = 5, max = 15, chance = 40},
            {item = 'firstaid', min = 2, max = 8, chance = 30},
            {item = 'morphine', min = 1, max = 3, chance = 20},
            {item = 'defib', min = 1, max = 1, chance = 10}
        }
    },
    
    weaponcase = {
        rewards = {
            {item = 'weapon_pistol', min = 1, max = 1, chance = 30},
            {item = 'weapon_smg', min = 1, max = 1, chance = 25},
            {item = 'weapon_rifle', min = 1, max = 1, chance = 20},
            {item = 'weapon_shotgun', min = 1, max = 1, chance = 15},
            {item = 'weapon_sniper', min = 1, max = 1, chance = 10}
        }
    },
    
    supplycrate = {
        rewards = {
            {item = 'water', min = 10, max = 25, chance = 30},
            {item = 'bread', min = 5, max = 15, chance = 30},
            {item = 'phone', min = 1, max = 1, chance = 20},
            {item = 'radio', min = 1, max = 1, chance = 15},
            {item = 'cash', min = 1000, max = 5000, chance = 5}
        }
    }
}

-- backwards compatibility 
Config = config

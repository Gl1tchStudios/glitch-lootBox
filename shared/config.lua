config = {}

config.debug = true -- set to true to enable debug prints
config.useUI = true -- set to false to use classic notifications instead of UI

config.ui = {
    -- Inventory system configuration - change this to match your inventory
    inventory = {
        system = 'ox', -- 'ox', 'qb', 'esx'
        iconPath = 'nui://ox_inventory/web/images/',
        iconExtension = '.png',
        fallbackIcon = 'nui://ox_inventory/web/images/placeholder.png'
    },
    
    -- Rarity colors for UI
    rarityColors = {
        common = '#b0c3d9',
        uncommon = '#5e98d9', 
        rare = '#4b69ff',
        ['very-rare'] = '#8847ff',
        epic = '#d32ce6',
        legendary = '#eb4b4b'
    }
}

-- ████ Loot Box System ████

-- weight is chance for item to drop out of 100

config.lootBoxes = {
    ammocratet1 = {
        name = 'Ammo Crate T1',
        rewards = {
            { item = 'ammo-9', label = '9mm Ammo', min = 50, max = 150, rarity = 'common', weight = 40 },
            { item = 'ammo-50', label = '.50 Cal Ammo', min = 50, max = 150, rarity = 'uncommon', weight = 40 },
            { item = 'ammo-shotgun', label = 'Shotgun Shells', min = 15, max = 35, rarity = 'rare', weight = 20 }
        },
        bonusItems = { -- any items here have an 100% chance to drop
            { item = 'money', amount = {min = 25, max = 100}, label = 'Cash Find' }
        }
    },
    
    ammocratet2 = {
        name = 'Ammo Crate T2',
        rewards = {
            { item = 'ammo-9', label = '9mm Ammo', min = 100, max = 250, rarity = 'common', weight = 30 },
            { item = 'ammo-50', label = '.50 Cal Ammo', min = 100, max = 200, rarity = 'uncommon', weight = 30 },
            { item = 'ammo-rifle', label = 'Rifle Ammo', min = 50, max = 150, rarity = 'rare', weight = 25 },
            { item = 'ammo-shotgun', label = 'Shotgun Shells', min = 20, max = 50, rarity = 'epic', weight = 15 }
        },
        bonusItems = {
            { item = 'money', amount = {min = 50, max = 200}, label = 'Cash Find' },
            { item = 'bandage', amount = 1, label = 'First Aid' }
        }
    },
    
    ammocratet3 = {
        name = 'Ammo Crate T3',
        rewards = {
            { item = 'ammo-rifle', label = 'Rifle Ammo', min = 150, max = 300, rarity = 'uncommon', weight = 35 },
            { item = 'ammo-rifle2', label = 'Advanced Rifle Ammo', min = 100, max = 250, rarity = 'rare', weight = 35 },
            { item = 'ammo-9', label = '9mm Ammo', min = 200, max = 400, rarity = 'common', weight = 20 },
            { item = 'ammo-50', label = '.50 Cal Ammo', min = 150, max = 300, rarity = 'epic', weight = 10 }
        },
        bonusItems = {
            { item = 'money', amount = {min = 100, max = 300}, label = 'Cash Find' },
            { item = 'bandage', amount = 2, label = 'Medical Supplies' },
            { item = 'lockpick', amount = 1, label = 'Tool Bonus' }
        }
    }
}

-- backwards compatibility 
Config = config

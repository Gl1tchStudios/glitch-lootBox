config = {}

config.debug = false -- print every roll / grant to the server console
config.useUI = true  -- false = crates open instantly with a notification, no UI

-- ====================================================================
-- UI
-- ====================================================================

config.ui = {
    showPreview    = true,  -- CS2 "Unlock Container" screen (contents + odds) before the reel spins
    showChances    = true,  -- show drop odds on the preview screen
    spinTime       = 6.5,   -- seconds the reel spins before it settles
    reelLength     = 56,    -- cards on the reel
    winnerIndex    = 48,    -- card (1-based) the reel lands on; keep it at least 4 below reelLength
    allowSkip      = true,  -- SPACE / ESC skips straight to the reveal
    volume         = 0.5,   -- reel tick volume, 0 to mute (the reveal uses GTA frontend sounds)
    blurBackground = true,  -- blur the game behind the UI

    inventory = {
        iconPath      = 'nui://ox_inventory/web/images/',
        iconExtension = '.png',
        fallbackIcon  = false, -- image url for items without an icon (false = built-in placeholder)
    },
}

-- ====================================================================
-- Rarities
-- ====================================================================
-- Keys are what the loot tables below use in `rarity = '...'`.
-- order   : higher = rarer (sorting; 5 and up get sparkles on the reveal)
-- color   : CS2 grade colours by default
-- sound   : GTA frontend sound { name, soundSet } played on the reveal
-- mystery : hidden behind a gold star card on the preview and reel until revealed,
--           like the CS2 "Rare Special Item"

config.rarities = {
    common        = { order = 1, label = 'Common',    color = '#b0c3d9', sound = { 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET' } },
    uncommon      = { order = 2, label = 'Uncommon',  color = '#5e98d9', sound = { 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET' } },
    rare          = { order = 3, label = 'Rare',      color = '#4b69ff', sound = { 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET' } },
    ['very-rare'] = { order = 4, label = 'Very Rare', color = '#8847ff', sound = { 'WEAPON_PURCHASE', 'HUD_AMMO_SHOP_SOUNDSET' } },
    epic          = { order = 5, label = 'Epic',      color = '#d32ce6', sound = { 'RANK_UP', 'HUD_AWARDS' } },
    legendary     = { order = 6, label = 'Legendary', color = '#eb4b4b', sound = { 'CHALLENGE_UNLOCKED', 'HUD_AWARDS' } },
    mythic        = { order = 7, label = 'Mythic',    color = '#e4ae39', sound = { 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET' }, mystery = true },
}

-- ====================================================================
-- Loot boxes
-- ====================================================================
-- The key is the inventory item name of the crate.
-- rewards    : exactly one is rolled. `chance` is a weight (they do not need to add up to 100,
--              decimals are fine). min/max is the amount range.
-- bonusItems : always given on top of the reward. amount = number or { min = x, max = y }.
-- accent     : colour of the case art on the preview screen (optional)
-- image      : image url to use instead of the drawn case (optional)
-- label      : optional, falls back to the inventory item label
--
-- Heist caches (crafting plan) also use:
-- blueprint  : glitch-crafting recipe id; the reward is a crafting_blueprint item with
--              that recipe (needs glitch-crafting running). unlock = '<id>' works the same
--              for glitch-crafting ServerConfig.Unlocks.
-- sources    : { jobId = true } - the reward only exists in crates from these jobs
--              (glitch-crafting writes the job into the crate's metadata.source)
-- weights    : { jobId = 2.0 } - multiplies the reward's chance for crates from that job

config.lootBoxes = {
    ammocratet1 = {
        name = 'Ammo Crate T1',
        accent = '#b0c3d9',
        rewards = {
            { item = 'ammo-9',       label = '9mm Ammo',       min = 50, max = 150, rarity = 'common',   chance = 40 },
            { item = 'ammo-50',      label = '.50 Cal Ammo',   min = 50, max = 150, rarity = 'uncommon', chance = 40 },
            { item = 'ammo-shotgun', label = 'Shotgun Shells', min = 15, max = 35,  rarity = 'rare',     chance = 20 },
        },
        bonusItems = {
            { item = 'money', amount = { min = 25, max = 100 }, label = 'Cash Find' },
        },
    },

    ammocratet2 = {
        name = 'Ammo Crate T2',
        accent = '#4b69ff',
        rewards = {
            { item = 'ammo-9',       label = '9mm Ammo',       min = 100, max = 250, rarity = 'common',   chance = 30 },
            { item = 'ammo-50',      label = '.50 Cal Ammo',   min = 100, max = 200, rarity = 'uncommon', chance = 30 },
            { item = 'ammo-rifle',   label = 'Rifle Ammo',     min = 50,  max = 150, rarity = 'rare',     chance = 25 },
            { item = 'ammo-shotgun', label = 'Shotgun Shells', min = 20,  max = 50,  rarity = 'epic',     chance = 15 },
        },
        bonusItems = {
            { item = 'money',   amount = { min = 50, max = 200 }, label = 'Cash Find' },
            { item = 'bandage', amount = 1,                       label = 'First Aid' },
        },
    },

    ammocratet3 = {
        name = 'Ammo Crate T3',
        accent = '#d32ce6',
        rewards = {
            { item = 'ammo-rifle',  label = 'Rifle Ammo',          min = 150, max = 300, rarity = 'uncommon', chance = 35 },
            { item = 'ammo-rifle2', label = 'Advanced Rifle Ammo', min = 100, max = 250, rarity = 'rare',     chance = 35 },
            { item = 'ammo-9',      label = '9mm Ammo',            min = 200, max = 400, rarity = 'common',   chance = 20 },
            { item = 'ammo-50',     label = '.50 Cal Ammo',        min = 150, max = 300, rarity = 'epic',     chance = 10 },
        },
        bonusItems = {
            { item = 'money',    amount = { min = 100, max = 300 }, label = 'Cash Find' },
            { item = 'bandage',  amount = 2,                        label = 'Medical Supplies' },
            { item = 'lockpick', amount = 1,                        label = 'Tool Bonus' },
        },
    },

    -- ----------------------------------------------------------------------------
    -- Heist caches (Glitch'd Roleplay crafting plan). glitch-crafting hands these out
    -- when a robbery reports to the tablet (ServerConfig.CacheDrops).
    -- ----------------------------------------------------------------------------

    cache_street = {
        name = 'Street Stash',
        accent = '#b0c3d9',
        rewards = {
            { item = 'metalscrap',         label = 'Scrap Metal',        min = 10, max = 20, rarity = 'common',    chance = 35 },
            { item = 'copper',             label = 'Copper',             min = 6,  max = 12, rarity = 'common',    chance = 25 },
            { item = 'aluminum',           label = 'Aluminum',           min = 4,  max = 8,  rarity = 'uncommon',  chance = 15 },
            { blueprint = 'trojan_usb',    label = 'Blueprint: Trojan USB',     min = 1, max = 1, rarity = 'rare',      chance = 8 },
            { blueprint = 'atm_hacker',    label = 'Blueprint: ATM Hacker',     min = 1, max = 1, rarity = 'rare',      chance = 6 },
            { blueprint = 'at_suppressor_light', label = 'Blueprint: Pistol Suppressor', min = 1, max = 1, rarity = 'very-rare', chance = 5 },
            { item = 'industrial_diamond', label = 'Industrial Diamond', min = 1,  max = 1,  rarity = 'very-rare', chance = 3 },
            { blueprint = 'WEAPON_SNSPISTOL', label = 'Blueprint: SNS Pistol',  min = 1, max = 1, rarity = 'epic',      chance = 2 },
            { blueprint = 'glass_cutter',  label = 'Blueprint: Glass Cutter',   min = 1, max = 1, rarity = 'epic',      chance = 1 },
        },
        bonusItems = {
            { item = 'plastic', amount = 3, label = 'Plastic' },
        },
    },

    cache_deposit = {
        name = 'Deposit Box',
        accent = '#4b69ff',
        rewards = {
            { item = 'steel',              label = 'Steel',              min = 6, max = 10, rarity = 'common',    chance = 26 },
            { item = 'aluminum',           label = 'Aluminum',           min = 8, max = 14, rarity = 'common',    chance = 20 },
            { item = 'military_circuit',   label = 'Military Circuit',   min = 1, max = 1,  rarity = 'uncommon',  chance = 14 },
            { item = 'blasting_cap',       label = 'Blasting Cap',       min = 1, max = 1,  rarity = 'uncommon',  chance = 12, weights = { armored_truck = 2.0 } },
            { item = 'industrial_diamond', label = 'Industrial Diamond', min = 1, max = 2,  rarity = 'rare',      chance = 10, weights = { paleto_bank = 2.0 } },
            { blueprint = 'at_scope_medium',     label = 'Blueprint: Medium Scope',   min = 1, max = 1, rarity = 'rare',      chance = 6 },
            { blueprint = 'hacking_laptop',      label = 'Blueprint: Hacking Laptop', min = 1, max = 1, rarity = 'very-rare', chance = 6 },
            { blueprint = 'thermite',            label = 'Blueprint: Thermite',       min = 1, max = 1, rarity = 'very-rare', chance = 5 },
            { blueprint = 'WEAPON_COMBATPISTOL', label = 'Blueprint: Combat Pistol',  min = 1, max = 1, rarity = 'very-rare', chance = 4 },
            { blueprint = 'c4_charge',           label = 'Blueprint: C4 Charge',      min = 1, max = 1, rarity = 'epic',      chance = 3.5, weights = { armored_truck = 2.0 } },
            { blueprint = 'WEAPON_PUMPSHOTGUN',  label = 'Blueprint: Pump Shotgun',   min = 1, max = 1, rarity = 'epic',      chance = 3 },
            { blueprint = 'heavy_drill',         label = 'Blueprint: Heavy Drill',    min = 1, max = 1, rarity = 'epic',      chance = 2, weights = { paleto_bank = 2.0 } },
            { blueprint = 'military_thermite',   label = 'Blueprint: Military Thermite', min = 1, max = 1, rarity = 'legendary', chance = 1.5 },
        },
        bonusItems = {
            { item = 'copper_wire', amount = 4, label = 'Copper Wire' },
        },
    },

    cache_vault = {
        name = 'Vault Strongbox',
        accent = '#d32ce6',
        rewards = {
            { item = 'blasting_cap',       label = 'Blasting Cap',       min = 2, max = 3, rarity = 'uncommon',  chance = 22 },
            { item = 'military_circuit',   label = 'Military Circuit',   min = 2, max = 2, rarity = 'uncommon',  chance = 18 },
            { item = 'industrial_diamond', label = 'Industrial Diamond', min = 2, max = 2, rarity = 'rare',      chance = 15 },
            { item = 'filter_cartridge',   label = 'Filter Cartridge',   min = 2, max = 2, rarity = 'rare',      chance = 12 },
            { item = 'nylon_webbing',      label = 'Nylon Webbing',      min = 1, max = 2, rarity = 'very-rare', chance = 10,
              sources = { union_depository = true, yacht = true } },
            { blueprint = 'shaped_charge',      label = 'Blueprint: Shaped Charge', min = 1, max = 1, rarity = 'epic',      chance = 8 },
            { blueprint = 'hazmat_suit',        label = 'Blueprint: Hazmat Suit',   min = 1, max = 1, rarity = 'epic',      chance = 6 },
            { blueprint = 'WEAPON_MICROSMG',    label = 'Blueprint: Micro SMG',     min = 1, max = 1, rarity = 'epic',      chance = 5 },
            { blueprint = 'at_clip_drum_smg',   label = 'Blueprint: SMG Drum',      min = 1, max = 1, rarity = 'epic',      chance = 5 },
            { blueprint = 'WEAPON_SMG',         label = 'Blueprint: SMG',           min = 1, max = 1, rarity = 'legendary', chance = 3 },
            { blueprint = 'at_clip_drum_rifle', label = 'Blueprint: Rifle Drum',    min = 1, max = 1, rarity = 'legendary', chance = 3 },
            { blueprint = 'rappel_equipment',   label = 'Blueprint: Rappel Equipment', min = 1, max = 1, rarity = 'mythic', chance = 2,
              sources = { union_depository = true, yacht = true } },
        },
        bonusItems = {
            { item = 'steel', amount = 8, label = 'Steel' },
        },
    },

    cache_diamond = {
        name = 'Diamond Case',
        accent = '#e4ae39',
        rewards = {
            { item = 'diamond',       label = 'Diamonds',      min = 3, max = 6, rarity = 'rare',      chance = 35 },
            { item = 'blasting_cap',  label = 'Blasting Caps', min = 3, max = 4, rarity = 'very-rare', chance = 15 },
            { item = 'nylon_webbing', label = 'Nylon Webbing', min = 2, max = 3, rarity = 'very-rare', chance = 10 },
            { blueprint = 'at_clip_drum_rifle',  label = 'Blueprint: Rifle Drum',    min = 1, max = 1, rarity = 'epic',      chance = 20 },
            { blueprint = 'WEAPON_CARBINERIFLE', label = 'Blueprint: Carbine Rifle', min = 1, max = 1, rarity = 'legendary', chance = 15 },
            { unlock = 'finish_diamond',         label = 'Diamond Weapon Finish',    min = 1, max = 1, rarity = 'mythic',    chance = 5 },
        },
    },
}

-- backwards compatibility
Config = config

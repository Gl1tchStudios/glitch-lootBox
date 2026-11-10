-- glitch-lootBox DEMO crates (server only: clients never download this file)
--
-- The key of each entry is the inventory item name of the crate. Every crate item must exist in
-- your inventory (see install/items.lua). Delete the crates you do not want, or add your own.
--
-- rewards     exactly one is rolled. `chance` is a weight: the weights do not need to add up to
--             100 and decimals are fine. min / max is the amount range.
-- bonusItems  always given on top of the reward. amount = number or { min = x, max = y }.
-- name        title on the preview screen (optional, falls back to the crate item label)
-- accent      colour of the case art on the preview screen (optional)
-- image       image url for the case art (optional, defaults to the crate item's inventory icon)
-- category    small label above the name on the preview screen (optional)
-- description one line under the name on the preview screen (optional)
-- label       reward label (optional, falls back to the inventory item label)
--
-- Optional reward fields for crafting and heist caches:
-- blueprint   glitch-crafting recipe id. The reward is a crafting_blueprint item for that recipe.
--             unlock = '<id>' works the same for glitch-crafting unlocks. Both are left out of the
--             roll (and the preview) while glitch-crafting is not running.
-- sources     { jobId = true }: the reward only exists in crates whose metadata.source is one of
--             these jobs. A crate without a source never rolls it.
-- weights     { jobId = 2.0 }: multiplies the reward's chance for crates from that job.
--
-- Rewards whose item does not exist in ox_inventory are left out of the roll, with one console
-- warning per crate at start.
--
-- DEMO PACK: the crates below are the ones the Glitch'd Roleplay demo server runs. Their rewards
-- use items from that server, so this pack is only loaded when config.server.cratePack is
-- 'demo' (or 'auto' on a server that runs glitch-economy). Copy what you want into crates.lua.
-- The chance of each reward follows its
-- rarity (common 24, uncommon 14, rare 8, very-rare 4.5, epic 2.2, legendary 0.9, mythic 0.25),
-- normalised so each crate adds up to 100.

config.demoLootBoxes = {
    ammocratet1 = {
        name = 'Munitions Crate T1',
        category = 'Munitions crate',
        description = 'Gun-making supplies. Ammo is crafted only, so these crates hold materials and plans, never rounds or cash.',
        accent = '#b0c3d9',
        rewards = {
            { item = 'metalscrap',     label = 'Scrap Metal',    min = 6, max = 12, rarity = 'common',   chance = 34.28 },
            { item = 'copper',         label = 'Copper',         min = 4, max = 8,  rarity = 'common',   chance = 34.29 },
            { item = 'gunpowder',      label = 'Gunpowder',      min = 2, max = 4,  rarity = 'uncommon', chance = 20 },
            { blueprint = 'ammo-9',    label = 'Blueprint: 9mm Rounds', min = 1, max = 1, rarity = 'rare', chance = 11.43 },
        },
        bonusItems = {
            { item = 'plastic', amount = 2, label = 'Plastic' },
        },
    },

    ammocratet2 = {
        name = 'Munitions Crate T2',
        category = 'Munitions crate',
        description = 'Gun-making supplies. Ammo is crafted only, so these crates hold materials and plans, never rounds or cash.',
        accent = '#4b69ff',
        rewards = {
            { item = 'copper',         label = 'Copper',         min = 8, max = 14, rarity = 'common',   chance = 47.53 },
            { item = 'gunpowder',      label = 'Gunpowder',      min = 4, max = 8,  rarity = 'uncommon', chance = 27.72 },
            { item = 'red_phosphorus', label = 'Red Phosphorus', min = 1, max = 2,  rarity = 'rare',     chance = 15.84 },
            { blueprint = 'ammo-shotgun', label = 'Blueprint: Shotgun Shells', min = 1, max = 1, rarity = 'very-rare', chance = 8.91 },
        },
        bonusItems = {
            { item = 'bandage', amount = 1, label = 'First Aid' },
        },
    },

    ammocratet3 = {
        name = 'Munitions Crate T3',
        category = 'Munitions crate',
        description = 'Gun-making supplies. Ammo is crafted only, so these crates hold materials and plans, never rounds or cash.',
        accent = '#d32ce6',
        rewards = {
            { item = 'gunpowder',      label = 'Gunpowder',      min = 8, max = 12, rarity = 'uncommon', chance = 45.02 },
            { item = 'steel',          label = 'Steel',          min = 4, max = 8,  rarity = 'uncommon', chance = 45.02 },
            { item = 'firearm_parts',  label = 'Firearm Parts',  min = 1, max = 1,  rarity = 'epic',     chance = 7.07 },
            { blueprint = 'ammo-rifle', label = 'Blueprint: Rifle Rounds', min = 1, max = 1, rarity = 'legendary', chance = 2.89 },
        },
        bonusItems = {
            { item = 'bandage',  amount = 2, label = 'Medical Supplies' },
            { item = 'lockpick', amount = 1, label = 'Tool Bonus' },
        },
    },

    -- ----------------------------------------------------------------------------
    -- Heist caches. Meant to be handed out by your robbery scripts (glitch-crafting
    -- does it through its CacheDrops config and writes the job into metadata.source).
    -- Blueprint rewards need glitch-crafting and are left out of the roll without it.
    -- ----------------------------------------------------------------------------

    -- Back Alley Bag: a tier below the Street Stash.
    cache_alley = {
        name = 'Back Alley Bag',
        category = 'Street find',
        accent = '#8a8f96',
        rewards = {
            { item = 'metalscrap',       label = 'Scrap Metal',       min = 4, max = 8, rarity = 'common',    chance = 14.22 },
            { item = 'plastic',          label = 'Plastic',           min = 4, max = 8, rarity = 'common',    chance = 11.86 },
            { item = 'glass',            label = 'Glass',             min = 2, max = 4, rarity = 'common',    chance = 11.86 },
            { item = 'cloth',            label = 'Cloth',             min = 1, max = 3, rarity = 'common',    chance = 4.74 },
            { item = 'bandage',         label = 'Bandages',          min = 1, max = 3, rarity = 'common',    chance = 14.23 },
            { blueprint = 'bandage',     label = 'Blueprint: Bandages', min = 1, max = 1, rarity = 'rare',      chance = 4.74 },
            { item = 'rubber',           label = 'Rubber',            min = 2, max = 4, rarity = 'uncommon',  chance = 8.3 },
            { item = 'copper',           label = 'Copper',            min = 3, max = 6, rarity = 'uncommon',  chance = 8.3 },
            { item = 'lockpick',         label = 'Lockpick',          min = 1, max = 2, rarity = 'uncommon',  chance = 8.3 },
            { item = 'steel',            label = 'Steel',             min = 2, max = 4, rarity = 'rare',      chance = 4.74 },
            { item = 'advancedlockpick', label = 'Advanced Lockpick', min = 1, max = 1, rarity = 'rare',      chance = 4.74 },
            { item = 'electronickit',    label = 'Electronic Kit',    min = 1, max = 1, rarity = 'very-rare', chance = 2.67 },
            { blueprint = 'ammo-9',      label = 'Blueprint: 9mm Rounds', min = 1, max = 1, rarity = 'epic', chance = 1.3 },
        },
    },
    cache_street = {
        name = 'Street Stash',
        category = 'Heist cache',
        accent = '#b0c3d9',
        rewards = {
            { item = 'metalscrap',         label = 'Scrap Metal',        min = 10, max = 20, rarity = 'common',    chance = 25.36 },
            { item = 'copper',             label = 'Copper',             min = 6,  max = 12, rarity = 'common',    chance = 22.62 },
            { item = 'aluminum',           label = 'Aluminum',           min = 4,  max = 8,  rarity = 'uncommon',  chance = 13.2 },
            { blueprint = 'trojan_usb',    label = 'Blueprint: Trojan USB',     min = 1, max = 1, rarity = 'rare',      chance = 7.54 },
            { blueprint = 'atm_hacker',    label = 'Blueprint: ATM Hacker',     min = 1, max = 1, rarity = 'rare',      chance = 7.54 },
            { blueprint = 'painkillers', label = 'Blueprint: Painkillers', min = 1, max = 1, rarity = 'rare',     chance = 7.54 },
            { blueprint = 'bproof',        label = 'Blueprint: Vest and plates', min = 1, max = 1, rarity = 'legendary', chance = 0.85 },
            { blueprint = 'at_suppressor_light', label = 'Blueprint: Pistol Suppressor', min = 1, max = 1, rarity = 'very-rare', chance = 1.5 },
            { item = 'industrial_diamond', label = 'Industrial Diamond', min = 1,  max = 1,  rarity = 'very-rare', chance = 4.24 },
            { blueprint = 'glass_cutter',  label = 'Blueprint: Glass Cutter',   min = 1, max = 1, rarity = 'epic',      chance = 2.07 },
            { blueprint = 'ammo-9',        label = 'Blueprint: 9mm Rounds',     min = 1, max = 1, rarity = 'rare',      chance = 7.54 },
        },
        bonusItems = {
            { item = 'plastic', amount = 3, label = 'Plastic' },
        },
    },

    cache_deposit = {
        name = 'Deposit Box',
        category = 'Heist cache',
        accent = '#4b69ff',
        rewards = {
            { item = 'steel',              label = 'Steel',              min = 6, max = 10, rarity = 'common',    chance = 20.59 },
            { item = 'aluminum',           label = 'Aluminum',           min = 8, max = 14, rarity = 'common',    chance = 20.6 },
            { item = 'military_circuit',   label = 'Military Circuit',   min = 1, max = 1,  rarity = 'uncommon',  chance = 12.02 },
            { item = 'blasting_cap',       label = 'Blasting Cap',       min = 1, max = 1,  rarity = 'uncommon',  chance = 12.02, weights = { armored_truck = 2.0 } },
            { item = 'industrial_diamond', label = 'Industrial Diamond', min = 1, max = 2,  rarity = 'rare',      chance = 6.87, weights = { paleto_bank = 2.0 } },
            { blueprint = 'at_scope_medium',     label = 'Blueprint: Medium Scope',   min = 1, max = 1, rarity = 'rare',      chance = 6.87 },
            { blueprint = 'hacking_laptop',      label = 'Blueprint: Hacking Laptop', min = 1, max = 1, rarity = 'very-rare', chance = 3.86 },
            { blueprint = 'thermite',            label = 'Blueprint: Thermite',       min = 1, max = 1, rarity = 'very-rare', chance = 3.86 },
            { blueprint = 'c4_charge',           label = 'Blueprint: C4 Charge',      min = 1, max = 1, rarity = 'epic',      chance = 1.89, weights = { armored_truck = 2.0 } },
            { blueprint = 'WEAPON_PUMPSHOTGUN',  label = 'Blueprint: Pump Shotgun',   min = 1, max = 1, rarity = 'epic',      chance = 1.89 },
            { blueprint = 'heavy_drill',         label = 'Blueprint: Heavy Drill',    min = 1, max = 1, rarity = 'epic',      chance = 1.89, weights = { paleto_bank = 2.0 } },
            { blueprint = 'military_thermite',   label = 'Blueprint: Military Thermite', min = 1, max = 1, rarity = 'legendary', chance = 0.77 },
            { blueprint = 'ammo-shotgun',        label = 'Blueprint: Shotgun Shells', min = 1, max = 1, rarity = 'rare',      chance = 6.87 },
        },
        bonusItems = {
            { item = 'copper_wire', amount = 4, label = 'Copper Wire' },
        },
    },

    cache_vault = {
        name = 'Vault Strongbox',
        category = 'Heist cache',
        accent = '#d32ce6',
        rewards = {
            { item = 'blasting_cap',       label = 'Blasting Cap',       min = 2, max = 3, rarity = 'uncommon',  chance = 21.6 },
            { item = 'military_circuit',   label = 'Military Circuit',   min = 2, max = 2, rarity = 'uncommon',  chance = 21.62 },
            { item = 'industrial_diamond', label = 'Industrial Diamond', min = 2, max = 2, rarity = 'rare',      chance = 12.36 },
            { item = 'filter_cartridge',   label = 'Filter Cartridge',   min = 2, max = 2, rarity = 'rare',      chance = 12.36 },
            { item = 'nylon_webbing',      label = 'Nylon Webbing',      min = 1, max = 2, rarity = 'very-rare', chance = 6.95,
              sources = { union_depository = true, yacht = true } },
            { blueprint = 'shaped_charge',      label = 'Blueprint: Shaped Charge', min = 1, max = 1, rarity = 'epic',      chance = 3.4 },
            { blueprint = 'hazmat_suit',        label = 'Blueprint: Hazmat Suit',   min = 1, max = 1, rarity = 'epic',      chance = 3.4 },
            { blueprint = 'WEAPON_MICROSMG',    label = 'Blueprint: Micro SMG',     min = 1, max = 1, rarity = 'epic',      chance = 3.4 },
            { blueprint = 'at_clip_drum_smg',   label = 'Blueprint: SMG Drum',      min = 1, max = 1, rarity = 'epic',      chance = 3.4 },
            { blueprint = 'WEAPON_SMG',         label = 'Blueprint: SMG',           min = 1, max = 1, rarity = 'legendary', chance = 1.39 },
            { blueprint = 'at_clip_drum_rifle', label = 'Blueprint: Rifle Drum',    min = 1, max = 1, rarity = 'legendary', chance = 1.39 },
            { blueprint = 'ammo-rifle',         label = 'Blueprint: Rifle Rounds',  min = 1, max = 1, rarity = 'very-rare', chance = 6.95 },
            { blueprint = 'WEAPON_CARBINERIFLE', label = 'Blueprint: Carbine Rifle', min = 1, max = 1, rarity = 'legendary', chance = 1.39,
              sources = { union_depository = true, yacht = true } },
            { blueprint = 'rappel_equipment',   label = 'Blueprint: Rappel Equipment', min = 1, max = 1, rarity = 'mythic', chance = 0.39,
              sources = { union_depository = true, yacht = true } },
        },
        bonusItems = {
            { item = 'steel', amount = 8, label = 'Steel' },
        },
    },

    cache_diamond = {
        name = 'Diamond Case',
        category = 'Heist cache',
        accent = '#e4ae39',
        rewards = {
            { item = 'diamond',       label = 'Diamonds',      min = 3, max = 6, rarity = 'rare',      chance = 39.32 },
            { item = 'blasting_cap',  label = 'Blasting Caps', min = 3, max = 4, rarity = 'very-rare', chance = 22.11 },
            { item = 'nylon_webbing', label = 'Nylon Webbing', min = 2, max = 3, rarity = 'very-rare', chance = 22.11 },
            { blueprint = 'at_clip_drum_rifle',  label = 'Blueprint: Rifle Drum',    min = 1, max = 1, rarity = 'epic',      chance = 10.81 },
            { blueprint = 'WEAPON_CARBINERIFLE', label = 'Blueprint: Carbine Rifle', min = 1, max = 1, rarity = 'legendary', chance = 4.42 },
            { unlock = 'finish_diamond',         label = 'Diamond Weapon Finish',    min = 1, max = 1, rarity = 'mythic',    chance = 1.23 },
        },
    },

    -- ----------------------------------------------------------------------------
    -- Blueprint cases. Every reward is a glitch-crafting blueprint, so these cases
    -- cannot be opened while glitch-crafting is not running (the player keeps the case).
    -- ----------------------------------------------------------------------------

    case_gun_blueprints = {
        name = 'Gun Blueprint Case',
        category = 'Blueprint case',
        description = 'One gun blueprint. Learn it to build that gun at a weapons bench.',
        accent = '#eb4b4b',
        rewards = {
            { blueprint = 'WEAPON_PUMPSHOTGUN',  label = 'Blueprint: Pump Shotgun',  min = 1, max = 1, rarity = 'very-rare', chance = 44.77 },
            { blueprint = 'WEAPON_MICROSMG',     label = 'Blueprint: Micro SMG',     min = 1, max = 1, rarity = 'epic',      chance = 21.89 },
            { blueprint = 'WEAPON_SMG',          label = 'Blueprint: SMG',           min = 1, max = 1, rarity = 'epic',      chance = 21.89 },
            { blueprint = 'WEAPON_CARBINERIFLE', label = 'Blueprint: Carbine Rifle', min = 1, max = 1, rarity = 'legendary', chance = 8.96 },
            { unlock = 'finish_diamond',         label = 'Diamond Weapon Finish',    min = 1, max = 1, rarity = 'mythic',    chance = 2.49 },
        },
    },

    case_attachment_blueprints = {
        name = 'Attachment Blueprint Case',
        category = 'Blueprint case',
        description = 'One attachment blueprint. Learn it to build that attachment at a weapons bench.',
        accent = '#8847ff',
        rewards = {
            { blueprint = 'at_grip',                 label = 'Blueprint: Grip',                min = 1, max = 1, rarity = 'common',    chance = 14.39 },
            { blueprint = 'at_flashlight',           label = 'Blueprint: Flashlight',          min = 1, max = 1, rarity = 'common',    chance = 14.37 },
            { blueprint = 'at_clip_extended_pistol', label = 'Blueprint: Extended Pistol Mag', min = 1, max = 1, rarity = 'common',    chance = 14.37 },
            { blueprint = 'at_scope_macro',          label = 'Blueprint: Macro Scope',         min = 1, max = 1, rarity = 'common',    chance = 14.37 },
            { blueprint = 'at_scope_holo',           label = 'Blueprint: Holo Sight',          min = 1, max = 1, rarity = 'uncommon',  chance = 8.38 },
            { blueprint = 'at_clip_extended_smg',    label = 'Blueprint: Extended SMG Mag',    min = 1, max = 1, rarity = 'uncommon',  chance = 8.38 },
            { blueprint = 'at_scope_small',          label = 'Blueprint: Small Scope',         min = 1, max = 1, rarity = 'uncommon',  chance = 8.38 },
            { blueprint = 'at_clip_extended_rifle',  label = 'Blueprint: Extended Rifle Mag',  min = 1, max = 1, rarity = 'rare',      chance = 4.79 },
            { blueprint = 'at_suppressor_light',     label = 'Blueprint: Pistol Suppressor',   min = 1, max = 1, rarity = 'rare',      chance = 4.79 },
            { blueprint = 'at_scope_medium',         label = 'Blueprint: Medium Scope',        min = 1, max = 1, rarity = 'very-rare', chance = 2.69 },
            { blueprint = 'at_barrel',               label = 'Blueprint: Heavy Barrel',        min = 1, max = 1, rarity = 'very-rare', chance = 2.69 },
            { blueprint = 'at_suppressor_heavy',     label = 'Blueprint: Rifle Suppressor',    min = 1, max = 1, rarity = 'epic',      chance = 1.32 },
            { blueprint = 'at_clip_drum_smg',        label = 'Blueprint: SMG Drum',            min = 1, max = 1, rarity = 'legendary', chance = 0.54 },
            { blueprint = 'at_clip_drum_rifle',      label = 'Blueprint: Rifle Drum',          min = 1, max = 1, rarity = 'legendary', chance = 0.54 },
        },
    },

    -- ----------------------------------------------------------------------------
    -- Trading card packs. One card per pack, parody names. glitch-cardAlbums adds
    -- albums for these cards and reads the odds through the GetDropRates export.
    -- ----------------------------------------------------------------------------

    soccer_card_pack = {
        name = 'Football Legends Pack',
        category = 'Trading cards',
        description = 'One card per pack. Duplicates stack in your inventory and can be traded or sold.',
        accent = '#2e7d32',
        rewards = {
            { item = 'card_fb_penaldo', label = 'Cristiano Penaldo', min = 1, max = 1, rarity = 'mythic', chance = 0.3 },
            { item = 'card_fb_messy', label = 'Lionel Messy', min = 1, max = 1, rarity = 'legendary', chance = 1.08 },
            { item = 'card_fb_neydive', label = 'Neydive Jr', min = 1, max = 1, rarity = 'legendary', chance = 1.08 },
            { item = 'card_fb_mbappay', label = 'Kylian Mbappay', min = 1, max = 1, rarity = 'epic', chance = 2.64 },
            { item = 'card_fb_haulland', label = 'Erling Haul-land', min = 1, max = 1, rarity = 'epic', chance = 2.64 },
            { item = 'card_fb_debruiser', label = 'Kevin De Bruiser', min = 1, max = 1, rarity = 'very-rare', chance = 5.39 },
            { item = 'card_fb_salad', label = 'Mo Salad', min = 1, max = 1, rarity = 'very-rare', chance = 5.39 },
            { item = 'card_fb_vinny', label = 'Vinny Juniorr', min = 1, max = 1, rarity = 'rare', chance = 9.59 },
            { item = 'card_fb_kaneless', label = 'Harry Kaneless', min = 1, max = 1, rarity = 'rare', chance = 9.59 },
            { item = 'card_fb_bellingum', label = 'Jude Bellingum', min = 1, max = 1, rarity = 'uncommon', chance = 16.78 },
            { item = 'card_fb_modrip', label = 'Luka Modrip', min = 1, max = 1, rarity = 'uncommon', chance = 16.78 },
            { item = 'card_fb_gary', label = 'Sunday League Gary', min = 1, max = 1, rarity = 'common', chance = 28.74 },
        },
    },

    basketball_card_pack = {
        name = 'Hoops Stars Pack',
        category = 'Trading cards',
        description = 'One card per pack. Duplicates stack in your inventory and can be traded or sold.',
        accent = '#e65100',
        rewards = {
            { item = 'card_bb_jorgan', label = 'Michael Jorgan', min = 1, max = 1, rarity = 'mythic', chance = 0.3 },
            { item = 'card_bb_lebrick', label = 'LeBrick James', min = 1, max = 1, rarity = 'legendary', chance = 1.08 },
            { item = 'card_bb_hurry', label = 'Steph Hurry', min = 1, max = 1, rarity = 'legendary', chance = 1.08 },
            { item = 'card_bb_durantula', label = 'Kevin Durantula', min = 1, max = 1, rarity = 'epic', chance = 2.64 },
            { item = 'card_bb_antetokounbro', label = 'Giannis Antetokounbro', min = 1, max = 1, rarity = 'epic', chance = 2.64 },
            { item = 'card_bb_jokestar', label = 'Nikola Jokestar', min = 1, max = 1, rarity = 'very-rare', chance = 5.39 },
            { item = 'card_bb_doncheese', label = 'Luka Doncheese', min = 1, max = 1, rarity = 'very-rare', chance = 5.39 },
            { item = 'card_bb_wembanyamama', label = 'Victor Wembanyamama', min = 1, max = 1, rarity = 'rare', chance = 9.59 },
            { item = 'card_bb_shaqmeal', label = 'Shaq O\'Meal', min = 1, max = 1, rarity = 'rare', chance = 9.59 },
            { item = 'card_bb_eyebrows', label = 'Anthony Eyebrows', min = 1, max = 1, rarity = 'uncommon', chance = 16.78 },
            { item = 'card_bb_lillardo', label = 'Dame Lillardo', min = 1, max = 1, rarity = 'uncommon', chance = 16.78 },
            { item = 'card_bb_airball', label = 'Airball Al', min = 1, max = 1, rarity = 'common', chance = 28.74 },
        },
    },

    los_santos_card_pack = {
        name = 'Faces of Sydney',
        category = 'Trading cards',
        description = 'One card of the locals of the city per pack. Collect all twelve in the Faces of Sydney booklet.',
        accent = '#9a6fe3',
        rewards = {
            { item = 'card_ls_franklin', label = 'Franklin Clinton', min = 1, max = 1, rarity = 'mythic', chance = 0.3 },
            { item = 'card_ls_trevor', label = 'Trevor Philips', min = 1, max = 1, rarity = 'legendary', chance = 1.08 },
            { item = 'card_ls_michael', label = 'Michael De Santa', min = 1, max = 1, rarity = 'legendary', chance = 1.08 },
            { item = 'card_ls_lamar', label = 'Lamar Davis', min = 1, max = 1, rarity = 'epic', chance = 2.64 },
            { item = 'card_ls_lester', label = 'Lester Crest', min = 1, max = 1, rarity = 'epic', chance = 2.64 },
            { item = 'card_ls_ron', label = 'Ron Jakowski', min = 1, max = 1, rarity = 'very-rare', chance = 5.39 },
            { item = 'card_ls_dave', label = 'Dave Norton', min = 1, max = 1, rarity = 'very-rare', chance = 5.39 },
            { item = 'card_ls_steve', label = 'Steve Haines', min = 1, max = 1, rarity = 'rare', chance = 9.59 },
            { item = 'card_ls_amanda', label = 'Amanda De Santa', min = 1, max = 1, rarity = 'rare', chance = 9.59 },
            { item = 'card_ls_jimmy', label = 'Jimmy De Santa', min = 1, max = 1, rarity = 'uncommon', chance = 16.78 },
            { item = 'card_ls_tracey', label = 'Tracey De Santa', min = 1, max = 1, rarity = 'uncommon', chance = 16.78 },
            { item = 'card_ls_wade', label = 'Wade Hebert', min = 1, max = 1, rarity = 'common', chance = 28.74 },
        },
    },

    -- Blind box figures and a sneaker box (parody names)
    figure_blind_box = {
        name = 'Pop Pals Blind Box',
        category = 'Collectible',
        accent = '#ffb300',
        rewards = {
            { item = 'figure_zombie_chef', label = 'Zombie Chef', min = 1, max = 1, rarity = 'common', chance = 26.13 },
            { item = 'figure_space_ranger', label = 'Space Ranger', min = 1, max = 1, rarity = 'common', chance = 26.13 },
            { item = 'figure_disco_yeti', label = 'Disco Yeti', min = 1, max = 1, rarity = 'uncommon', chance = 15.24 },
            { item = 'figure_sad_robot', label = 'Sad Robot', min = 1, max = 1, rarity = 'uncommon', chance = 15.24 },
            { item = 'figure_ninja_cat', label = 'Ninja Cat', min = 1, max = 1, rarity = 'rare', chance = 8.71 },
            { item = 'figure_robo_pup', label = 'Robo Pup', min = 1, max = 1, rarity = 'very-rare', chance = 4.9 },
            { item = 'figure_wizard_gran', label = 'Wizard Gran', min = 1, max = 1, rarity = 'epic', chance = 2.4 },
            { item = 'figure_pirate_captain', label = 'Pirate Captain', min = 1, max = 1, rarity = 'legendary', chance = 0.98 },
            { item = 'figure_golden_gorilla', label = 'Golden Gorilla (Chase)', min = 1, max = 1, rarity = 'mythic', chance = 0.27 },
        },
    },

    sneaker_box = {
        name = 'Sneaker Box',
        category = 'Collectible',
        accent = '#ff6d00',
        rewards = {
            { item = 'stolen_shoes', label = 'Designer Trainers', min = 1, max = 1, rarity = 'common', chance = 44.56 },
            { item = 'kicks_dunks_panda', label = 'Dunks Lo \'Panda\'', min = 1, max = 1, rarity = 'uncommon', chance = 26 },
            { item = 'kicks_yeezo_350', label = 'Yeezo Boost 350', min = 1, max = 1, rarity = 'rare', chance = 14.86 },
            { item = 'kicks_jorgan_chicago', label = 'Air Jorgan 1 \'Chicago\'', min = 1, max = 1, rarity = 'very-rare', chance = 8.36 },
            { item = 'kicks_reverse_mocha', label = 'Reverse Mocha Lows', min = 1, max = 1, rarity = 'epic', chance = 4.09 },
            { item = 'kicks_hoverboard_highs', label = 'Hoverboard Highs 2015', min = 1, max = 1, rarity = 'legendary', chance = 1.67 },
            { item = 'kicks_golden_one', label = 'Golden Kicks (1 of 1)', min = 1, max = 1, rarity = 'mythic', chance = 0.46 },
        },
    },
}

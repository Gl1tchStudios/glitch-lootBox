-- glitch-lootBox crates (server only: clients never download this file)
--
-- Default pack: three crates that only hand out stock ox_inventory items, so it works on a fresh
-- server. config/crates.demo.lua holds the larger set from the demo server (card packs, figures,
-- blueprints) as a reference; see config.server.cratePack in config/server.lua.
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
-- rarity      a key of config.rarities in config/main.lua
--
-- Optional reward fields: blueprint / unlock (glitch-crafting), sources, weights. See
-- config/crates.demo.lua for examples.
--
-- Rewards whose item does not exist in ox_inventory are left out of the roll, with one console
-- warning per crate at start.

config.lootBoxes = {
    cache_alley = {
        name = 'Back Alley Bag',
        category = 'Street cache',
        description = 'A taped-up bag somebody stashed.',
        accent = '#b0c3d9',
        rewards = {
            { item = 'water',    label = 'Water',    min = 1, max = 3, rarity = 'common',   chance = 35 },
            { item = 'burger',   label = 'Burger',   min = 1, max = 2, rarity = 'common',   chance = 30 },
            { item = 'bandage',  label = 'Bandages', min = 1, max = 3, rarity = 'uncommon', chance = 20 },
            { item = 'lockpick', label = 'Lockpick', min = 1, max = 2, rarity = 'rare',     chance = 12 },
            { item = 'money',    label = 'Cash',     min = 200, max = 600, rarity = 'very-rare', chance = 3 },
        },
    },
    cache_street = {
        name = 'Street Stash',
        category = 'Street cache',
        description = 'A sealed bag from a back room.',
        accent = '#5e98d9',
        rewards = {
            { item = 'bandage',  label = 'Bandages', min = 2, max = 4, rarity = 'common',    chance = 34 },
            { item = 'lockpick', label = 'Lockpick', min = 1, max = 3, rarity = 'uncommon',  chance = 30 },
            { item = 'radio',    label = 'Radio',    min = 1, max = 1, rarity = 'rare',      chance = 18 },
            { item = 'money',    label = 'Cash',     min = 500, max = 1500, rarity = 'very-rare', chance = 14 },
            { item = 'armour',   label = 'Body Armour', min = 1, max = 1, rarity = 'epic',   chance = 4 },
        },
        bonusItems = {
            { item = 'water', amount = 1, label = 'Water' },
        },
    },
    cache_deposit = {
        name = 'Deposit Box',
        category = 'Vault cache',
        description = 'A locked deposit box.',
        accent = '#8847ff',
        rewards = {
            { item = 'money',    label = 'Cash',        min = 1000, max = 2500, rarity = 'uncommon', chance = 40 },
            { item = 'lockpick', label = 'Lockpick',    min = 2, max = 4, rarity = 'uncommon',  chance = 25 },
            { item = 'phone',    label = 'Phone',       min = 1, max = 1, rarity = 'rare',      chance = 20 },
            { item = 'armour',   label = 'Body Armour', min = 1, max = 1, rarity = 'very-rare', chance = 12 },
            { item = 'money',    label = 'Big Cash',    min = 4000, max = 8000, rarity = 'legendary', chance = 3 },
        },
    },
}

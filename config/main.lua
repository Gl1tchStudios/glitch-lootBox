-- glitch-lootBox shared settings (server and client).
-- The crates themselves are in config/crates.lua and the server-only settings in config/server.lua.

config = config or {}

config.debug  = false -- print every roll and payout to the server console
config.useUI  = true  -- false = crates open instantly with a notification, no UI
config.locale = 'en'  -- a file in locales/

-- --------------------------------------------------------------------
-- UI
-- --------------------------------------------------------------------

config.ui = {
    showPreview    = true,  -- CS2 "Unlock Container" screen (contents + odds) before the reel spins
    showChances    = true,  -- show drop odds on the preview screen
    spinTime       = 6.5,   -- seconds the reel spins before it settles
    reelLength     = 56,    -- cards on the reel
    winnerIndex    = 48,    -- card (1-based) the reel lands on; keep it at least 4 below reelLength
    allowSkip      = true,  -- SPACE / ESC skips straight to the reveal
    volume         = 0.5,   -- reel tick volume, 0 to mute (the reveal uses GTA frontend sounds)
    blurBackground = true,  -- blur the world behind the UI

    inventory = {
        -- Item images. With ox_inventory the item's own image (client.image) is used first.
        -- iconPath false = the ox_inventory image folder: the `inventory:imagepath` convar,
        -- or nui://ox_inventory/web/images/ when it is not set. Or give a url ending in '/'.
        iconPath      = false,
        iconExtension = '.png',
        iconOverrides = {
            -- ['item_name'] = 'https://example.com/item_name.png',
        },
        fallbackIcon  = false, -- image url for items without an icon (false = built-in placeholder)
    },
}

-- --------------------------------------------------------------------
-- Rarities
-- --------------------------------------------------------------------
-- Keys are what the crates use in `rarity = '...'`.
-- order   : higher = rarer (sorting; 6 and up get sparkles on the reveal)
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

config.lootBoxes = config.lootBoxes or {}

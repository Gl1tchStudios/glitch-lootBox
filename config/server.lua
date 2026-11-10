-- glitch-lootBox server-only settings.

config.server = {
    -- Seconds the server waits for the reveal before it pays out a rolled crate anyway
    -- (on top of ui.spinTime).
    revealGrace = 25,

    -- Seconds between two crate requests from the same player.
    throttle = { use = 0.5, again = 0.6 },

    -- A player who is dead, in last stand or cuffed cannot open crates (Qbox / QBCore metadata).
    blockWhenIncapacitated = true,

    -- Rolled loot that could not be handed over (the player disconnected or switched character
    -- mid-spin, the inventory was full with nowhere to drop it, or the server went down) is kept
    -- in the resource KVP store and handed over the next time that character loads in.
    -- How long (seconds) to wait after the character loads before trying, and how many tries.
    pendingDelay = 5,
    pendingTries = 10,

    -- Which crate set to load: 'generic' (config/crates.lua, stock ox_inventory items only),
    -- 'demo' (config/crates.demo.lua, the Glitch'd Roleplay set) or 'auto' (demo when
    -- glitch-economy is installed, generic otherwise).
    cratePack = 'auto',
}

-- Optional integrations with other Glitch Studios resources. Each one is skipped when its
-- resource is not running.
config.integrations = {
    -- At start, warn in the console about any card in a crate of this category that the
    -- glitch-criminaltablet pawn counter would not buy. Example:
    -- pawnCheck = { resource = 'glitch-criminaltablet', category = 'Trading cards' }
    pawnCheck = false,
}

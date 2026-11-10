Locales = Locales or {}

-- Player-facing text. Copy this file to add a language, then set config.locale.
-- Keys starting with ui_ are sent to the crate screen.
Locales.en = {
    -- notifications
    title              = 'Crate',
    unknown_crate      = 'Unknown crate.',
    no_crate           = "You don't have a %s.",
    no_room            = 'Make some room in your inventory before opening this.',
    open_failed        = 'Could not open the crate.',
    nothing_inside     = 'This crate cannot be opened right now.',
    already_opening    = 'You are already opening a crate.',
    incapacitated      = 'You cannot open a crate right now.',
    received           = 'You received %s',
    inv_full_dropped   = 'Your inventory was full, the rest of the crate was dropped at your feet.',
    inv_full_kept      = 'Your inventory was full. The rest of the crate is kept for you and handed over next time you load in.',
    pending_delivered  = 'Loot from a crate you opened earlier was added to your inventory.',
    screen_failed      = 'The crate screen failed to load.',

    -- crate screen
    ui_container       = 'Container',
    ui_default_desc    = 'You get one of these. Odds are per open.',
    ui_possible        = 'Possible drops',
    ui_you_have        = 'You have',
    ui_rarest          = 'Rarest drop',
    ui_top_grade       = 'Top grade',
    ui_in_inventory    = 'In your inventory: ',
    ui_close           = 'Close',
    ui_open            = 'Open',
    ui_opening         = 'Opening',
    ui_skip            = 'Skip',
    ui_open_another    = 'Open another',
    ui_open_another_n  = 'Open another (%s)',
    ui_secret          = 'Secret item',
    ui_also_found      = 'Also found',
    ui_always_included = 'Always included',
    ui_always          = 'Always',
    ui_one_in          = '1 in %s',
    ui_adding          = 'Adding to your inventory...',
    ui_added           = 'Added to your inventory',
    ui_full_dropped    = 'Inventory full - dropped at your feet',
    ui_full_kept       = 'Inventory full - kept for your next login',
}

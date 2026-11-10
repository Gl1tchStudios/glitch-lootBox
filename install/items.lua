-- glitch-lootBox: crate items for ox_inventory.
-- Paste these into ox_inventory/data/items.lua. One entry per crate in config/crates.lua.
-- Do not add client.export or server.export: crates are used through the framework.
-- The items the crates hand out (metalscrap, card_*, figure_*, ...) belong to the demo
-- server. Rewards whose item does not exist are left out of the roll, so either add those
-- items too or edit config/crates.lua to hand out your own.

return {
    ['ammocratet1'] = { label = 'Munitions Crate T1', weight = 2000, stack = true, close = true, description = 'Gun-making supplies. Open it to see what is inside.' },
    ['ammocratet2'] = { label = 'Munitions Crate T2', weight = 3000, stack = true, close = true, description = 'Gun-making supplies. Open it to see what is inside.' },
    ['ammocratet3'] = { label = 'Munitions Crate T3', weight = 4000, stack = true, close = true, description = 'Gun-making supplies. Open it to see what is inside.' },
    ['cache_alley'] = { label = 'Back Alley Bag', weight = 1000, close = true, description = 'A taped-up bag somebody stashed. Open it to see what is inside.' },
    ['cache_street'] = { label = 'Street Stash', weight = 1500, close = true, description = 'A sealed bag from a back room. Open it to see what is inside.' },
    ['cache_deposit'] = { label = 'Deposit Box', weight = 2500, close = true, description = 'A locked deposit box. Open it to see what is inside.' },
    ['cache_vault'] = { label = 'Vault Strongbox', weight = 4000, close = true, description = 'A strongbox from a vault. Open it to see what is inside.' },
    ['cache_diamond'] = { label = 'Diamond Case', weight = 3000, close = true, description = 'A case from a diamond vault. Open it to see what is inside.' },
    ['case_gun_blueprints'] = { label = 'Gun Blueprint Case', weight = 2000, close = true, description = 'A sealed case of gun plans. Open it for one blueprint.' },
    ['case_attachment_blueprints'] = { label = 'Attachment Blueprint Case', weight = 1500, close = true, description = 'A sealed case of attachment plans. Open it for one blueprint.' },
    ['soccer_card_pack'] = { label = 'Football Legends Pack', weight = 40, close = true, description = 'A sealed pack of football trading cards. One card inside.' },
    ['basketball_card_pack'] = { label = 'Hoops Stars Pack', weight = 40, close = true, description = 'A sealed pack of basketball trading cards. One card inside.' },
    ['los_santos_card_pack'] = { label = 'Celebrity Faces Pack', weight = 40, close = true, description = 'A sealed pack of trading cards. One card inside.' },
    ['figure_blind_box'] = { label = 'Pop Pals Blind Box', weight = 300, close = true, description = 'A sealed blind box. One vinyl figure inside.' },
    ['sneaker_box'] = { label = 'Sneaker Box', weight = 1500, close = true, description = 'A shoebox from the back of a wardrobe. Open it to see what is inside.' },
}

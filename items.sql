-- Example SQL for adding ammo crate items to your database
-- Adjust table name and structure according to your framework

-- For ESX (items table)
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('ammocratet1', 'Tier 1 Ammo Crate', 5, 0, 1),
('ammocratet2', 'Tier 2 Ammo Crate', 8, 0, 1),
('ammocratet3', 'Tier 3 Ammo Crate', 12, 0, 1),
('militarycrate', 'Military Supply Crate', 15, 0, 1),
('policecrate', 'Police Supply Crate', 10, 0, 1),
('civilianbox', 'Civilian Ammo Box', 3, 0, 1),
('holidaycrate', 'Holiday Special Crate', 20, 0, 1);

-- For QBCore (qb-core/shared/items.lua)
-- Add these to your items.lua file:
--[[
-- Main Crates
['ammocratet1'] = {
    ['name'] = 'ammocratet1',
    ['label'] = 'Tier 1 Ammo Crate',
    ['weight'] = 5000,
    ['type'] = 'item',
    ['image'] = 'ammocratet1.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'A basic ammo supply crate containing various ammunition types.'
},
['ammocratet2'] = {
    ['name'] = 'ammocratet2',
    ['label'] = 'Tier 2 Ammo Crate',
    ['weight'] = 8000,
    ['type'] = 'item',
    ['image'] = 'ammocratet2.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'An advanced ammo supply crate with guaranteed shotgun shells and chance for pistol or rifle ammo.'
},
['ammocratet3'] = {
    ['name'] = 'ammocratet3',
    ['label'] = 'Tier 3 Ammo Crate',
    ['weight'] = 12000,
    ['type'] = 'item',
    ['image'] = 'ammocratet3.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'A premium ammo supply crate guaranteed to contain rifle ammunition with bonus pistol ammo chance.'
},

-- Alternative Crates
['militarycrate'] = {
    ['name'] = 'militarycrate',
    ['label'] = 'Military Supply Crate',
    ['weight'] = 15000,
    ['type'] = 'item',
    ['image'] = 'militarycrate.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'High-grade military ammunition supplies with guaranteed rifle ammo and bonus pistol rounds.'
},
['policecrate'] = {
    ['name'] = 'policecrate',
    ['label'] = 'Police Supply Crate',
    ['weight'] = 10000,
    ['type'] = 'item',
    ['image'] = 'policecrate.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Standard police ammunition supplies containing pistol and shotgun rounds.'
},
['civilianbox'] = {
    ['name'] = 'civilianbox',
    ['label'] = 'Civilian Ammo Box',
    ['weight'] = 3000,
    ['type'] = 'item',
    ['image'] = 'civilianbox.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Basic civilian ammunition box with limited supplies.'
},
['holidaycrate'] = {
    ['name'] = 'holidaycrate',
    ['label'] = 'Holiday Special Crate',
    ['weight'] = 20000,
    ['type'] = 'item',
    ['image'] = 'holidaycrate.png',
    ['unique'] = false,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Limited time holiday ammunition crate containing massive amounts of all ammo types.'
}
--]]

-- Make sure these ammo types also exist in your items:
-- ammo-9, ammo-50, ammo-rifle, ammo-rifle2, ammo-shotgun

-- Example ammo items (adjust according to your server's ammo system):
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('ammo-9', '9mm Ammo', 0.1, 0, 1),
('ammo-50', '.50 Cal Ammo', 0.2, 0, 1),
('ammo-rifle', 'Rifle Ammo', 0.15, 0, 1),
('ammo-rifle2', 'Advanced Rifle Ammo', 0.15, 0, 1),
('ammo-shotgun', 'Shotgun Shells', 0.2, 0, 1);

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'glitch-lootBox'
author 'Glitch Studios'
description 'CS2 style loot crates: server-rolled rewards with an animated case opening screen'
version '3.1.2'

-- Required: a framework (qbx_core, qb-core or es_extended), ox_inventory and ox_lib (notify fallback).
-- Optional, all checked at run time: glitch-crafting (blueprint rewards), glitch-abstraction
-- (inventory fallback), glitch-criminaltablet (pawn check), glitch-cardAlbums (reads the pack odds).
-- See README.md.
dependencies {
    'ox_inventory',
    'ox_lib',
}

shared_scripts {
    'locales/*.lua',
    'config/main.lua',
    'shared/locale.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    'config/crates.lua',
    'config/crates.demo.lua',
    'config/server.lua',
    'server/server.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/fonts/*.woff2',
}

escrow_ignore {
    'config/*',
    'locales/*',
    'install/*',
    'README.md',
    'LICENSE',
    'CHANGELOG.md',
}

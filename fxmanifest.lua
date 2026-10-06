fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Luma in collaboration with Glitch Studios'
description 'CS2 style loot crates: server-rolled rewards with an animated case opening UI'
version '3.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- glitch-abstraction is optional now (notifications + non-ox inventory fallback),
-- so it is no longer a hard dependency.

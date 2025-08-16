fx_version 'cerulean'
game 'gta5'

author 'Glitch Studios'
description 'Simple loot box system like csgo crates with animated UI'
version '2.0.0'

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

dependencies {
    'glitch-abstraction'
}

lua54 'yes'

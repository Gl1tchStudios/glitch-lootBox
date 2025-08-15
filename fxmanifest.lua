fx_version 'cerulean'
game 'gta5'

author 'Glitch Studios'
description 'Simple loot box system like csgo crates'
version '1.0.0'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

dependencies {
    'glitch-abstraction'
}

lua54 'yes'

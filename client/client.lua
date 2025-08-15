local GlitchLib = nil

local function debugPrint(message)
    if config.debug then
        print(message)
    end
end

Citizen.CreateThread(function()
    while GetResourceState('glitch-abstraction') ~= 'started' do
        Citizen.Wait(100)
    end
    
    Citizen.Wait(1000)
    
    GlitchLib = exports['glitch-abstraction']:getAbstraction()
    
    while not GlitchLib.IsReady do 
        Citizen.Wait(100) 
    end
    
    debugPrint('^2[loot-box] client loaded^7')
end)

RegisterNetEvent('lootbox:showReward', function(item, amount)
    if GlitchLib and GlitchLib.Notifications then
        GlitchLib.Notifications.Success('Loot Box Opened!', 'You got ' .. amount .. 'x ' .. item, 4000)
    end
    
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

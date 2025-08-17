local GlitchLib = nil
local isUIOpen = false
local currentSpinnerItems = {}
local currentReward = nil

local function debugPrint(message) -- debug messages when enabled
    if config.debug then
        print(message)
    end
end

local function forceCloseUI() -- force close ui and fix mouse cursor
    if not isUIOpen then
        return
    end
    
    isUIOpen = false
    currentReward = nil
    currentSpinnerItems = {}
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    Citizen.SetTimeout(50, function()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)
    
    Citizen.SetTimeout(100, function()
        SetNuiFocus(false, false)
    end)
    
    SendNUIMessage({type = 'forceClose'})
end

Citizen.CreateThread(function() -- wait for glitch abstraction to load
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

RegisterNetEvent('glitch-lootBox:client:openUI', function(spinnerItems, selectedReward) -- open loot box ui
    if isUIOpen then 
        return 
    end
    
    currentSpinnerItems = spinnerItems
    currentReward = selectedReward
    isUIOpen = true
    
    Citizen.SetTimeout(100, function()
        SetNuiFocus(true, true)
        
        SendNUIMessage({
            type = 'openLootBox',
            spinnerItems = spinnerItems,
            selectedReward = selectedReward
        })
    end)
    
    Citizen.SetTimeout(30000, function()
        if isUIOpen then
            forceCloseUI()
        end
    end)
end)

RegisterNUICallback('collectReward', function(data, cb) -- collect reward from ui
    TriggerServerEvent('glitch-lootBox:server:collectReward', data.actualWinner)
    forceCloseUI()
    cb('ok')
end)

RegisterNUICallback('forceCloseUI', function(data, cb) -- force close ui callback
    cb('ok')
    
    if isUIOpen then
        forceCloseUI()
    end
end)

RegisterNUICallback('requestConfig', function(data, cb) -- send config to ui
    debugPrint('^3[loot-box] Config requested by UI^7')
    
    SendNUIMessage({
        type = 'updateConfig',
        config = config
    })
    
    cb('ok')
end)

RegisterNUICallback('playSound', function(data, cb) -- play sound based on rarity
    local soundName = 'PICK_UP'
    local soundSet = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    
    if data.rarity == 'mythic' then
        soundName = 'MEDAL_UP'
        soundSet = 'HUD_MINI_GAME_SOUNDSET'
    elseif data.rarity == 'legendary' then
        soundName = 'CHALLENGE_UNLOCKED' 
        soundSet = 'HUD_AWARDS'
    elseif data.rarity == 'epic' then
        soundName = 'WEAPON_PURCHASE'
        soundSet = 'HUD_AMMO_SHOP_SOUNDSET'
    elseif data.rarity == 'rare' then
        soundName = 'NAV_UP_DOWN'
        soundSet = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    end
    
    PlaySoundFrontend(-1, soundName, soundSet, true)
    cb('ok')
end)

RegisterNetEvent('glitch-lootBox:client:rewardCollected', function(success) -- handle reward collection result
    if success then
        PlaySoundFrontend(-1, 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET', true)
    else
        PlaySoundFrontend(-1, 'CANCEL', 'HUD_FREEMODE_SOUNDSET', true)
        
        if GlitchLib and GlitchLib.Notifications then
            GlitchLib.Notifications.Error('Loot Box Error', 'Failed to collect reward. Please try again.', 3000)
        end
    end
    
    -- Ensure UI is closed
    if isUIOpen then
        forceCloseUI()
    end
end)

RegisterNetEvent('glitch-lootBox:client:showReward', function(item, amount) -- show basic reward notification
    if GlitchLib and GlitchLib.Notifications then
        GlitchLib.Notifications.Success('Loot Box Opened!', 'You got ' .. amount .. 'x ' .. item, 4000)
    end
    
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

RegisterNetEvent('glitch-lootBox:client:showBonusReward', function(item, amount, label) -- show bonus reward notification
    if GlitchLib and GlitchLib.Notifications then
        GlitchLib.Notifications.Info('Bonus Item!', 'You received: ' .. amount .. 'x ' .. label, 3000)
    end
    
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

RegisterNetEvent('glitch-lootBox:client:showRewardBox', function(item, amount, rarity, label) -- show csgo style reward notification
    if GlitchLib and GlitchLib.Notifications then
        local rarityColor = ''
        local rarityText = rarity:upper()
        if rarity == 'mythic' then
            rarityColor = '~r~' -- red
        elseif rarity == 'legendary' then
            rarityColor = '~o~' -- orange
        elseif rarity == 'epic' then
            rarityColor = '~p~' -- purple
        elseif rarity == 'rare' then
            rarityColor = '~b~' -- blue
        elseif rarity == 'uncommon' then
            rarityColor = '~g~' -- green
        else
            rarityColor = '~w~' -- white for common
        end
        
        local title = 'Crate Opened!'
        local message = 'You received: ' .. rarityColor .. label .. ' (' .. rarityText .. ')'

        GlitchLib.Notifications.Success(title, message, 5000)
    end
    
    local soundName = 'PICK_UP'
    local soundSet = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    
    if rarity == 'mythic' then
        soundName = 'MEDAL_UP'
        soundSet = 'HUD_MINI_GAME_SOUNDSET'
    elseif rarity == 'legendary' then
        soundName = 'CHALLENGE_UNLOCKED' 
        soundSet = 'HUD_AWARDS'
    elseif rarity == 'epic' then
        soundName = 'WEAPON_PURCHASE'
        soundSet = 'HUD_AMMO_SHOP_SOUNDSET'
    end
    
    PlaySoundFrontend(-1, soundName, soundSet, true)
end)

Citizen.CreateThread(function() -- handle escape key to close ui
    while true do
        Citizen.Wait(100)
        
        if isUIOpen then
            if IsControlJustPressed(0, 322) then
                forceCloseUI()
            end
            
            if IsControlJustPressed(0, 177) then
                forceCloseUI()
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

Citizen.CreateThread(function() -- monitor nui focus in background
    while true do
        Citizen.Wait(500)
        
        if isUIOpen then
            if not IsNuiFocused() then
                isUIOpen = false
                currentReward = nil
                currentSpinnerItems = {}
            end
        end
    end
end)

RegisterNetEvent('glitch-lootBox:client:notify', function(message, type) -- general notification handler
    if GlitchLib and GlitchLib.Notifications then
        if type == 'success' then
            GlitchLib.Notifications.Notify(message, 'success', 5000)
        elseif type == 'error' then
            GlitchLib.Notifications.Notify(message, 'error', 5000)
        else
            GlitchLib.Notifications.Notify(message, 'info', 5000)
        end
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end)

AddEventHandler('onResourceStop', function(resourceName) -- cleanup when resource stops
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then
            SetNuiFocus(false, false)
            isUIOpen = false
        end
    end
end)
local GlitchLib = nil
local isUIOpen = false
local currentSpinnerItems = {}
local currentReward = nil

local function debugPrint(message)
    if config.debug then
        print(message)
    end
end

-- Enhanced force close with mouse cursor fixes
local function forceCloseUI()
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

RegisterNetEvent('glitch-lootBox:openUI', function(spinnerItems, selectedReward)
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

RegisterNUICallback('collectReward', function(data, cb)
    TriggerServerEvent('glitch-lootBox:collectReward', data.actualWinner)
    forceCloseUI()
    cb('ok')
end)

RegisterNUICallback('forceCloseUI', function(data, cb)
    cb('ok')
    
    if isUIOpen then
        forceCloseUI()
    end
end)

RegisterNUICallback('requestConfig', function(data, cb)
    debugPrint('^3[loot-box] Config requested by UI^7')
    
    -- Send config to NUI
    SendNUIMessage({
        type = 'updateConfig',
        config = config
    })
    
    cb('ok')
end)

RegisterNUICallback('playSound', function(data, cb)
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

RegisterNetEvent('glitch-lootBox:rewardCollected', function(success)
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

RegisterNetEvent('lootbox:showReward', function(item, amount)
    if GlitchLib and GlitchLib.Notifications then
        GlitchLib.Notifications.Success('Loot Box Opened!', 'You got ' .. amount .. 'x ' .. item, 4000)
    end
    
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

RegisterNetEvent('lootbox:showBonusReward', function(item, amount, label)
    if GlitchLib and GlitchLib.Notifications then
        GlitchLib.Notifications.Info('Bonus Item!', 'You received: ' .. amount .. 'x ' .. label, 3000)
    end
    
    PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

RegisterNetEvent('lootbox:showRewardBox', function(item, amount, rarity, label)
    if GlitchLib and GlitchLib.Notifications then
        local rarityColor = ''
        local rarityText = rarity:upper()
        if rarity == 'mythic' then
            rarityColor = '~r~' -- Red
        elseif rarity == 'legendary' then
            rarityColor = '~o~' -- Orange
        elseif rarity == 'epic' then
            rarityColor = '~p~' -- Purple
        elseif rarity == 'rare' then
            rarityColor = '~b~' -- Blue
        elseif rarity == 'uncommon' then
            rarityColor = '~g~' -- Green
        else
            rarityColor = '~w~' -- White for common
        end
        
        local title = 'Ammo Crate Opened!'
        local message = 'You received: ' .. rarityColor .. label .. '~w~ (' .. rarityColor .. rarityText .. '~w~)'
        
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

Citizen.CreateThread(function()
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
            Citizen.Wait(1000) -- Reduce load when not needed
        end
    end
end)

-- Background mouse monitor thread
Citizen.CreateThread(function()
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

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then
            SetNuiFocus(false, false)
            isUIOpen = false
        end
    end
end)
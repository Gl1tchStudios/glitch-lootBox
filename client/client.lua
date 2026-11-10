-- glitch-lootBox client
-- Rolls happen on the server. This side only drives the NUI, holds the session token
-- and plays the reveal sound. No threads run while the UI is closed.

local uiOpen = false
local token = nil -- server session for the crate on screen
local openSeq = 0 -- bumps on every open so stale timers do nothing
local nuiAck = 0
local cfgAcked = false -- the page has the config; later messages leave it out
local abst = nil

local inv = config.ui.inventory or {}
local iconPath = inv.iconPath
if type(iconPath) ~= 'string' or iconPath == '' then
    iconPath = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images')
end
if iconPath:sub(-1) ~= '/' then iconPath = iconPath .. '/' end
local iconExt = inv.iconExtension or '.png'
local overrides = type(inv.iconOverrides) == 'table' and inv.iconOverrides or {}

local nuiConfig = {
    ui = {
        showChances = config.ui.showChances,
        spinTime = config.ui.spinTime,
        allowSkip = config.ui.allowSkip,
        volume = config.ui.volume,
        inventory = { fallbackIcon = inv.fallbackIcon or false },
    },
    rarities = config.rarities,
    strings = LootBoxUIStrings(),
}

local function getAbst()
    if abst then return abst end
    if GetResourceState('glitch-abstraction') ~= 'started' then return nil end
    local ok, a = pcall(function() return exports['glitch-abstraction']:getAbstraction() end)
    if ok and a then abst = a end
    return abst
end

local function notify(message, kind)
    local title = L('title')
    local a = getAbst()
    local n = a and a.Notifications
    if n then
        if kind == 'success' and n.Success then return n.Success(title, message, 5000) end
        if kind == 'error' and n.Error then return n.Error(title, message, 5000) end
        if n.Info then return n.Info(title, message, 5000) end
    end
    if GetResourceState('ox_lib') == 'started' then
        return TriggerEvent('ox_lib:notify', { title = title, description = message, type = kind == 'info' and 'inform' or kind })
    end
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

-- --------------------------------------------------------------------
-- Item icons: config override, then the ox_inventory item image, then iconPath
-- --------------------------------------------------------------------

local iconCache = {}

local function iconOf(item)
    local url = iconCache[item]
    if url then return url end
    url = overrides[item]
    if not url and GetResourceState('ox_inventory') == 'started' then
        local ok, data = pcall(function() return exports.ox_inventory:Items(item) end)
        local image = ok and type(data) == 'table' and data.client and data.client.image
        if type(image) == 'string' and image ~= '' then url = image end
    end
    url = url or (iconPath .. item .. iconExt)
    iconCache[item] = url
    return url
end

local function addIcons(icons, list)
    if type(list) ~= 'table' then return end
    for _, e in ipairs(list) do
        if type(e) == 'table' and type(e.item) == 'string' then icons[e.item] = iconOf(e.item) end
    end
end

local function iconsFor(data)
    local icons = {}
    local box = data.box
    if type(box) == 'table' then
        if type(box.id) == 'string' then icons[box.id] = iconOf(box.id) end
        addIcons(icons, box.items)
        addIcons(icons, box.bonus)
    end
    addIcons(icons, data.reel)
    addIcons(icons, data.bonus)
    if type(data.reward) == 'table' then addIcons(icons, { data.reward }) end
    return icons
end

-- --------------------------------------------------------------------
-- UI
-- --------------------------------------------------------------------

local function closeUI()
    if not uiOpen then return end
    uiOpen = false
    SetNuiFocus(false, false)
    if config.ui.blurBackground then TriggerScreenblurFadeOut(250.0) end
    SendNUIMessage({ action = 'hide' })
end

local function openUI(action, data)
    openSeq = openSeq + 1
    local seq = openSeq

    if not uiOpen then
        uiOpen = true
        SetNuiFocus(true, true)
        if config.ui.blurBackground then TriggerScreenblurFadeIn(250.0) end
        -- ox_inventory can still be closing its own UI and release focus right after us
        SetTimeout(200, function()
            if uiOpen and seq == openSeq then SetNuiFocus(true, true) end
        end)
    end

    SendNUIMessage({ action = action, data = data, icons = iconsFor(data), cfg = not cfgAcked and nuiConfig or nil })

    -- If the page never answers, give the player their mouse back instead of trapping them.
    SetTimeout(3000, function()
        if uiOpen and seq == openSeq and nuiAck < seq then
            if token then TriggerServerEvent('glitch-lootBox:server:close', token) end
            token = nil
            closeUI()
            notify(L('screen_failed'), 'error')
        end
    end)
end

RegisterNetEvent('glitch-lootBox:client:preview', function(data)
    if type(data) ~= 'table' then return end
    token = data.token
    openUI('preview', data)
end)

RegisterNetEvent('glitch-lootBox:client:spin', function(data)
    if type(data) ~= 'table' then return end
    token = data.token
    openUI('spin', data)
end)

RegisterNetEvent('glitch-lootBox:client:granted', function(sessionToken, info)
    if type(info) ~= 'table' then return end
    if uiOpen and sessionToken == token then
        SendNUIMessage({ action = 'granted', data = info })
    end
    if info.notify then
        notify(info.notify, info.ok and 'success' or 'error')
    end
end)

RegisterNetEvent('glitch-lootBox:client:abort', function(message)
    token = nil
    closeUI()
    if message then notify(message, 'error') end
end)

RegisterNetEvent('glitch-lootBox:client:notify', function(message, kind)
    notify(message, kind)
end)

-- --------------------------------------------------------------------
-- NUI callbacks
-- --------------------------------------------------------------------

RegisterNUICallback('shown', function(_, cb)
    nuiAck = openSeq
    cfgAcked = true
    cb(1)
end)

RegisterNUICallback('unlock', function(_, cb)
    cb(1)
    if not token then return end
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    TriggerServerEvent('glitch-lootBox:server:unlock', token)
end)

RegisterNUICallback('reveal', function(data, cb)
    cb(1)
    local rarity = type(data) == 'table' and type(data.rarity) == 'string' and config.rarities[data.rarity]
    local sound = rarity and rarity.sound
    if type(sound) == 'table' and sound[1] then
        PlaySoundFrontend(-1, sound[1], sound[2] or 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    end
    if token then TriggerServerEvent('glitch-lootBox:server:claim', token) end
end)

RegisterNUICallback('again', function(data, cb)
    cb(1)
    if type(data) ~= 'table' or type(data.box) ~= 'string' then return end
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    TriggerServerEvent('glitch-lootBox:server:again', data.box)
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    -- Closing mid-spin is fine: the server pays out a rolled crate either way.
    if token then TriggerServerEvent('glitch-lootBox:server:close', token) end
    token = nil
    PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    closeUI()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() or not uiOpen then return end
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0.0)
end)

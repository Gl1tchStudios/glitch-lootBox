-- glitch-lootBox server
-- The server owns every roll. The crate is taken and the reward decided here before the
-- reel spins; the client only ever sends back a session token, never an item or amount.

local RESOURCE = GetCurrentResourceName()

local sessions = {}   -- [src] = { token, box, stage = 'preview' | 'rolled', reward, bonus }
local lastAction = {} -- [src] = GetGameTimer() of the last accepted crate request
local tokenSeq = 0
local abst = nil

local function dbg(msg, ...)
    if config.debug then print(('[glitch-lootBox] ' .. msg):format(...)) end
end

local function warnf(msg, ...)
    print(('^3[glitch-lootBox]^7 ' .. msg):format(...))
end

local function started(res)
    return GetResourceState(res) == 'started'
end

local function getAbst()
    if abst then return abst end
    if not started('glitch-abstraction') then return nil end
    local ok, lib = pcall(function() return exports['glitch-abstraction']:getAbstraction() end)
    if ok and lib then abst = lib end
    return abst
end

local function notify(src, message, kind)
    TriggerClientEvent('glitch-lootBox:client:notify', src, message, kind or 'info')
end

-- --------------------------------------------------------------------
-- Inventory (ox_inventory direct, glitch-abstraction otherwise)
-- --------------------------------------------------------------------

local Inv = {}

local function abstInv(fn)
    local a = getAbst()
    return a and a.Inventory and a.Inventory[fn]
end

function Inv.count(src, item)
    if started('ox_inventory') then return exports.ox_inventory:GetItemCount(src, item) or 0 end
    local fn = abstInv('GetItemCount')
    return fn and (tonumber(fn(src, item)) or 0) or 0
end

function Inv.canCarry(src, item, count)
    if started('ox_inventory') then return exports.ox_inventory:CanCarryItem(src, item, count) and true or false end
    local fn = abstInv('CanCarryItem')
    if fn then return fn(src, item, count) ~= false end
    return true
end

function Inv.add(src, item, count, metadata)
    if started('ox_inventory') then return exports.ox_inventory:AddItem(src, item, count, metadata) and true or false end
    local fn = abstInv('AddItem')
    return fn and (fn(src, item, count, metadata) and true or false) or false
end

-- metadata / slot: take that exact crate (heist caches carry metadata.source)
function Inv.remove(src, item, count, metadata, slot)
    if started('ox_inventory') then
        if slot and exports.ox_inventory:RemoveItem(src, item, count, metadata, slot) then return true end
        return exports.ox_inventory:RemoveItem(src, item, count, metadata) and true or false
    end
    local fn = abstInv('RemoveItem')
    return fn and (fn(src, item, count) and true or false) or false
end

-- First slot holding this crate, so "Open Another" keeps the crate's metadata.
function Inv.firstSlot(src, item)
    if not started('ox_inventory') then return nil end
    local ok, slots = pcall(function() return exports.ox_inventory:Search(src, 'slots', item) end)
    if not ok or type(slots) ~= 'table' then return nil end
    for _, s in pairs(slots) do return s end
end

-- Last resort when the player's inventory is full: put the items on the ground at their feet.
function Inv.drop(src, items)
    if #items == 0 or not started('ox_inventory') then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local ok, id = pcall(function()
        return exports.ox_inventory:CustomDrop('Crate', items, GetEntityCoords(ped))
    end)
    return ok and id ~= nil
end

local labelCache = {}

function Inv.label(item)
    if labelCache[item] then return labelCache[item] end
    local label
    if started('ox_inventory') then
        local ok, data = pcall(function() return exports.ox_inventory:Items(item) end)
        if ok and type(data) == 'table' then label = data.label end
    elseif started('qb-core') then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        local data = ok and core and core.Shared and core.Shared.Items and core.Shared.Items[item]
        if data then label = data.label end
    end
    labelCache[item] = label or item
    return labelCache[item]
end

-- --------------------------------------------------------------------
-- Rolling
-- --------------------------------------------------------------------

local function randInt(a, b)
    a, b = math.floor(tonumber(a) or 1), math.floor(tonumber(b) or 1)
    if a > b then a, b = b, a end
    return math.random(a, b)
end

-- source: the job a heist cache came from (crate metadata.source).
--   sources = { jobId = true }   the reward only exists in crates from these jobs
--   weights = { jobId = 2.0 }    the reward's chance is multiplied for that job
local function weightOf(def, source)
    if def.sources and not (source and def.sources[source]) then return 0 end
    local w = math.max(tonumber(def.chance) or 1, 0)
    if source and def.weights and def.weights[source] then w = w * def.weights[source] end
    return w
end

local function pickWeighted(list, source)
    local total = 0
    for i = 1, #list do total = total + weightOf(list[i], source) end
    if total <= 0 then return list[math.random(#list)] end

    local roll = math.random() * total
    for i = 1, #list do
        roll = roll - weightOf(list[i], source)
        if roll < 0 then return list[i] end
    end
    return list[#list]
end

local function rollAmount(def)
    if def.min and def.max then return randInt(def.min, def.max) end
    local a = def.amount
    if type(a) == 'table' and a.min and a.max then return randInt(a.min, a.max) end
    if type(a) == 'function' then return math.floor(tonumber(a()) or 1) end
    return math.floor(tonumber(a) or 1)
end

local function maxAmount(def)
    if def.max then return math.floor(def.max) end
    local a = def.amount
    if type(a) == 'table' and a.max then return math.floor(a.max) end
    return math.floor(tonumber(a) or 1)
end

local function rarityOf(key)
    return config.rarities[key] and key or 'common'
end

local function entryOf(def)
    return { item = def.item, label = def.label or Inv.label(def.item), rarity = rarityOf(def.rarity) }
end

-- Blueprint / unlock rewards (glitch-crafting): the item is crafting_blueprint
-- with metadata built by glitch-crafting. nil when crafting is not running.
local function rewardMeta(def)
    if not (def.blueprint or def.unlock) then return nil end
    if not started('glitch-crafting') then return nil end
    local ok, meta = pcall(function() return exports['glitch-crafting']:BlueprintMetadata(def.blueprint, def.unlock) end)
    return ok and meta or nil
end

local function amountText(def)
    if def.min and def.max then
        return def.min == def.max and tostring(def.min) or ('%s-%s'):format(def.min, def.max)
    end
    local a = def.amount
    if type(a) == 'table' and a.min and a.max then return ('%s-%s'):format(a.min, a.max) end
    if type(a) == 'number' then return tostring(a) end
    return '?'
end

-- What the preview screen shows. Built once per crate type.
local viewCache = {}

local function boxView(id, source)
    local cacheKey = id .. '|' .. tostring(source or '')
    if viewCache[cacheKey] then return viewCache[cacheKey] end
    local box = config.lootBoxes[id]

    local total = 0
    for _, def in ipairs(box.rewards) do total = total + weightOf(def, source) end

    local items = {}
    for _, def in ipairs(box.rewards) do
        local w = weightOf(def, source)
        if w > 0 then
            local e = entryOf(def)
            e.amount = amountText(def)
            e.chance = total > 0 and (w / total * 100) or 0
            items[#items + 1] = e
        end
    end
    table.sort(items, function(a, b)
        local ra, rb = config.rarities[a.rarity].order or 0, config.rarities[b.rarity].order or 0
        if ra ~= rb then return ra < rb end
        return a.chance > b.chance
    end)

    local bonus = {}
    for _, def in ipairs(box.bonusItems or {}) do
        bonus[#bonus + 1] = { item = def.item, label = def.label or Inv.label(def.item), amount = amountText(def) }
    end

    viewCache[cacheKey] = {
        id = id,
        name = box.name or Inv.label(id),
        accent = box.accent,
        image = box.image,
        items = items,
        bonus = bonus,
    }
    return viewCache[cacheKey]
end

-- The reel is weighted like the real odds, with the server's winner at winnerIndex.
local function buildReel(box, reward, source)
    local reel = {}
    local winner = config.ui.winnerIndex
    for i = 1, config.ui.reelLength do
        if i == winner then
            reel[i] = { item = reward.item, label = reward.label, rarity = reward.rarity }
        else
            reel[i] = entryOf(pickWeighted(box.rewards, source))
        end
    end
    return reel
end

-- --------------------------------------------------------------------
-- Sessions
-- --------------------------------------------------------------------

local function throttled(src, ms)
    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < ms then return true end
    lastAction[src] = now
    return false
end

local function newToken()
    tokenSeq = tokenSeq + 1
    return tokenSeq
end

local function describe(reward)
    local r = config.rarities[reward.rarity]
    return ('%sx %s (%s)'):format(reward.amount, reward.label, r and r.label or reward.rarity)
end

-- Takes one crate and decides the reward. Every possible reward has to fit before anything is
-- touched, so a nearly full inventory can never be used to filter out unwanted rolls.
-- crate: { metadata, slot } of the crate being opened (nil = any)
local function roll(src, id, crate)
    local box = config.lootBoxes[id]
    if not box then return nil, 'Unknown crate.' end
    if Inv.count(src, id) < 1 then return nil, ("You don't have a %s."):format(box.name or id) end
    local source = crate and crate.metadata and crate.metadata.source or nil

    for _, def in ipairs(box.rewards) do
        if weightOf(def, source) > 0 and not Inv.canCarry(src, def.item, maxAmount(def)) then
            return nil, 'Make some room in your inventory before opening this.'
        end
    end

    if not Inv.remove(src, id, 1, crate and crate.metadata, crate and crate.slot) then return nil, 'Could not open the crate.' end

    local def = pickWeighted(box.rewards, source)
    local reward = entryOf(def)
    reward.amount = math.max(rollAmount(def), 1)
    reward.metadata = rewardMeta(def)
    if (def.blueprint or def.unlock) and not reward.metadata then
        warnf('crate %s: could not build the %s reward (is glitch-crafting running?)', id, def.blueprint or def.unlock)
    end

    local bonus = {}
    for _, b in ipairs(box.bonusItems or {}) do
        local n = rollAmount(b)
        if n > 0 then
            bonus[#bonus + 1] = { item = b.item, label = b.label or Inv.label(b.item), amount = n }
        end
    end

    local s = { token = newToken(), box = id, stage = 'rolled', reward = reward, bonus = bonus, source = source }
    sessions[src] = s
    return s
end

-- Pays out a rolled session exactly once, whatever ends it (reveal, close, timeout, drop).
local function grant(src, why)
    local s = sessions[src]
    if not s or s.stage ~= 'rolled' then return end
    sessions[src] = nil

    local reward = s.reward
    local undelivered = {}

    if not Inv.add(src, reward.item, reward.amount, reward.metadata) then
        undelivered[#undelivered + 1] = { reward.item, reward.amount, reward.metadata }
    end
    for _, b in ipairs(s.bonus) do
        if not Inv.add(src, b.item, b.amount) then
            undelivered[#undelivered + 1] = { b.item, b.amount }
        end
    end

    local dropped = #undelivered > 0 and Inv.drop(src, undelivered)
    local lost = #undelivered > 0 and not dropped

    dbg('%s (%s) opened %s -> %s [%s]', GetPlayerName(src) or '?', src, s.box, describe(reward), why)
    if lost then
        warnf('could not deliver crate loot to %s (%s, %s) after %s: %s', GetPlayerName(src) or '?', src,
            GetPlayerIdentifierByType(src, 'license') or 'no license', why, json.encode(undelivered))
    end

    if why == 'dropped' or why == 'shutdown' then return end

    local info = { ok = #undelivered == 0, dropped = dropped and true or false, lost = lost, box = s.box, remaining = Inv.count(src, s.box) }
    if lost then
        info.notify = 'Your inventory was full and some crate loot could not be delivered. Contact staff.'
    elseif dropped then
        info.notify = 'Your inventory was full, the rest of the crate was dropped at your feet.'
    elseif why == 'instant' or why == 'timeout' then
        info.notify = 'You received ' .. describe(reward)
    end
    TriggerClientEvent('glitch-lootBox:client:granted', src, s.token, info)
end

local function startSpin(src, id, crate)
    local s, err = roll(src, id, crate)
    if not s then
        sessions[src] = nil
        TriggerClientEvent('glitch-lootBox:client:abort', src, err)
        return
    end

    -- Failsafe: if the client never reports the reveal, pay out anyway.
    SetTimeout(math.floor(((tonumber(config.ui.spinTime) or 6.5) + 25) * 1000), function()
        if sessions[src] == s then grant(src, 'timeout') end
    end)

    local view = boxView(id, s.source)
    TriggerClientEvent('glitch-lootBox:client:spin', src, {
        token = s.token,
        box = { id = id, name = view.name, accent = view.accent },
        reel = buildReel(config.lootBoxes[id], s.reward, s.source),
        winner = config.ui.winnerIndex,
        reward = s.reward,
        bonus = s.bonus,
    })
end

-- data: the used slot from the inventory ({ slot, metadata }), when given
local function useBox(src, id, data)
    src = tonumber(src)
    if not src or src <= 0 or not config.lootBoxes[id] then return end
    if throttled(src, 500) then return end

    local current = sessions[src]
    if current and current.stage == 'rolled' then
        return notify(src, 'You are already opening a crate.', 'error')
    end

    local crate = nil
    if type(data) == 'table' and (data.slot or data.metadata) then
        crate = { slot = data.slot, metadata = data.metadata or data.info }
    end
    local source = crate and crate.metadata and crate.metadata.source or nil

    if not config.useUI then
        local s, err = roll(src, id, crate)
        if not s then return notify(src, err, 'error') end
        return grant(src, 'instant')
    end

    if config.ui.showPreview then
        local token = newToken()
        sessions[src] = { token = token, box = id, stage = 'preview', crate = crate }
        TriggerClientEvent('glitch-lootBox:client:preview', src, { token = token, box = boxView(id, source), owned = Inv.count(src, id) })
    else
        startSpin(src, id, crate)
    end
end

-- --------------------------------------------------------------------
-- Client requests (token only)
-- --------------------------------------------------------------------

RegisterNetEvent('glitch-lootBox:server:unlock', function(token)
    local src = source
    local s = sessions[src]
    if not s or s.stage ~= 'preview' or s.token ~= token then return end
    startSpin(src, s.box, s.crate)
end)

RegisterNetEvent('glitch-lootBox:server:claim', function(token)
    local src = source
    local s = sessions[src]
    if s and s.stage == 'rolled' and s.token == token then grant(src, 'claim') end
end)

RegisterNetEvent('glitch-lootBox:server:close', function(token)
    local src = source
    local s = sessions[src]
    if not s or s.token ~= token then return end
    if s.stage == 'preview' then
        sessions[src] = nil
    else
        grant(src, 'close')
    end
end)

RegisterNetEvent('glitch-lootBox:server:again', function(id)
    local src = source
    if type(id) ~= 'string' or not config.lootBoxes[id] or not config.useUI then return end
    if sessions[src] or throttled(src, 600) then return end
    startSpin(src, id, Inv.firstSlot(src, id))
end)

AddEventHandler('playerDropped', function()
    local src = source
    if sessions[src] then grant(src, 'dropped') end
    sessions[src] = nil
    lastAction[src] = nil
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= RESOURCE then return end
    for src, s in pairs(sessions) do
        if s.stage == 'rolled' then grant(src, 'shutdown') end
    end
end)

-- --------------------------------------------------------------------
-- Startup
-- --------------------------------------------------------------------

local function validate()
    local ui = config.ui
    ui.reelLength = math.max(math.floor(tonumber(ui.reelLength) or 56), 24)
    ui.winnerIndex = math.floor(tonumber(ui.winnerIndex) or (ui.reelLength - 8))
    if ui.winnerIndex < 12 or ui.winnerIndex > ui.reelLength - 4 then
        warnf('config.ui.winnerIndex must be between 12 and reelLength - 4, using %s', ui.reelLength - 8)
        ui.winnerIndex = ui.reelLength - 8
    end

    for id, box in pairs(config.lootBoxes) do
        if type(box.rewards) ~= 'table' or #box.rewards == 0 then
            warnf('crate %s has no rewards and was skipped', id)
            config.lootBoxes[id] = nil
        else
            if started('ox_inventory') and not exports.ox_inventory:Items(id) then
                warnf('crate item %s is not loaded in ox_inventory (add it to data/items.lua, then restart ox_inventory)', id)
            end
            for _, def in ipairs(box.rewards) do
                if def.blueprint or def.unlock then def.item = 'crafting_blueprint' end
                if def.rarity and not config.rarities[def.rarity] then
                    warnf('crate %s: unknown rarity "%s" on %s, treating it as common', id, def.rarity, def.item)
                end
                if started('ox_inventory') and not exports.ox_inventory:Items(def.item) then
                    warnf('crate %s: item %s does not exist in ox_inventory', id, def.item)
                end
            end
        end
    end
end

-- Qbox / QBCore usable items also work with ox_inventory (it hands unknown items to the framework).
-- glitch-abstraction is only a fallback: its ox_inventory path relies on an export ox removed.
local function registerUsable(name)
    local handler = function(src, data) useBox(src, name, data) end

    if started('qbx_core') and pcall(function() exports.qbx_core:CreateUseableItem(name, handler) end) then
        return 'qbx_core'
    end
    if started('qb-core') and pcall(function() exports['qb-core']:GetCoreObject().Functions.CreateUseableItem(name, handler) end) then
        return 'qb-core'
    end
    if started('es_extended') and pcall(function() exports.es_extended:getSharedObject().RegisterUsableItem(name, handler) end) then
        return 'es_extended'
    end
    local a = getAbst()
    if a and a.Framework and a.Framework.RegisterUsableItem then
        local ok, res = pcall(a.Framework.RegisterUsableItem, name, handler)
        if ok and res ~= false then return 'glitch-abstraction' end
    end
end

CreateThread(function()
    local deadline = GetGameTimer() + 15000
    while GetGameTimer() < deadline and not (started('qbx_core') or started('qb-core') or started('es_extended')) do
        Wait(250)
    end

    validate()

    local count, via = 0, nil
    for id in pairs(config.lootBoxes) do
        local res = registerUsable(id)
        if res then
            count, via = count + 1, res
        else
            warnf('could not register %s as a usable item', id)
        end
    end
    print(('^2[glitch-lootBox]^7 %s crate type(s) usable via %s'):format(count, via or 'nothing'))
end)

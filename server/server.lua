-- glitch-lootBox server
-- The server owns every roll. The crate is taken and the reward decided here before the
-- reel spins; the client only ever sends back a session token, never an item or amount.
-- A rolled reward is written to the resource KVP store at roll time and removed once it is
-- in the player's inventory, so a disconnect, character switch or crash never loses it.

local RESOURCE = GetCurrentResourceName()
local SV = config.server or {}

local sessions = {}   -- [src] = { token, box, stage = 'preview' | 'rolled', reward, items, ident, key }
local lastAction = {} -- [src] = GetGameTimer() of the last accepted crate request
local lastBox = {}    -- [src] = crate id of the last finished spin (for Open Another)
local delivering = {} -- [src] = true while pending loot is being handed over
local tokenSeq = 0
local pendingSeq = 0
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

-- Pick the crate set (config.server.cratePack). 'auto' = the demo set on a Glitch'd Roleplay
-- server (glitch-economy installed), the stock-item set everywhere else.
do
    local pack = SV.cratePack or 'auto'
    if pack == 'auto' then
        pack = GetResourceState('glitch-economy') ~= 'missing' and 'demo' or 'generic'
    end
    if pack == 'demo' and type(config.demoLootBoxes) == 'table' then
        config.lootBoxes = config.demoLootBoxes
    end
    config.demoLootBoxes = nil
end

-- Tokens come from math.random: seed it once so they differ between restarts.
math.randomseed(os.time() + GetGameTimer())

local craftingUp = started('glitch-crafting')

local function getAbst()
    if abst then return abst end
    if not started('glitch-abstraction') then return nil end
    local ok, a = pcall(function() return exports['glitch-abstraction']:getAbstraction() end)
    if ok and a then abst = a end
    return abst
end

local function notify(src, message, kind)
    TriggerClientEvent('glitch-lootBox:client:notify', src, message, kind or 'info')
end

-- --------------------------------------------------------------------
-- Framework (Qbox, QBCore or ESX; all optional)
-- --------------------------------------------------------------------

local qbCore, esxObj

local function qb()
    if not qbCore and started('qb-core') then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok then qbCore = core end
    end
    return qbCore
end

local function esx()
    if not esxObj and started('es_extended') then
        local ok, obj = pcall(function() return exports.es_extended:getSharedObject() end)
        if ok then esxObj = obj end
    end
    return esxObj
end

local function playerData(src)
    if started('qbx_core') then
        local ok, p = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if ok and p then return p.PlayerData end
    end
    local core = qb()
    if core then
        local p = core.Functions.GetPlayer(src)
        if p then return p.PlayerData end
    end
end

-- The character a crate was opened by: citizenid on Qbox / QBCore, the ESX identifier,
-- or the license as a last resort.
local function identOf(src)
    local pd = playerData(src)
    if pd and pd.citizenid then return tostring(pd.citizenid) end
    local x = esx()
    if x then
        local xp = x.GetPlayerFromId(src)
        if xp and xp.identifier then return tostring(xp.identifier) end
    end
    return GetPlayerIdentifierByType(src, 'license')
end

local function incapacitated(src)
    if SV.blockWhenIncapacitated == false then return false end
    local pd = playerData(src)
    local m = pd and pd.metadata
    return m and (m.isdead or m.inlaststand or m.ishandcuffed) and true or false
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
-- items: { { item, amount, metadata }, ... }
function Inv.drop(src, items)
    if #items == 0 or not started('ox_inventory') then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local list = {}
    for i, it in ipairs(items) do list[i] = { it.item, it.amount, it.metadata } end
    local ok, id = pcall(function()
        return exports.ox_inventory:CustomDrop(L('title'), list, GetEntityCoords(ped))
    end)
    return ok and id ~= nil
end

function Inv.ready(src)
    if not started('ox_inventory') then return true end
    local ok, inv = pcall(function() return exports.ox_inventory:GetInventory(src) end)
    return ok and inv ~= nil
end

local itemCache = {} -- [name] = ox_inventory item data or false

local function itemData(item)
    local data = itemCache[item]
    if data == nil then
        data = false
        if started('ox_inventory') then
            local ok, d = pcall(function() return exports.ox_inventory:Items(item) end)
            if ok and type(d) == 'table' then data = d end
        end
        itemCache[item] = data
    end
    return data or nil
end

function Inv.weight(item)
    local d = itemData(item)
    return d and tonumber(d.weight) or 0
end

local labelCache = {}

function Inv.label(item)
    if labelCache[item] then return labelCache[item] end
    local label
    local d = itemData(item)
    if d then
        label = d.label
    elseif started('qb-core') then
        local core = qb()
        local data = core and core.Shared and core.Shared.Items and core.Shared.Items[item]
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
-- Rewards whose item is missing from the inventory, and blueprint rewards while
-- glitch-crafting is not running, weigh 0.
local function weightOf(def, source)
    if def.missing then return 0 end
    if (def.blueprint or def.unlock) and not craftingUp then return 0 end
    if def.sources and not (source and def.sources[source]) then return 0 end
    local w = math.max(tonumber(def.chance) or 1, 0)
    if source and def.weights and def.weights[source] then w = w * def.weights[source] end
    return w
end

local function totalWeight(list, source)
    local total = 0
    for i = 1, #list do total = total + weightOf(list[i], source) end
    return total
end

-- nil when nothing in the list can be rolled.
local function pickWeighted(list, source)
    local total = totalWeight(list, source)
    if total <= 0 then return nil end

    local roll = math.random() * total
    local last
    for i = 1, #list do
        local w = weightOf(list[i], source)
        if w > 0 then
            last = list[i]
            roll = roll - w
            if roll < 0 then return list[i] end
        end
    end
    return last
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
-- with metadata built by glitch-crafting. nil when that fails.
local function rewardMeta(def)
    if not craftingUp then return nil end
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

-- What the preview screen shows. Built once per crate type, job source and crafting state.
local viewCache = {}

local function boxView(id, source)
    local cacheKey = ('%s|%s|%s'):format(id, tostring(source or ''), craftingUp and 1 or 0)
    if viewCache[cacheKey] then return viewCache[cacheKey] end
    local box = config.lootBoxes[id]

    local total = totalWeight(box.rewards, source)

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
        if not def.missing then
            bonus[#bonus + 1] = { item = def.item, label = def.label or Inv.label(def.item), amount = amountText(def) }
        end
    end

    viewCache[cacheKey] = {
        id = id,
        name = box.name or Inv.label(id),
        accent = box.accent,
        image = box.image,
        category = box.category,
        description = box.description,
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
        local def = i ~= winner and pickWeighted(box.rewards, source)
        if def then
            reel[i] = entryOf(def)
        else
            reel[i] = { item = reward.item, label = reward.label, rarity = reward.rarity }
        end
    end
    return reel
end

-- Room for the heaviest possible reward plus every bonus item, minus the crate itself.
local function hasRoom(src, box, id, source)
    local heaviest = 0
    for _, def in ipairs(box.rewards) do
        if weightOf(def, source) > 0 then
            local n = maxAmount(def)
            if not Inv.canCarry(src, def.item, n) then return false end
            heaviest = math.max(heaviest, Inv.weight(def.item) * n)
        end
    end
    if not started('ox_inventory') then return true end

    local need = heaviest - Inv.weight(id)
    for _, b in ipairs(box.bonusItems or {}) do
        if not b.missing then need = need + Inv.weight(b.item) * math.max(maxAmount(b), 0) end
    end
    if need > 0 then
        local ok, fits = pcall(function() return exports.ox_inventory:CanCarryWeight(src, need) end)
        if ok and fits == false then return false end
    end
    return true
end

-- --------------------------------------------------------------------
-- Pending loot (KVP)
-- --------------------------------------------------------------------

local PENDING = 'pending:'

-- Identifiers can hold ':' (license:..., char1:...), so they are flattened for the key prefix.
local function identKey(ident)
    return (tostring(ident):gsub('[^%w_%-]', '-'))
end

local function newPendingKey(ident)
    pendingSeq = (pendingSeq + 1) % 100000
    return ('%s%s:%d.%d'):format(PENDING, identKey(ident), os.time(), pendingSeq)
end

local function savePending(key, box, items)
    SetResourceKvp(key, json.encode({ box = box, items = items, t = os.time() }))
end

local function pendingKeys(ident)
    local keys = {}
    local handle = StartFindKvp(PENDING .. identKey(ident) .. ':')
    if handle == -1 then return keys end
    for _ = 1, 500 do
        local key = FindKvp(handle)
        if not key then break end
        keys[#keys + 1] = key
    end
    EndFindKvp(handle)
    return keys
end

-- Hands items over, drops what does not fit, and returns what is still left.
local function deliver(src, items)
    local failed = {}
    for _, it in ipairs(items) do
        if not Inv.add(src, it.item, it.amount, it.metadata) then failed[#failed + 1] = it end
    end
    if #failed == 0 then return {}, false end
    if Inv.drop(src, failed) then return {}, true end
    return failed, false
end

local function describe(reward)
    local r = config.rarities[reward.rarity]
    return ('%sx %s (%s)'):format(reward.amount, reward.label, r and r.label or reward.rarity)
end

-- Hands over every pending record of this character that is not part of a live session.
local function deliverPending(src)
    if delivering[src] or not GetPlayerName(src) then return end
    local ident = identOf(src)
    if not ident then return end
    local keys = pendingKeys(ident)
    if #keys == 0 then return end

    delivering[src] = true
    local active = sessions[src] and sessions[src].key
    local handed = false
    for _, key in ipairs(keys) do
        if key ~= active then
            local ok, rec = pcall(json.decode, GetResourceKvpString(key) or '')
            if ok and type(rec) == 'table' and type(rec.items) == 'table' then
                local left = deliver(src, rec.items)
                if #left < #rec.items then handed = true end
                if #left > 0 then savePending(key, rec.box, left) else DeleteResourceKvp(key) end
                dbg('pending %s for %s (%s): %s item(s) handed over, %s left', key, GetPlayerName(src) or '?', src, #rec.items - #left, #left)
            else
                DeleteResourceKvp(key)
            end
        end
    end
    delivering[src] = nil
    if handed then notify(src, L('pending_delivered'), 'success') end
end

-- Waits until the character's inventory is loaded, then hands over pending loot.
local function scheduleDelivery(src)
    src = tonumber(src)
    if not src or src <= 0 then return end
    CreateThread(function()
        Wait(math.max(tonumber(SV.pendingDelay) or 5, 0) * 1000)
        for _ = 1, math.max(tonumber(SV.pendingTries) or 10, 1) do
            if not GetPlayerName(src) then return end
            if playerData(src) or esx() or not (started('qbx_core') or started('qb-core')) then
                if Inv.ready(src) then return deliverPending(src) end
            end
            Wait(2000)
        end
    end)
end

-- --------------------------------------------------------------------
-- Sessions
-- --------------------------------------------------------------------

local function throttled(src, seconds)
    local now = GetGameTimer()
    if lastAction[src] and now - lastAction[src] < seconds * 1000 then return true end
    lastAction[src] = now
    return false
end

local function newToken()
    -- Random, so a token cannot be guessed; it is also only ever valid for its own session.
    tokenSeq = tokenSeq + 1
    return math.random(1000, 2000000) * 1000 + (tokenSeq % 1000)
end

-- Takes one crate and decides the reward. Every possible reward has to fit before anything is
-- touched, so a nearly full inventory can never be used to filter out unwanted rolls.
-- crate: { metadata, slot } of the crate being opened (nil = any)
local function roll(src, id, crate)
    local box = config.lootBoxes[id]
    if not box then return nil, L('unknown_crate') end
    if Inv.count(src, id) < 1 then return nil, L('no_crate', box.name or Inv.label(id)) end
    local source = crate and crate.metadata and crate.metadata.source or nil

    local def = pickWeighted(box.rewards, source)
    if not def then return nil, L('nothing_inside') end
    if not hasRoom(src, box, id, source) then return nil, L('no_room') end

    local metadata
    if def.blueprint or def.unlock then
        metadata = rewardMeta(def)
        if not metadata then
            warnf('crate %s: could not build the %s reward (is glitch-crafting running?), crate kept', id, def.blueprint or def.unlock)
            return nil, L('open_failed')
        end
    end

    local ident = identOf(src)
    if not ident then return nil, L('open_failed') end

    local reward = entryOf(def)
    reward.amount = math.max(rollAmount(def), 1)

    local items = { { item = reward.item, amount = reward.amount, metadata = metadata } }
    local bonus = {}
    for _, b in ipairs(box.bonusItems or {}) do
        local n = not b.missing and rollAmount(b) or 0
        if n > 0 then
            bonus[#bonus + 1] = { item = b.item, label = b.label or Inv.label(b.item), amount = n }
            items[#items + 1] = { item = b.item, amount = n }
        end
    end

    local s = {
        token = newToken(), box = id, stage = 'rolled', reward = reward, bonus = bonus, items = items,
        source = source, ident = ident, key = newPendingKey(ident),
    }
    -- Save the roll first, then take the crate: a crash in between can only cost the server a
    -- crate, never the player a reward.
    savePending(s.key, id, items)
    if not Inv.remove(src, id, 1, crate and crate.metadata, crate and crate.slot) then
        DeleteResourceKvp(s.key)
        return nil, L('open_failed')
    end
    sessions[src] = s
    return s
end

-- The player left or switched character mid-spin: the roll stays in KVP for that character.
local function park(src, why)
    local s = sessions[src]
    sessions[src] = nil
    lastBox[src] = nil
    if s and s.stage == 'rolled' then
        dbg('%s: crate %s for %s kept for their next login (%s)', src, s.box, s.ident, why)
    end
end

-- Pays out a rolled session exactly once, whatever ends it (reveal, close, timeout, shutdown).
local function grant(src, why)
    local s = sessions[src]
    if not s or s.stage ~= 'rolled' then return end
    if s.ident and identOf(src) ~= s.ident then
        -- A different character is on this slot now: keep the roll in KVP for the original one.
        park(src, 'identity changed')
        return
    end
    sessions[src] = nil
    lastBox[src] = s.box

    local left, dropped = deliver(src, s.items)
    if #left == 0 then
        DeleteResourceKvp(s.key)
    else
        savePending(s.key, s.box, left)
        warnf('crate loot for %s (%s, %s) kept for later after %s: %s', GetPlayerName(src) or '?', src, s.ident, why, json.encode(left))
    end

    dbg('%s (%s) opened %s -> %s [%s]', GetPlayerName(src) or '?', src, s.box, describe(s.reward), why)
    if why == 'shutdown' then return end

    local kept = #left > 0
    local info = { ok = not kept and not dropped, dropped = dropped, kept = kept, box = s.box, remaining = Inv.count(src, s.box) }
    if kept then
        info.notify = L('inv_full_kept')
    elseif dropped then
        info.notify = L('inv_full_dropped')
    elseif why == 'instant' or why == 'timeout' then
        info.notify = L('received', describe(s.reward))
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
    local grace = (tonumber(config.ui.spinTime) or 6.5) + (tonumber(SV.revealGrace) or 25)
    SetTimeout(math.floor(grace * 1000), function()
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

local function throttleOf(kind, default)
    local t = SV.throttle
    return type(t) == 'table' and tonumber(t[kind]) or default
end

-- data: the used slot from the inventory ({ slot, metadata }), when given
local function useBox(src, id, data)
    src = tonumber(src)
    if not src or src <= 0 or not config.lootBoxes[id] then return end
    if throttled(src, throttleOf('use', 0.5)) then return end

    local current = sessions[src]
    if current and current.stage == 'rolled' then
        return notify(src, L('already_opening'), 'error')
    end
    if incapacitated(src) then return notify(src, L('incapacitated'), 'error') end

    local crate = nil
    if type(data) == 'table' and (data.slot or data.metadata) then
        crate = { slot = data.slot, metadata = data.metadata or data.info }
    end
    local source = crate and crate.metadata and crate.metadata.source or nil

    if totalWeight(config.lootBoxes[id].rewards, source) <= 0 then
        return notify(src, L('nothing_inside'), 'error')
    end

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
    if incapacitated(src) then
        sessions[src] = nil
        return TriggerClientEvent('glitch-lootBox:client:abort', src, L('incapacitated'))
    end
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
    if s and s.token == token then
        if s.stage == 'preview' then
            sessions[src] = nil
        else
            grant(src, 'close')
        end
    end
    lastBox[src] = nil
end)

-- Open Another: only the crate type the player just opened, while its reveal is on screen.
RegisterNetEvent('glitch-lootBox:server:again', function(id)
    local src = source
    if type(id) ~= 'string' or id ~= lastBox[src] or not config.lootBoxes[id] or not config.useUI then return end
    if sessions[src] or throttled(src, throttleOf('again', 0.6)) then return end
    if incapacitated(src) then
        lastBox[src] = nil
        return TriggerClientEvent('glitch-lootBox:client:abort', src, L('incapacitated'))
    end
    startSpin(src, id, Inv.firstSlot(src, id))
end)

AddEventHandler('playerDropped', function()
    local src = source
    park(src, 'dropped')
    lastAction[src] = nil
    delivering[src] = nil
end)

-- Character switch: the inventory unloads, so a rolled crate waits for that character's next login.
local function onLogout(src)
    src = tonumber(src)
    if not src or not sessions[src] then return end
    park(src, 'logout')
    TriggerClientEvent('glitch-lootBox:client:abort', src)
end

AddEventHandler('qbx_core:server:playerLoggedOut', onLogout)
AddEventHandler('QBCore:Server:OnPlayerUnload', onLogout)
AddEventHandler('esx:onPlayerLogout', onLogout)

-- Character loaded: hand over anything left from an earlier session.
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source
    if src then scheduleDelivery(src) end
end)

AddEventHandler('qbx_core:server:playerLoaded', function(player)
    local src = type(player) == 'table' and player.PlayerData and player.PlayerData.source or tonumber(player)
    if src then scheduleDelivery(src) end
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    scheduleDelivery(playerId)
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'glitch-crafting' then craftingUp = true end
end)

AddEventHandler('onResourceStop', function(res)
    if res == 'glitch-crafting' then craftingUp = false return end
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

    local ox = started('ox_inventory')
    for id, box in pairs(config.lootBoxes) do
        if type(box.rewards) ~= 'table' or #box.rewards == 0 then
            warnf('crate %s has no rewards and was skipped', id)
            config.lootBoxes[id] = nil
        else
            if ox and not itemData(id) then
                warnf('crate item %s is not loaded in ox_inventory (see install/items.lua, then restart ox_inventory)', id)
            end
            local missing, allSourced = {}, true
            for _, def in ipairs(box.rewards) do
                if def.blueprint or def.unlock then def.item = 'crafting_blueprint' end
                if not def.sources then allSourced = false end
                if def.rarity and not config.rarities[def.rarity] then
                    warnf('crate %s: unknown rarity "%s" on %s, treating it as common', id, def.rarity, tostring(def.item))
                end
                if type(def.item) ~= 'string' or (ox and not itemData(def.item)) then
                    def.missing = true
                    missing[#missing + 1] = tostring(def.item)
                end
            end
            for _, b in ipairs(box.bonusItems or {}) do
                if type(b.item) ~= 'string' or (ox and not itemData(b.item)) then
                    b.missing = true
                    missing[#missing + 1] = tostring(b.item)
                end
            end
            if #missing > 0 then
                warnf('crate %s: %s item(s) not in ox_inventory, left out of the roll: %s', id, #missing, table.concat(missing, ', '))
            end
            local usable = false
            for _, def in ipairs(box.rewards) do
                if not def.missing then usable = true break end
            end
            if not usable then
                warnf('crate %s: none of its rewards exist in ox_inventory, crate skipped', id)
                config.lootBoxes[id] = nil
            end
            if allSourced then
                warnf('crate %s: every reward has `sources`, so a crate without metadata.source cannot be opened', id)
            end
        end
    end
end

-- Qbox / QBCore usable items also work with ox_inventory (it hands unknown items to the framework).
-- glitch-abstraction is only a fallback for other setups.
local function registerUsable(name)
    local handler = function(src, data) useBox(src, name, data) end

    if started('qbx_core') and pcall(function() exports.qbx_core:CreateUseableItem(name, handler) end) then
        return 'qbx_core'
    end
    if started('qb-core') and pcall(function() qb().Functions.CreateUseableItem(name, handler) end) then
        return 'qb-core'
    end
    if started('es_extended') and pcall(function() esx().RegisterUsableItem(name, handler) end) then
        return 'es_extended'
    end
    local a = getAbst()
    if a and a.Framework and a.Framework.RegisterUsableItem then
        local ok, res = pcall(a.Framework.RegisterUsableItem, name, handler)
        if ok and res ~= false then return 'glitch-abstraction' end
    end
end

-- Warn about any card in the configured category that the glitch-criminaltablet pawn counter
-- would not buy. Off when config.integrations.pawnCheck is false.
local function pawnCheck()
    local pc = config.integrations and config.integrations.pawnCheck
    if type(pc) ~= 'table' or not pc.resource or not started(pc.resource) then return end
    local items, seen = {}, {}
    for _, box in pairs(config.lootBoxes) do
        if box.category == pc.category then
            for _, r in ipairs(box.rewards or {}) do
                if r.item and not seen[r.item] then seen[r.item] = true; items[#items + 1] = r.item end
            end
        end
    end
    if #items == 0 then return end
    local ok, missing = pcall(function() return exports[pc.resource]:MissingFromPawn(items) end)
    for item, why in pairs(ok and type(missing) == 'table' and missing or {}) do
        warnf('%s cannot be sold at the pawn counter: %s', item, why)
    end
end

CreateThread(function()
    local deadline = GetGameTimer() + 15000
    while GetGameTimer() < deadline and not (started('qbx_core') or started('qb-core') or started('es_extended')) do
        Wait(250)
    end

    if not started('ox_inventory') and not getAbst() then
        warnf('neither ox_inventory nor glitch-abstraction is running: crates cannot be opened')
    end

    craftingUp = started('glitch-crafting')
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
    dbg('%s crate type(s) usable via %s', count, via or 'nothing')

    -- Loot kept from before a restart or crash, for everyone already online.
    for _, id in ipairs(GetPlayers()) do scheduleDelivery(id) end

    Wait(15000)
    pawnCheck()
end)

-- --------------------------------------------------------------------
-- Exports
-- --------------------------------------------------------------------

-- Pull chance (percent of one opening) per reward item, from plain crates (no job source).
-- An item in several crates reports its best chance. Used by glitch-cardAlbums.
exports('GetDropRates', function()
    local out = {}
    for _, box in pairs(config.lootBoxes or {}) do
        local total = totalWeight(box.rewards or {})
        if total > 0 then
            for _, def in ipairs(box.rewards or {}) do
                local chance = weightOf(def) / total * 100
                if def.item and chance > (out[def.item] or 0) then out[def.item] = chance end
            end
        end
    end
    return out
end)

-- Items that sit behind the gold star card (a rarity with mystery = true) in any crate.
-- Used by glitch-cardAlbums and glitch-criminaltablet to keep chase items hidden.
exports('GetMysteryItems', function()
    local out, seen = {}, {}
    for _, box in pairs(config.lootBoxes or {}) do
        for _, r in ipairs(box.rewards or {}) do
            local rarity = config.rarities[r.rarity or '']
            if r.item and rarity and rarity.mystery and not seen[r.item] then
                seen[r.item] = true
                out[#out + 1] = r.item
            end
        end
    end
    return out
end)

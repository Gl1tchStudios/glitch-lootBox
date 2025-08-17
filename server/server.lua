local GlitchLib = nil

local preSelectedRewards = {}

local function debugPrint(message) -- debug messages when enabled
    if config.debug then
        print(message)
    end
end

local function getTableKeys(tbl) -- get table keys as strings
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
end

Citizen.CreateThread(function() -- wait for glitch abstraction and setup loot boxes
    while GetResourceState('glitch-abstraction') ~= 'started' do
        Citizen.Wait(100)
    end
    
    Citizen.Wait(2000)
    
    GlitchLib = exports['glitch-abstraction']:getAbstraction()
    
    if not GlitchLib then
        debugPrint('^1[loot-box] ERROR: GlitchLib is nil after getAbstraction()^7')
        return
    end
    
    debugPrint('^3[loot-box] DEBUG: GlitchLib loaded, IsReady = ' .. tostring(GlitchLib.IsReady) .. '^7')
    
    while not GlitchLib.IsReady do 
        Citizen.Wait(100) 
    end
    
    Citizen.Wait(1000)
    
    debugPrint('^3[loot-box] DEBUG: GlitchLib is ready^7')
    debugPrint('^3[loot-box] DEBUG: Available GlitchLib keys: ' .. table.concat(getTableKeys(GlitchLib), ', ') .. '^7')
    
    if GlitchLib.Inventory then
        debugPrint('^3[loot-box] DEBUG: Available Inventory keys: ' .. table.concat(getTableKeys(GlitchLib.Inventory), ', ') .. '^7')
    end
    
    setupLootBoxes()
    
    debugPrint('^2[loot-box] system loaded^7')
end)

function selectUnifiedReward(lootBoxData) -- select reward from loot table
    local rewards = lootBoxData.rewards
    if not rewards or #rewards == 0 then
        return nil
    end
    
    local isRarityBased = rewards[1].chance and rewards[1].rarity
    
    if isRarityBased then
        local totalChance = 0
        for _, item in ipairs(rewards) do
            totalChance = totalChance + item.chance
        end
        
        local randomChance = math.random(1, totalChance)
        local currentChance = 0
        
        for _, item in ipairs(rewards) do
            currentChance = currentChance + item.chance
            if randomChance <= currentChance then
                local amount = 1
                if item.min and item.max then
                    amount = math.random(item.min, item.max)
                end
                return {
                    item = item.item,
                    amount = amount,
                    label = item.label or item.item,
                    rarity = item.rarity
                }
            end
        end
        
        local firstItem = rewards[1]
        local amount = 1
        if firstItem.min and firstItem.max then
            amount = math.random(firstItem.min, firstItem.max)
        end
        return {
            item = firstItem.item,
            amount = amount,
            label = firstItem.label or firstItem.item,
            rarity = firstItem.rarity
        }
    else
        local totalChance = 0
        for _, reward in pairs(rewards) do
            totalChance = totalChance + (reward.chance or 10)
        end
        
        local roll = math.random(1, totalChance)
        local currentChance = 0
        
        for _, reward in pairs(rewards) do
            currentChance = currentChance + (reward.chance or 10)
            if roll <= currentChance then
                local amount = math.random(reward.min or 1, reward.max or 1)
                return {
                    item = reward.item,
                    amount = amount,
                    label = reward.item, 
                    rarity = 'common'
                }
            end
        end
        
        local firstReward = rewards[1] or rewards[next(rewards)]
        return {
            item = firstReward.item,
            amount = math.random(firstReward.min or 1, firstReward.max or 1),
            label = firstReward.item,
            rarity = 'common'
        }
    end
end

function generateSpinnerItems(lootBoxData) -- generate items for ui spinner
    local rewards = lootBoxData.rewards
    local spinnerItems = {}
    
    for i = 1, 60 do
        local randomReward = rewards[math.random(1, #rewards)]
        table.insert(spinnerItems, {
            item = randomReward.item,
            label = randomReward.label or randomReward.item,
            rarity = randomReward.rarity or 'common'
        })
    end
    return spinnerItems
end

local function AddItem(source, item, amount) -- add item to player inventory
    return GlitchLib.Inventory.AddItem(source, item, amount)
end

local function RemoveItem(source, item, count) -- remove item from player inventory
    return GlitchLib.Inventory.RemoveItem(source, item, count)
end

function giveUnifiedBonusItems(source, lootBoxData) -- give bonus items to player
    if not lootBoxData.bonusItems then
        return
    end
    
    for _, bonusItem in ipairs(lootBoxData.bonusItems) do
        local amount = bonusItem.amount
        
        if type(amount) == 'table' and amount.min and amount.max then
            amount = math.random(amount.min, amount.max)
        elseif type(amount) == 'function' then
            amount = amount()
        end
        
        local success = AddItem(source, bonusItem.item, amount)
        if success then
            TriggerClientEvent('glitch-lootBox:client:showBonusReward', source, bonusItem.item, amount, bonusItem.label or bonusItem.item)
        end
    end
end

function setupLootBoxes() -- register all loot boxes as usable items
    if not GlitchLib then
        debugPrint('^1[loot-box] ERROR: GlitchLib not available^7')
        return
    end
    
    if not GlitchLib.Framework then
        debugPrint('^1[loot-box] ERROR: GlitchLib.Framework not available^7')
        debugPrint('^3[loot-box] DEBUG: Available GlitchLib keys: ' .. table.concat(getTableKeys(GlitchLib), ', ') .. '^7')
        return
    end
    
    if not GlitchLib.Framework.RegisterUsableItem then
        debugPrint('^1[loot-box] ERROR: GlitchLib.Framework.RegisterUsableItem not available^7')
        debugPrint('^3[loot-box] DEBUG: Available Framework keys: ' .. table.concat(getTableKeys(GlitchLib.Framework), ', ') .. '^7')
        return
    end
    
    debugPrint('^3[loot-box] DEBUG: Using GlitchLib.Framework.RegisterUsableItem^7')
    
    local count = 0
    
    for lootBoxName, lootBoxData in pairs(config.lootBoxes) do
        local success, error = pcall(function()
            GlitchLib.Framework.RegisterUsableItem(lootBoxName, function(source)
                debugPrint('^2[loot-box] Using ' .. lootBoxName .. ' - source: ' .. tostring(source) .. '^7')
                
                local selectedReward = selectUnifiedReward(lootBoxData)
                if not selectedReward then
                    debugPrint('^1[loot-box] ERROR: Could not select reward for ' .. lootBoxName .. '^7')
                    return
                end
                
                preSelectedRewards[source] = {
                    reward = selectedReward,
                    lootBoxName = lootBoxName,
                    lootBoxData = lootBoxData
                }
                
                if config.useUI then
                    debugPrint('^3[loot-box] DEBUG: Using UI mode for ' .. lootBoxName .. '^7')
                    
                    local spinnerItems = generateSpinnerItems(lootBoxData)
                    
                    spinnerItems[45] = {
                        item = selectedReward.item,
                        label = selectedReward.label,
                        rarity = selectedReward.rarity
                    }
                    
                    debugPrint('^3[loot-box] DEBUG: Set winning item at position 45: ' .. selectedReward.item .. '^7')
                    debugPrint('^3[loot-box] DEBUG: Winning item details: ' .. selectedReward.label .. ' (' .. selectedReward.rarity .. ')^7')
                    
                    TriggerClientEvent('glitch-lootBox:client:openUI', source, spinnerItems, selectedReward)
                else
                    debugPrint('^3[loot-box] DEBUG: Using classic mode for ' .. lootBoxName .. '^7')
                    
                    local removed = RemoveItem(source, lootBoxName, 1)
                    if removed then
                        -- Give main reward
                        local added = AddItem(source, selectedReward.item, selectedReward.amount)
                        if added then
                            debugPrint('^2[loot-box] SUCCESS: Added reward to inventory (Classic)^7')
                            
                            giveUnifiedBonusItems(source, lootBoxData)
                            
                            if selectedReward.rarity and selectedReward.rarity ~= 'common' then
                                TriggerClientEvent('glitch-lootBox:client:showRewardBox', source, selectedReward.item, selectedReward.amount, selectedReward.rarity, selectedReward.label)
                            else
                                TriggerClientEvent('glitch-lootBox:client:showReward', source, selectedReward.item, selectedReward.amount)
                            end
                        else
                            print('^1[loot-box] ERROR: Failed to add reward, giving back crate^7')
                            AddItem(source, lootBoxName, 1)
                        end
                    else
                        debugPrint('^1[loot-box] ERROR: Failed to remove ' .. lootBoxName .. '^7')
                    end
                    
                    preSelectedRewards[source] = nil
                end
            end)
        end)
        
        if not success then
            debugPrint('^1[loot-box] ERROR registering ' .. lootBoxName .. ': ' .. tostring(error) .. '^7')
        else
            count = count + 1
            debugPrint('^2[loot-box] registered unified loot box: ' .. lootBoxName .. '^7')
        end
    end
    
    debugPrint('^2[loot-box] registered ' .. count .. ' loot box types with unified system^7')
end

RegisterNetEvent('glitch-lootBox:server:collectReward', function(actualWinner) -- handles reward collection from UI
    local source = source
    debugPrint('^3[loot-box] DEBUG: Collect reward event from player ' .. source .. '^7')
    
    local rewardData = preSelectedRewards[source]
    if not rewardData then
        debugPrint('^1[loot-box] ERROR: No reward data found for player ' .. source .. '^7')
        TriggerClientEvent('glitch-lootBox:client:rewardCollected', source, false)
        return
    end
    
    local lootBoxName = rewardData.lootBoxName
    local lootBoxData = rewardData.lootBoxData
    
    local selectedReward = actualWinner or rewardData.reward
    if not selectedReward then
        debugPrint('^1[loot-box] ERROR: No reward found for player ' .. source .. '^7')
        TriggerClientEvent('glitch-lootBox:client:rewardCollected', source, false)
        return
    end
    
    debugPrint('^6[loot-box] ANIMATION WINNER:^7')
    debugPrint('  Item: ' .. tostring(selectedReward.item))
    debugPrint('  Label: ' .. tostring(selectedReward.label))
    debugPrint('  Rarity: ' .. tostring(selectedReward.rarity))
    debugPrint('  Amount: ' .. tostring(selectedReward.amount))
    
    debugPrint('^3[loot-box] DEBUG: Processing reward: ' .. selectedReward.item .. ' x' .. selectedReward.amount .. '^7')
    
    local removed = RemoveItem(source, lootBoxName, 1)
    if removed then
        debugPrint('^3[loot-box] DEBUG: Successfully removed ' .. lootBoxName .. '^7')
        
        local added = AddItem(source, selectedReward.item, selectedReward.amount)
        if added then
            debugPrint('^2[loot-box] SUCCESS: Added animation-determined reward to inventory^7')
            
            giveUnifiedBonusItems(source, lootBoxData)
            
            TriggerClientEvent('glitch-lootBox:client:rewardCollected', source, true)
            
            if selectedReward.rarity and selectedReward.rarity ~= 'common' then
                debugPrint('^3[loot-box] DEBUG: Sending CSGO notification^7')
                TriggerClientEvent('glitch-lootBox:client:showRewardBox', source, selectedReward.item, selectedReward.amount, selectedReward.rarity, selectedReward.label)
            else
                debugPrint('^3[loot-box] DEBUG: Sending classic notification^7')
                TriggerClientEvent('glitch-lootBox:client:showReward', source, selectedReward.item, selectedReward.amount)
            end
        else
            debugPrint('^1[loot-box] ERROR: Failed to add reward, giving back crate^7')
            AddItem(source, lootBoxName, 1)
            TriggerClientEvent('glitch-lootBox:client:rewardCollected', source, false)
        end
    else
        debugPrint('^1[loot-box] ERROR: Failed to remove ' .. lootBoxName .. '^7')
        TriggerClientEvent('glitch-lootBox:client:rewardCollected', source, false)
    end
    
    preSelectedRewards[source] = nil
end)

AddEventHandler('playerDropped', function() -- clean up pre selected rewards when player leaves
    local source = source
    if preSelectedRewards[source] then
        preSelectedRewards[source] = nil
        debugPrint('^3[loot-box] DEBUG: Cleaned up reward for disconnected player ' .. source .. '^7')
    end
end)
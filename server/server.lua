local GlitchLib = nil

local preSelectedRewards = {}

local function debugPrint(message)
    if config.debug then
        print(message)
    end
end

local function getTableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
end

Citizen.CreateThread(function()
    while GetResourceState('glitch-abstraction') ~= 'started' do
        Citizen.Wait(100)
    end
    
    Citizen.Wait(2000)
    
    GlitchLib = exports['glitch-abstraction']:getAbstraction()
    
    if not GlitchLib then
        print('^1[loot-box] ERROR: GlitchLib is nil after getAbstraction()^7')
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
    
    print('^2[loot-box] system loaded^7')
end)

function selectUnifiedReward(lootBoxData)
    local rewards = lootBoxData.rewards
    if not rewards or #rewards == 0 then
        return nil
    end
    
    local isRarityBased = rewards[1].weight and rewards[1].rarity
    
    if isRarityBased then
        local totalWeight = 0
        for _, item in ipairs(rewards) do
            totalWeight = totalWeight + item.weight
        end
        
        local randomWeight = math.random(1, totalWeight)
        local currentWeight = 0
        
        for _, item in ipairs(rewards) do
            currentWeight = currentWeight + item.weight
            if randomWeight <= currentWeight then
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
        
        -- Fallback to first item
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
        -- Old chance-based selection (backwards compatibility)
        local totalWeight = 0
        for _, reward in pairs(rewards) do
            totalWeight = totalWeight + (reward.chance or 10)
        end
        
        local roll = math.random(1, totalWeight)
        local currentWeight = 0
        
        for _, reward in pairs(rewards) do
            currentWeight = currentWeight + (reward.chance or 10)
            if roll <= currentWeight then
                local amount = math.random(reward.min or 1, reward.max or 1)
                return {
                    item = reward.item,
                    amount = amount,
                    label = reward.item, -- Old format doesn't have labels
                    rarity = 'common' -- Default rarity for old format
                }
            end
        end
        
        -- Fallback
        local firstReward = rewards[1] or rewards[next(rewards)]
        return {
            item = firstReward.item,
            amount = math.random(firstReward.min or 1, firstReward.max or 1),
            label = firstReward.item,
            rarity = 'common'
        }
    end
end

function generateSpinnerItems(lootBoxData)
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

local function AddItem(source, item, amount)
    return GlitchLib.Inventory.AddItem(source, item, amount)
end

local function RemoveItem(source, item, count)
    return GlitchLib.Inventory.RemoveItem(source, item, count)
end

function giveUnifiedBonusItems(source, lootBoxData)
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
            TriggerClientEvent('lootbox:showBonusReward', source, bonusItem.item, amount, bonusItem.label or bonusItem.item)
        end
    end
end

function setupLootBoxes()
    if not GlitchLib then
        print('^1[loot-box] ERROR: GlitchLib not available^7')
        return
    end
    
    if not GlitchLib.Framework then
        print('^1[loot-box] ERROR: GlitchLib.Framework not available^7')
        debugPrint('^3[loot-box] DEBUG: Available GlitchLib keys: ' .. table.concat(getTableKeys(GlitchLib), ', ') .. '^7')
        return
    end
    
    if not GlitchLib.Framework.RegisterUsableItem then
        print('^1[loot-box] ERROR: GlitchLib.Framework.RegisterUsableItem not available^7')
        debugPrint('^3[loot-box] DEBUG: Available Framework keys: ' .. table.concat(getTableKeys(GlitchLib.Framework), ', ') .. '^7')
        return
    end
    
    debugPrint('^3[loot-box] DEBUG: Using GlitchLib.Framework.RegisterUsableItem^7')
    
    local count = 0
    
    -- Register all loot boxes with unified system (supports both old and new formats)
    for lootBoxName, lootBoxData in pairs(config.lootBoxes) do
        local success, error = pcall(function()
            GlitchLib.Framework.RegisterUsableItem(lootBoxName, function(source)
                print('^2[loot-box] Using ' .. lootBoxName .. ' - source: ' .. tostring(source) .. '^7')
                
                -- Pre-select reward for UI synchronisation
                local selectedReward = selectUnifiedReward(lootBoxData)
                if not selectedReward then
                    print('^1[loot-box] ERROR: Could not select reward for ' .. lootBoxName .. '^7')
                    return
                end
                
                preSelectedRewards[source] = {
                    reward = selectedReward,
                    lootBoxName = lootBoxName,
                    lootBoxData = lootBoxData
                }
                
                -- Check UI mode from config
                if config.useUI then
                    debugPrint('^3[loot-box] DEBUG: Using UI mode for ' .. lootBoxName .. '^7')
                    
                    -- Generate spinner items and ensure winning item is at position 45 (0-indexed 44)
                    local spinnerItems = generateSpinnerItems(lootBoxData)
                    
                    -- In Lua arrays are 1-indexed, so position 45 in Lua = index 44 in JavaScript
                    spinnerItems[45] = {
                        item = selectedReward.item,
                        label = selectedReward.label,
                        rarity = selectedReward.rarity
                    }
                    
                    debugPrint('^3[loot-box] DEBUG: Set winning item at position 45: ' .. selectedReward.item .. '^7')
                    debugPrint('^3[loot-box] DEBUG: Winning item details: ' .. selectedReward.label .. ' (' .. selectedReward.rarity .. ')^7')
                    
                    -- Send to client for UI display
                    TriggerClientEvent('glitch-lootBox:openUI', source, spinnerItems, selectedReward)
                else
                    debugPrint('^3[loot-box] DEBUG: Using classic mode for ' .. lootBoxName .. '^7')
                    
                    -- Classic mode - direct reward with notification
                    local removed = RemoveItem(source, lootBoxName, 1)
                    if removed then
                        -- Give main reward
                        local added = AddItem(source, selectedReward.item, selectedReward.amount)
                        if added then
                            debugPrint('^2[loot-box] SUCCESS: Added reward to inventory (Classic)^7')
                            
                            -- Give bonus items
                            giveUnifiedBonusItems(source, lootBoxData)
                            
                            -- Send appropriate notification based on format
                            if selectedReward.rarity and selectedReward.rarity ~= 'common' then
                                -- New format with rarity
                                TriggerClientEvent('lootbox:showRewardBox', source, selectedReward.item, selectedReward.amount, selectedReward.rarity, selectedReward.label)
                            else
                                -- Old format or common rarity
                                TriggerClientEvent('lootbox:showReward', source, selectedReward.item, selectedReward.amount)
                            end
                        else
                            print('^1[loot-box] ERROR: Failed to add reward, giving back crate^7')
                            AddItem(source, lootBoxName, 1)
                        end
                    else
                        print('^1[loot-box] ERROR: Failed to remove ' .. lootBoxName .. '^7')
                    end
                    
                    -- Clean up pre-selected reward
                    preSelectedRewards[source] = nil
                end
            end)
        end)
        
        if not success then
            print('^1[loot-box] ERROR registering ' .. lootBoxName .. ': ' .. tostring(error) .. '^7')
        else
            count = count + 1
            print('^2[loot-box] registered unified loot box: ' .. lootBoxName .. '^7')
        end
    end
    
    print('^2[loot-box] registered ' .. count .. ' loot box types with unified system^7')
end

-- Handle reward collection from UI (unified system with animation-determined winner)
RegisterNetEvent('glitch-lootBox:collectReward', function(actualWinner)
    local source = source
    debugPrint('^3[loot-box] DEBUG: Collect reward event from player ' .. source .. '^7')
    
    -- Get pre-selected reward data for loot box info
    local rewardData = preSelectedRewards[source]
    if not rewardData then
        print('^1[loot-box] ERROR: No reward data found for player ' .. source .. '^7')
        TriggerClientEvent('glitch-lootBox:rewardCollected', source, false)
        return
    end
    
    local lootBoxName = rewardData.lootBoxName
    local lootBoxData = rewardData.lootBoxData
    
    -- Use actual winner if provided by animation, otherwise fallback to pre-selected
    local selectedReward = actualWinner or rewardData.reward
    if not selectedReward then
        print('^1[loot-box] ERROR: No reward found for player ' .. source .. '^7')
        TriggerClientEvent('glitch-lootBox:rewardCollected', source, false)
        return
    end
    
    print('^6[loot-box] ANIMATION WINNER:^7')
    print('  Item: ' .. tostring(selectedReward.item))
    print('  Label: ' .. tostring(selectedReward.label))
    print('  Rarity: ' .. tostring(selectedReward.rarity))
    print('  Amount: ' .. tostring(selectedReward.amount))
    
    debugPrint('^3[loot-box] DEBUG: Processing reward: ' .. selectedReward.item .. ' x' .. selectedReward.amount .. '^7')
    
    -- Remove the crate first
    local removed = RemoveItem(source, lootBoxName, 1)
    if removed then
        debugPrint('^3[loot-box] DEBUG: Successfully removed ' .. lootBoxName .. '^7')
        
        -- Add the animation-determined item
        local added = AddItem(source, selectedReward.item, selectedReward.amount)
        if added then
            debugPrint('^2[loot-box] SUCCESS: Added animation-determined reward to inventory^7')
            
            -- Give bonus items
            giveUnifiedBonusItems(source, lootBoxData)
            
            -- Confirm successful collection to client
            TriggerClientEvent('glitch-lootBox:rewardCollected', source, true)
            
            -- Send appropriate notification based on format
            if selectedReward.rarity and selectedReward.rarity ~= 'common' then
                -- New format with rarity
                debugPrint('^3[loot-box] DEBUG: Sending CSGO notification^7')
                TriggerClientEvent('lootbox:showRewardBox', source, selectedReward.item, selectedReward.amount, selectedReward.rarity, selectedReward.label)
            else
                -- Old format or common rarity
                debugPrint('^3[loot-box] DEBUG: Sending classic notification^7')
                TriggerClientEvent('lootbox:showReward', source, selectedReward.item, selectedReward.amount)
            end
        else
            print('^1[loot-box] ERROR: Failed to add reward, giving back crate^7')
            AddItem(source, lootBoxName, 1)
            TriggerClientEvent('glitch-lootBox:rewardCollected', source, false)
        end
    else
        print('^1[loot-box] ERROR: Failed to remove ' .. lootBoxName .. '^7')
        TriggerClientEvent('glitch-lootBox:rewardCollected', source, false)
    end
    
    -- Clean up pre-selected reward
    preSelectedRewards[source] = nil
end)

-- Clean up disconnected players
AddEventHandler('playerDropped', function()
    local source = source
    if preSelectedRewards[source] then
        preSelectedRewards[source] = nil
        debugPrint('^3[loot-box] DEBUG: Cleaned up reward for disconnected player ' .. source .. '^7')
    end
end)

-- Debug commands for testing the unified loot box system
if config.debug then
    RegisterCommand('testammocrate', function(source, args)
        local player = source
        local crateType = args[1] or 'ammocratet1'
        
        if config.lootBoxes[crateType] then
            local success = AddItem(player, crateType, 1)
            if success then
                TriggerClientEvent('glitch-lootbox:notify', player, 
                    'Debug: Gave you a ' .. crateType .. ' to test!', 'success')
            else
                TriggerClientEvent('glitch-lootbox:notify', player, 
                    'Debug: Failed to give ' .. crateType, 'error')
            end
        else
            TriggerClientEvent('glitch-lootbox:notify', player, 
                'Debug: Unknown crate type: ' .. crateType, 'error')
        end
    end, false)
    
    RegisterCommand('testlootbox', function(source, args)
        local player = source
        local boxType = args[1] or 'lockpickbox'
        
        if config.lootBoxes[boxType] then
            local success = AddItem(player, boxType, 1)
            if success then
                TriggerClientEvent('glitch-lootbox:notify', player, 
                    'Debug: Gave you a ' .. boxType .. ' to test!', 'success')
            else
                TriggerClientEvent('glitch-lootbox:notify', player, 
                    'Debug: Failed to give ' .. boxType, 'error')
            end
        else
            TriggerClientEvent('glitch-lootbox:notify', player, 
                'Debug: Unknown box type: ' .. boxType, 'error')
        end
    end, false)
    
    RegisterCommand('listlootboxes', function(source)
        local player = source
        local boxList = {}
        for boxName, _ in pairs(config.lootBoxes) do
            table.insert(boxList, boxName)
        end
        TriggerClientEvent('glitch-lootbox:notify', player, 
            'Available loot boxes: ' .. table.concat(boxList, ', '), 'info')
    end, false)
end

-- Test command for giving loot box items (unified system)
RegisterNetEvent('lootbox:giveTestItem', function(itemName)
    local source = source
    
    if config.lootBoxes[itemName] then
        local success = AddItem(source, itemName, 1)
        if success then
            debugPrint('^2[loot-box] DEBUG: Gave test item ' .. itemName .. ' to player ' .. source .. '^7')
        else
            debugPrint('^1[loot-box] ERROR: Failed to give test item ' .. itemName .. '^7')
        end
    else
        debugPrint('^1[loot-box] ERROR: Unknown test item ' .. itemName .. '^7')
    end
end)
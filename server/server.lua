local GlitchLib = nil

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

local function AddItem(source, item, amount)
    debugPrint('^3[loot-box] DEBUG: Adding ' .. amount .. 'x ' .. item .. ' to player ' .. source .. '^7')
    return GlitchLib.Inventory.AddItem(source, item, amount)
end

local function RemoveItem(source, item, count)
    debugPrint('^3[loot-box] DEBUG: Removing ' .. count .. 'x ' .. item .. ' from player ' .. source .. '^7')
    return GlitchLib.Inventory.RemoveItem(source, item, count)
end

local function pickRandomReward(rewardList)
    local totalWeight = 0
    for _, reward in pairs(rewardList) do
        totalWeight = totalWeight + (reward.chance or 10)
    end
    
    local roll = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, reward in pairs(rewardList) do
        currentWeight = currentWeight + (reward.chance or 10)
        if roll <= currentWeight then
            local amount = math.random(reward.min or 1, reward.max or 1)
            return reward.item, amount
        end
    end
    
    local firstReward = rewardList[1] or rewardList[next(rewardList)]
    return firstReward.item, math.random(firstReward.min or 1, firstReward.max or 1)
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
    for lootBoxName, lootBoxData in pairs(config.lootBoxes) do
        local success, error = pcall(function()
            GlitchLib.Framework.RegisterUsableItem(lootBoxName, function(source)
                print('^2[loot-box] Using ' .. lootBoxName .. ' - source: ' .. tostring(source) .. '^7')
                
                local item, amount = pickRandomReward(lootBoxData.rewards)
                debugPrint('^3[loot-box] DEBUG: Picked reward: ' .. item .. ' x' .. amount .. '^7')
                
                local removed = RemoveItem(source, lootBoxName, 1)
                if removed then
                    debugPrint('^3[loot-box] DEBUG: Removed loot box from inventory^7')
                    
                    local added = AddItem(source, item, amount)
                    if added then
                        debugPrint('^2[loot-box] SUCCESS: Added reward to inventory^7')
                        TriggerClientEvent('lootbox:showReward', source, item, amount)
                    else
                        print('^1[loot-box] ERROR: Failed to add reward, giving back loot box^7')
                        AddItem(source, lootBoxName, 1)
                    end
                else
                    print('^1[loot-box] ERROR: Failed to remove loot box^7')
                end
            end)
        end)
        
        if not success then
            print('^1[loot-box] ERROR registering ' .. lootBoxName .. ': ' .. tostring(error) .. '^7')
        else
            count = count + 1
            print('^2[loot-box] registered usable item: ' .. lootBoxName .. '^7')
        end
    end
    
    print('^2[loot-box] registered ' .. count .. ' loot box types^7')
end
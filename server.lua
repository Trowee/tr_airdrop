local QBCore, ESX
if Config.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
end

local function GetPlayer(source)
    if Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Config.Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
end

local function RemoveMoney(player, amount)
    if Config.Framework == 'qb' then
        return player.Functions.RemoveMoney('cash', amount)
    elseif Config.Framework == 'esx' then
        if player.getAccount('black_money').money >= amount then
            player.removeAccountMoney('black_money', amount)
            return true
        end
        return false
    end
end

RegisterServerEvent('blackmarket:spawnAirdrop')
AddEventHandler('blackmarket:spawnAirdrop', function(dropLocation)
    TriggerClientEvent('blackmarket:spawnAirdropForAll', -1, dropLocation)
end)

RegisterServerEvent('blackmarket:startFlareSV')
AddEventHandler('blackmarket:startFlareSV', function(dropLocation)
    TriggerClientEvent('blackmarket:startFlareCL', -1, dropLocation)
end)


RegisterNetEvent('blackmarket:buyItems')
AddEventHandler('blackmarket:buyItems', function(items, totalPrice)
    local src = source
    local player = GetPlayer(src)
    
    if RemoveMoney(player, totalPrice) then
        local dropLocation = Config.DropLocations[math.random(#Config.DropLocations)]
        TriggerClientEvent('blackmarket:startAirdrop', src, dropLocation, items)
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You do not have enough money!'})
    end
end)

RegisterNetEvent('blackmarket:startAirdrop')
AddEventHandler('blackmarket:startAirdrop', function(dropLocation, items)
    currentDrop = {location = dropLocation, items = items}
    TriggerClientEvent('blackmarket:spawnAirdropForAll', -1, dropLocation)
end)


RegisterNetEvent('blackmarket:collectAirdrop')
AddEventHandler('blackmarket:collectAirdrop', function(items)
    local src = source
    local player = GetPlayer(src)
   
    if not player then
        return
    end

    for _, itemData in ipairs(items) do
        if type(itemData) == 'table' and type(itemData.item) == 'string' and type(itemData.amount) == 'number' then
            if Config.Inventory == 'ox' then
                local itemDef = exports.ox_inventory:Items(itemData.item)
                if itemDef then
                    exports.ox_inventory:AddItem(src, itemData.item, itemData.amount)
                end
            elseif Config.Inventory == 'qb' then
                player.Functions.AddItem(itemData.item, itemData.amount)
            end
        end
    end
   
    TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'You collected the airdrop'})
    TriggerClientEvent('blackmarket:removeAirdrop', -1)
end)

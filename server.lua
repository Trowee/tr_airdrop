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
        return player.Functions.RemoveMoney('black_money', amount)
    elseif Config.Framework == 'esx' then
        if player.getAccount('black_money').money >= amount then
            player.removeAccountMoney('black_money', amount)
            return true
        end
        return false
    end
end

RegisterNetEvent('blackmarket:buyItems')
AddEventHandler('blackmarket:buyItems', function(items, totalPrice)
    local src = source
    local player = GetPlayer(src)
    
    if RemoveMoney(player, totalPrice) then
        local dropLocation = Config.DropLocations[math.random(#Config.DropLocations)]
        TriggerClientEvent('blackmarket:startAirdrop', src, dropLocation, items)
    else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'You dont have enough money!'})
    end
end)

RegisterNetEvent('blackmarket:collectAirdrop')
AddEventHandler('blackmarket:collectAirdrop', function(items)
    local src = source
    local player = GetPlayer(src)

    for _, item in ipairs(items) do
        if Config.Inventory == 'ox' then
            exports.ox_inventory:AddItem(src, item.item, 1)
        elseif Config.Inventory == 'qb' then
            player.Functions.AddItem(item.item, 1)
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'You collected AirDrop'})

    TriggerClientEvent('blackmarket:removeAirdrop', src)
end)

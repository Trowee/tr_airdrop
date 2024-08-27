local cart = {}
local currentDrop = nil
local hasCollected = false
local box = nil
local smoke = nil
local wayp = nil

CreateThread(function()
    local model = `a_m_m_eastsa_02`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local npc = CreatePed(4, model, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1, Config.NPCLocation.w, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    if Config.Target == 'ox' then
        exports.ox_target:addBoxZone({
            coords = vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z),
            size = vector3(1, 1, 2),
            rotation = Config.NPCLocation.w,
            debug = false,
            options = {
                {
                    name = 'open_black_market',
                    event = 'blackmarket:openMenu',
                    icon = 'fas fa-shopping-cart',
                    label = 'Open Black Market',
                }
            }
        })
    elseif Config.Target == 'qb' then
        exports['qb-target']:AddBoxZone("blackmarket_npc", vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z), 1, 1, {
            name = "blackmarket_npc",
            heading = Config.NPCLocation.w,
            debugPoly = false,
            minZ = Config.NPCLocation.z - 1,
            maxZ = Config.NPCLocation.z + 1
        }, {
            options = {
                {
                    event = "blackmarket:openMenu",
                    icon = "fas fa-shopping-cart",
                    label = "Open Black Market",
                }
            },
            distance = 2.0
        })
    end

    if Config.Blip then
        npcBlip = AddBlipForCoord(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
        SetBlipSprite(npcBlip, 150)
        SetBlipDisplay(npcBlip, 4)
        SetBlipScale(npcBlip, 0.8)
        SetBlipColour(npcBlip, 40)
        SetBlipAsShortRange(npcBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('Black Market')
        EndTextCommandSetBlipName(npcBlip)
    end
end)

RegisterNetEvent('blackmarket:openMenu')
AddEventHandler('blackmarket:openMenu', function()
    local options = {}
    for _, item in ipairs(Config.Items) do
        table.insert(options, {
            title = item.label,
            description = 'Price: $' .. item.price,
            onSelect = function()
                local input = lib.inputDialog('Add to Cart', {
                    {type = 'number', label = 'Amount', description = 'Enter the amount you want to buy', required = true, min = 1}
                })
                if input then
                    TriggerEvent('blackmarket:addToCart', {item = item, amount = input[1]})
                end
            end
        })
    end

    table.insert(options, {
        title = 'View Cart',
        onSelect = function()
            TriggerEvent('blackmarket:viewCart')
        end
    })

    lib.registerContext({
        id = 'black_market',
        title = 'Black Market',
        options = options
    })

    lib.showContext('black_market')
end)

RegisterNetEvent('blackmarket:addToCart')
AddEventHandler('blackmarket:addToCart', function(data)
    table.insert(cart, {item = data.item, amount = data.amount})
    lib.notify({
        title = 'Added to cart',
        description = data.amount .. 'x ' .. data.item.label .. ' added to cart',
        type = 'success'
    })
    TriggerEvent('blackmarket:openMenu')
end)

RegisterNetEvent('blackmarket:viewCart')
AddEventHandler('blackmarket:viewCart', function()
    local totalPrice = 0
    local cartItems = ''
    for _, item in ipairs(cart) do
        totalPrice = totalPrice + (item.item.price * item.amount)
        cartItems = cartItems .. item.amount .. 'x ' .. item.item.label .. ', '
    end

    if lib.alertDialog({
        header = 'Cart',
        content = 'Items: ' .. cartItems .. '\nTotal Price: $' .. totalPrice,
        centered = true,
        cancel = true
    }) then
        TriggerServerEvent('blackmarket:buyItems', cart, totalPrice)
        cart = {}
    end
end)

RegisterNetEvent('blackmarket:startAirdrop')
AddEventHandler('blackmarket:startAirdrop', function(dropLocation, items)
    currentDrop = {location = dropLocation, items = items}

    lib.showTextUI('Airdrop is on its way. Follow the checkpoint.')
    wayp = AddBlipForCoord(dropLocation.x, dropLocation.y, dropLocation.z)
    SetBlipRoute(wayp, true)
    SetBlipRouteColour(wayp, 66)

    SetBlipAlpha(blip, 0)

    local _, z = GetGroundZFor_3dCoord(dropLocation.x, dropLocation.y, dropLocation.z, 0)
    UseParticleFxAssetNextCall('core')
    if z == 0.0 then
        z = dropLocation.z
    end
    local size = 1.0
    smoke = StartParticleFxLoopedAtCoord('exp_grd_flare', vector3(dropLocation.x, dropLocation.y, z), 0.0, 0.0, 0.0, size, false, false, false, false)
    SetParticleFxLoopedAlpha(smoke, 0.8)

    CreateThread(function()
        while currentDrop do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - dropLocation)

            if distance < Config.DropRadius then
                TriggerServerEvent('blackmarket:spawnAirdrop', dropLocation)
                break
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('blackmarket:spawnAirdropForAll')
AddEventHandler('blackmarket:spawnAirdropForAll', function(dropLocation)
    lib.hideTextUI()
    RemoveBlip(wayp)

    local dropCoords = dropLocation + vector3(0, 0, Config.AirdropHeight)
    local groundZ = dropLocation.z

    local boxModel = `prop_box_wood05a`
    RequestModel(boxModel)
    while not HasModelLoaded(boxModel) do
        Wait(0)
    end

    box = CreateObject(boxModel, dropCoords, true, true, true)
    local netId = NetworkGetNetworkIdFromEntity(box)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, false)

    local parachuteModel = `p_cargo_chute_s`
    RequestModel(parachuteModel)
    while not HasModelLoaded(parachuteModel) do
        Wait(0)
    end
    local parachute = CreateObject(parachuteModel, dropCoords, true, true, true)

    AttachEntityToEntity(parachute, box, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

    CreateThread(function()
        while true do
            local boxCoords = GetEntityCoords(box)

            if boxCoords.z <= groundZ + 0.1 then
                DeleteObject(parachute)
                SetEntityCoords(box, boxCoords.x, boxCoords.y, groundZ, false, false, false, false)
                PlaceObjectOnGroundProperly(box)
                FreezeEntityPosition(box, true)
                TriggerEvent('blackmarket:createDroppedCrate', box)
                break
            end

            SetEntityCoords(box, boxCoords.x, boxCoords.y, boxCoords.z - 0.1, false, false, false, false)

            Wait(10)
        end
    end)

    lib.notify({
        title = 'Airdrop Incoming',
        description = 'Airdrop just got off the plane',
        type = 'inform'
    })
end)

RegisterNetEvent('blackmarket:collectAirdrop')
AddEventHandler('blackmarket:collectAirdrop', function(crate)
    hasCollected = true
    if Config.Target == 'ox' then
        exports.ox_target:removeZone('cratezone')
    elseif Config.Target == 'qb' then
        exports['qb-target']:RemoveZone("cratezone")
    end

    if smoke then
        StopParticleFxLooped(smoke, 0)
        smoke = nil 
    end

    local progress = lib.progressCircle({
        duration = Config.BreakingTime,
        label = 'Breaking crate...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
        },
        anim = {
            dict = 'melee@large_wpn@streamed_core',
            clip = 'ground_attack_on_spot'
        },
        prop = {
            model = `prop_ing_crowbar`,
            pos = vec3(0.0, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0) 
        }
    })

    if progress then
        local itemsToSend = {}
        for _, item in ipairs(currentDrop.items) do
            if type(item) == 'table' and type(item.item) == 'table' then
                table.insert(itemsToSend, {
                    item = item.item.item,
                    amount = item.amount
                })
            else
            end
        end
        TriggerServerEvent('blackmarket:collectAirdrop', itemsToSend)
        if DoesEntityExist(box) then
            DeleteObject(box)
        end
    end


    hasCollected = false
end)


RegisterNetEvent('blackmarket:createDroppedCrate')
AddEventHandler('blackmarket:createDroppedCrate', function(crate)
    local crateCoords = GetEntityCoords(crate)
    
    if Config.Target == 'ox' then
        exports.ox_target:addBoxZone({
            name = 'cratezone',
            coords = crateCoords,
            size = vector3(2, 2, 2),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'collect_airdrop',
                    event = 'blackmarket:collectAirdrop',
                    icon = 'fas fa-box-open',
                    label = 'Collect airdrop',
                }
            }
        })
    elseif Config.Target == 'qb' then
        exports['qb-target']:AddBoxZone("cratezone", crateCoords, 2, 2, {
            name = "cratezone",
            heading = 0,
            debugPoly = false,
            minZ = crateCoords.z - 1,
            maxZ = crateCoords.z + 1
        }, {
            options = {
                {
                    event = "blackmarket:collectAirdrop",
                    icon = "fas fa-box-open",
                    label = "Collect airdrop",
                }
            },
            distance = 2.0
        })
    end

    lib.notify({
        title = 'Airdrop',
        description = 'Airdrop has arrived at the location!',
        type = 'success'
    })
end)

RegisterNetEvent('blackmarket:removeAirdrop')
AddEventHandler('blackmarket:removeAirdrop', function()
    if DoesEntityExist(box) then
        DeleteObject(box)
    end
    currentDrop = nil
end)

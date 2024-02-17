local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPed
local qbx = exports.qbx_core
local blips = {}

local function sellItem(data)
    local hasItem = exports.ox_inventory:Search('count', data.item)
    local newAmount = hasItem + data.currentAmount
    local price = data.price * hasItem
    local pb = lib.progressBar({
        duration = 5000,
        label = "Discussing Price For " .. exports.ox_inventory:Items(data.item).label,
        canCancel = true,
        useWhileDead = false,
        anim = {
            dict = 'misscarsteal4@actor',
            clip = 'actor_berating_loop',
            flag = 1
        },
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        }
    })

    if pb then
        lib.callback('uus_market:sellItem', false, function(cb)
            if cb then
                qbx:Notify('Success Sell ' .. exports.ox_inventory:Items(data.item).label, 'success')
            else
                qbx:Notify('Something Wrong Please Try Again', 'error')
            end
        end, newAmount, data.item, hasItem, price)
    end
end

local function sellItemsMenu()
    local svData = lib.callback.await('uus_martket:getCurrentData', false)
    local sellItems = {}
    local baseUrl = 'nui://ox_inventory/web/images/%s.png'
    for k, v in pairs(Config.SellItems) do
        for _, j in ipairs(svData) do
            if k == j.item then
                local hasItem = exports.ox_inventory:Search('count', k)
                local price = 0
                if j.amount > 30 then
                    price = v / 2
                elseif j.amount > 50 then
                    price = v / 3
                else
                    price = v
                end
                if hasItem > 0 then
                    sellItems[#sellItems + 1] = {
                        title = exports.ox_inventory:Items(k).label,
                        description = 'Price = ' .. price,
                        image = baseUrl:format(k),
                        icon = 'fa-solid fa-dollar-sign',
                        onSelect = function()
                            sellItem({ item = k, price = price, currentAmount = j.amount })
                        end
                    }
                else
                    sellItems[#sellItems + 1] = {
                        title = exports.ox_inventory:Items(k).label,
                        description = 'Price = ' .. price,
                        image = baseUrl:format(k),
                        icon = 'fa-solid fa-dollar-sign',
                        disabled = true
                    }
                end
            end
        end
    end
    lib.registerContext({
        id = 'uus_market:sellItemMenu',
        title = "Sell Items",
        options = sellItems
    })

    lib.showContext('uus_market:sellItemMenu')
end

local function buyItems(data)
    local money = QBX.PlayerData.money['bank']
    local input = lib.inputDialog('Amount To Buy', {
        { type = 'number', label = 'Amount', placeholder = '1' },
    })

    local price = input[1] * data.price
    if input[1] > data.currentAmount then
        qbx:Notify('Not Enough Stock', 'error')
    else
        if money > price then
            local pb = lib.progressBar({
                duration = 5000,
                label = "Discussing Price For " .. exports.ox_inventory:Items(data.item).label,
                canCancel = true,
                useWhileDead = false,
                anim = {
                    dict = 'misscarsteal4@actor',
                    clip = 'actor_berating_loop',
                    flag = 1
                },
                disable = {
                    move = true,
                    car = true,
                    mouse = false,
                    combat = true
                }
            })

            if pb then
                local newAmont = data.currentAmount - input[1]
                lib.callback('uus_market:buyItem', false, function(cb)
                    if cb then
                        qbx:Notify('Success Buy ' .. exports.ox_inventory:Items(data.item).label, 'success')
                    else
                        qbx:Notify('Something Wrong Please Try Again', 'error')
                    end
                end, newAmont, data.item, input[1], price)
            end
        else
            qbx:Notify('Not enough money', 'error')
        end
    end
end

local function buyItemsMenu()
    local svData = lib.callback.await('uus_martket:getCurrentData', false)
    local sellItems = {}
    local baseUrl = 'nui://ox_inventory/web/images/%s.png'
    for k, v in pairs(Config.BuyItems) do
        for _, j in ipairs(svData) do
            if k == j.item then
                local price = 0
                if j.amount > 30 then
                    price = v * 2
                elseif j.amount > 50 then
                    price = v * 3
                else
                    price = v * 1.5
                end
                if j.amount > 0 then
                    sellItems[#sellItems + 1] = {
                        title = exports.ox_inventory:Items(k).label,
                        description = 'Price = ' .. price,
                        metadata = {
                            { label = 'Stock', value = j.amount or 'None' }
                        },
                        image = baseUrl:format(k),
                        icon = 'fa-solid fa-dollar-sign',
                        onSelect = function()
                            buyItems({ item = k, price = price, currentAmount = j.amount })
                        end
                    }
                else
                    sellItems[#sellItems + 1] = {
                        title = exports.ox_inventory:Items(k).label,
                        description = 'Price = ' .. v,
                        image = baseUrl:format(k),
                        disabled = true,
                        icon = 'fa-solid fa-dollar-sign'
                    }
                end
            end
        end
    end
    lib.registerContext({
        id = 'uus_market:buyItemMenu',
        title = "Buy Items",
        options = sellItems
    })

    lib.showContext('uus_market:buyItemMenu')
end

local function openSellMenu()
    lib.registerContext({
        id = 'uus_market:openMarket',
        title = 'Market',
        options = {
            {
                title = 'Buy Items',
                icon = 'fa-shopping-bag',
                description = 'Buy Available Job Items Here',
                onSelect = buyItemsMenu
            },
            {
                title = 'Sell Items',
                icon = 'fa-solid fa-dollar-sign',
                description = 'Sell Available Job Items Here',
                onSelect = sellItemsMenu
            },
        },
    })
    lib.showContext('uus_market:openMarket')
end

local function createSeller()
    for _, current in pairs(Config.Locations) do
        current.model = type(current.model) == 'string' and joaat(current.model) or current.model
        lib.requestModel(current.model)
        local currentCoords = vec4(current.coords.x, current.coords.y, current.coords.z - 1, current.coords.w)
        spawnedPed = CreatePed(0, current.model, currentCoords.x, currentCoords.y, currentCoords.z, currentCoords.w,
            false,
            false)
        FreezeEntityPosition(spawnedPed, true)
        SetEntityInvincible(spawnedPed, true)
        SetBlockingOfNonTemporaryEvents(spawnedPed, true)
        exports.ox_target:addLocalEntity(spawnedPed, {
            {
                label = "Open Market",
                icon = 'fa-solid fa-dollar-sign',
                onSelect = openSellMenu,
            }
        })

        blips = AddBlipForCoord(current.coords.x, current.coords.y, current.coords.z)
        SetBlipSprite(blips, current.blipIcon)
        SetBlipDisplay(blips, 4)
        SetBlipScale(blips, 0.8)
        SetBlipAsShortRange(blips, true)
        SetBlipColour(blips, 9)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(current.blipLabel)
        EndTextCommandSetBlipName(blips)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        createSeller()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createSeller()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    DeleteEntity(spawnedPed)
    if not blips then return end
    for i = 1, #blips do
        local blip = blips[i]
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end)

AddEventHandler('onResourceStop', function(resource)
    if not cache.resource then return end
    DeleteEntity(spawnedPed)
    if not blips then return end
    for i = 1, #blips do
        local blip = blips[i]
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end)

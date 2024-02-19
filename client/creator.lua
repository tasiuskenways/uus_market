local pec = exports.uus_source:objPlacer()

RegisterNetEvent('uus_market:createMarket', function()
    local input = lib.inputDialog('UUS MARKET', {
        { type = 'input',  label = 'Models',     placeholder = 'mp_m_freemode_01' },
        { type = 'input',  label = 'Blip Label', placeholder = 'Job Market' },
        { type = 'number', label = 'Blip Icon' }
    })

    if not input then return end

    local newMarket = {}
    pec.placePed({
        model = input[1],
        onFinish = function(data)
            newMarket[#newMarket + 1] = {
                coords = data.pos,
                model = input[1],
                blipIcon = input[3],
                blipLabel = input[2]
            }

            TriggerServerEvent('uus_market:saveMarket', newMarket)
            newMarket = {}
        end
    })
end)

RegisterNetEvent('uus_market:addItems', function(type)
    local input = lib.inputDialog('Add Items', {
        { type = 'input',  label = 'Item Name', placeholder = 'burger', required = true },
        { type = 'number', label = 'Price',     required = true },
    })

    if not input then return end

    local newData = {}
    newData[input[1]] = input[2]
    TriggerServerEvent('uus_market:saveNewItems', type, newData)
end)

local function showUpdateOptions(item, price, type)
    local input = lib.inputDialog('Edit Items', {
        { type = 'input',    label = 'Item Name',    default = item },
        { type = 'number',   label = 'Price',        default = price },
        { type = 'checkbox', label = 'Delete Items', description = 'Check If You Want To Delete This Items' }
    })

    if not input then return end
    local newMarket = {
        [input[1]] = input[2]
    }
    if input[3] then
        TriggerServerEvent('uus_market:updateItems', { itemName = input[1], isDelete = true, type = type })
    else
        TriggerServerEvent('uus_market:updateItems', { newData = newMarket, isDelete = false, type = type })
    end
end

RegisterNetEvent('uus_market:listItems', function(type)
    local listItems = {}
    local title = ''
    local svData = lib.callback.await('uus_martket:getCurrentData', false)
    local baseUrl = 'nui://ox_inventory/web/images/%s.png'
    if type == 'buy' then
        title = 'List Buy Items'
        for k, v in pairs(Config.BuyItems) do
            for _, j in ipairs(svData) do
                if k == j.item then
                    listItems[#listItems + 1] = {
                        title = exports.ox_inventory:Items(k).label,
                        description = 'Click To Edit Items',
                        image = baseUrl:format(k),
                        icon = 'fa-solid fa-pen-to-square',
                        onSelect = function()
                            showUpdateOptions(k, v, 'buy')
                        end
                    }
                end
            end
        end
    else
        title = 'List Sell Items'
        for k, v in pairs(Config.SellItems) do
            for _, j in ipairs(svData) do
                if k == j.item then
                    listItems[#listItems + 1] = {
                        title = exports.ox_inventory:Items(k).label,
                        description = 'Click To Edit Items',
                        image = baseUrl:format(k),
                        icon = 'fa-solid fa-pen-to-square',
                        onSelect = function()
                            showUpdateOptions(k, v, 'sell')
                        end
                    }
                end
            end
        end
    end
    lib.registerContext({
        id = 'uus_market:listItems',
        title = title,
        options = listItems
    })

    lib.showContext('uus_market:listItems')
end)

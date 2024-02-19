lib.addCommand('addmarket', {
    help = 'Add a new market(Admin Only)',
    restricted = 'admin'
}, function(source, args, raw)
    TriggerClientEvent('uus_market:createMarket', source)
end)

local function mergeData(data)
    local merged = {}
    for _, v in ipairs(data) do
        merged[#merged + 1] = {
            coords = v.coords,
            model = v.model,
            blipIcon = v.blipIcon,
            blipLabel = v.blipLabel
        }
    end
    for _, v in ipairs(Config.Locations) do
        merged[#merged + 1] = {
            coords = v.coords,
            model = v.model,
            blipIcon = v.blipIcon,
            blipLabel = v.blipLabel
        }
    end
    return merged
end

RegisterNetEvent('uus_market:saveMarket', function(data)
    local mergedData = mergeData(data)
    local Model = [[
        {
            coords = %s,
            model = '%s',
            blipIcon = %s,
            blipLabel = "%s"
        },
    ]]

    local formated = {}
    for _, v in ipairs(mergedData) do
        formated[#formated + 1] = Model:format(
            v.coords,
            v.model,
            v.blipIcon,
            v.blipLabel
        )
    end

    GlobalState.uus_market_save_market = mergedData

    local serialized = ('return { \n%s}'):format(table.concat(formated, '\n'))
    SaveResourceFile(cache.resource, 'data/locations.lua', serialized, -1)
end)

lib.addCommand('addstoreitems', {
    help = 'Add Items To Market Store (Admin Only)',
    restricted = 'admin',
    params = {
        { name = 'type', help = 'buy / sell', type = 'string' },
    }
}, function(src, args, raw)
    if args.type == 'buy' then
        TriggerClientEvent('uus_market:addItems', src, 'buy')
    elseif args.type == 'sell' then
        TriggerClientEvent('uus_market:addItems', src, 'sell')
    else
        lib.notify(src, {
            title = 'UUS MARKET',
            description = 'INVALID TYPE',
            type = 'error'
        })
    end
end)

local function mergeItemsData(type, data)
    local itemType = {}
    local newData = {}
    if type == 'buy' then
        itemType = Config.BuyItems
    else
        itemType = Config.SellItems
    end

    for k, v in pairs(itemType) do
        newData[k] = v
    end
    for k, v in pairs(data) do
        newData[k] = v
    end

    return newData
end

local function refreshConfigItems()
    for k, v in pairs(Config.SellItems) do
        local result = MySQL.Sync.fetchScalar('SELECT item FROM uus_market WHERE item = ?', { k })
        if not result then
            MySQL.insert.await('INSERT INTO `uus_market` (item, amount) VALUES (?, ?)', {
                k, 0
            })
        end
    end
    for k, v in pairs(Config.BuyItems) do
        local result = MySQL.Sync.fetchScalar('SELECT item FROM uus_market WHERE item = ?', { k })
        if not result then
            MySQL.insert.await('INSERT INTO `uus_market` (item, amount) VALUES (?, ?)', {
                k, 0
            })
        end
    end
end

lib.addCommand('listmarketitems', {
    help = 'List Market Items (Admin Only)',
    restricted = 'admin',
    params = {
        { name = 'type', help = 'buy / sell', type = 'string' },
    }
}, function(src, args, raw)
    if args.type == 'buy' then
        TriggerClientEvent('uus_market:listItems', src, 'buy')
    elseif args.type == 'sell' then
        TriggerClientEvent('uus_market:listItems', src, 'sell')
    else
        lib.notify(src, {
            title = 'UUS MARKET',
            description = 'INVALID TYPE',
            type = 'error'
        })
    end
end)

RegisterNetEvent('uus_market:saveNewItems', function(type, data)
    local mergedData = mergeItemsData(type, data)
    local Model = [[
        ['%s'] = %s,
    ]]
    local saveData = {}

    if type == 'buy' then
        for k, v in pairs(mergedData) do
            saveData[#saveData + 1] = Model:format(k, v)
        end

        local serialized = ('return { \n%s}'):format(table.concat(saveData, '\n'))
        SaveResourceFile(cache.resource, 'data/buyitems.lua', serialized, -1)

        GlobalState.uus_market_save_buy_items = mergedData
        Config.BuyItems = mergedData
    else
        for k, v in pairs(mergedData) do
            saveData[#saveData + 1] = Model:format(k, v)
        end

        local serialized = ('return { \n%s}'):format(table.concat(saveData, '\n'))
        SaveResourceFile(cache.resource, 'data/sellitems.lua', serialized, -1)

        GlobalState.uus_market_save_sell_items = mergedData
        Config.SellItems = mergedData
    end
    refreshConfigItems()
end)

RegisterNetEvent('uus_market:updateItems', function(data)
    local Model = [[
        ['%s'] = %s,
    ]]
    local saveData = {}
    if data.isDelete then
        if data.type == 'buy' then
            Config.BuyItems[data.itemName] = nil

            for k, v in pairs(Config.BuyItems) do
                saveData[#saveData + 1] = Model:format(k, v)
            end

            local serialized = ('return { \n%s}'):format(table.concat(saveData, '\n'))
            SaveResourceFile(cache.resource, 'data/buyitems.lua', serialized, -1)

            GlobalState.uus_market_save_buy_items = Config.BuyItems
        else
            Config.SellItems[data.itemName] = nil

            for k, v in pairs(Config.SellItems) do
                saveData[#saveData + 1] = Model:format(k, v)
            end

            local serialized = ('return { \n%s}'):format(table.concat(saveData, '\n'))
            SaveResourceFile(cache.resource, 'data/sellitems.lua', serialized, -1)

            GlobalState.uus_market_save_sell_items = Config.SellItems
        end
    else
        if data.type == 'buy' then
            for k, v in pairs(data.newData) do
                Config.BuyItems[k] = v
            end

            for k, v in pairs(Config.BuyItems) do
                saveData[#saveData + 1] = Model:format(k, v)
            end

            local serialized = ('return { \n%s}'):format(table.concat(saveData, '\n'))
            SaveResourceFile(cache.resource, 'data/buyitems.lua', serialized, -1)

            GlobalState.uus_market_save_buy_items = Config.BuyItems
        else
            for k, v in pairs(data.newData) do
                Config.SellItems[k] = v
            end

            for k, v in pairs(Config.SellItems) do
                saveData[#saveData + 1] = Model:format(k, v)
            end

            local serialized = ('return { \n%s}'):format(table.concat(saveData, '\n'))
            SaveResourceFile(cache.resource, 'data/sellitems.lua', serialized, -1)

            GlobalState.uus_market_save_sell_items = Config.SellItems
        end
    end
    refreshConfigItems()
end)

AddEventHandler('onResourceStart', function(resource)
    refreshConfigItems()
end)

lib.versionCheck('tasiuskenways/uus_market')
lib.callback.register('uus_martket:getCurrentData', function(source)
    local response = MySQL.query.await('SELECT `item`, `amount` FROM `uus_market`')
    return response
end)

lib.callback.register('uus_market:buyItem', function(source, newAmount, item, amount, price)
    local player
    if Config.Framework == 'qbx' then
        player = exports.qbx_core:GetPlayer(source)
    elseif Config.Framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        player = QBCore.Functions.GetPlayer(source)
    end
    local affectedRows = MySQL.update.await('UPDATE uus_market SET amount = ? WHERE item = ?', {
        newAmount, item
    })

    if not affectedRows or affectedRows == 0 then
        return false
    else
        local success = exports.ox_inventory:AddItem(source, item, amount)
        if success then
            if not player.Functions.RemoveMoney('bank', price, 'Buy Item From Market') then return false end
            return true
        else
            return false
        end
    end
end)

lib.callback.register('uus_market:sellItem', function(source, newAmount, item, amount, price)
    local player
    if Config.Framework == 'qbx' then
        player = exports.qbx_core:GetPlayer(source)
    elseif Config.Framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        player = QBCore.Functions.GetPlayer(source)
    end
    local affectedRows = MySQL.update.await('UPDATE uus_market SET amount = ? WHERE item = ?', {
        newAmount, item
    })

    if not affectedRows or affectedRows == 0 then
        return false
    else
        local success = exports.ox_inventory:RemoveItem(source, item, amount)
        if success then
            if not player.Functions.AddMoney('bank', price, 'Buy Item From Market') then return false end
            return true
        else
            return false
        end
    end
end)

lib.callback.register('uus_market:buyItem', function(source, item, amount, price)
    local player
    if Config.Framework == 'qbx' then
        player = exports.qbx_core:GetPlayer(source)
    elseif Config.Framework == 'qb' then
        local QBCore = exports['qb-core']:GetCoreObject()
        player = QBCore.Functions.GetPlayer(source)
    end

    local response = MySQL.query.await('SELECT `amount` FROM `uus_market` WHERE `item` = ?', {
        item
    })

    if not response then
        return false
    end

    local serverAmount = response[1].amount

    if amount > serverAmount then
        return false
    end


    local affectedRows = MySQL.update.await('UPDATE uus_market SET amount = ? WHERE item = ?', {
        serverAmount - amount, item
    })

    if not affectedRows or affectedRows == 0 then
        return false
    else
        if not exports.ox_inventory:CanCarryItem(source, item, amount) then return false end
        local success = exports.ox_inventory:AddItem(source, item, amount)
        if success then
            if not player.Functions.RemoveMoney('bank', price, 'Buy Item From Market') then return false end
            return true
        else
            return false
        end
    end
end)

ESX = nil
local data = {}
local inventoryBusy = {}
local ammo

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('esx_armories:isInventoryBusy', function(source, cb, code)
	if (inventoryBusy[code]  == true) then
		cb(true)
	else
		cb(false)
	end
end)

RegisterServerEvent('esx_armories:inventoryBusy')
AddEventHandler('esx_armories:inventoryBusy', function(code, bool)
	inventoryBusy[code] = bool
end)

RegisterNetEvent('esx_armories:remove:swapItems')
AddEventHandler('esx_armories:remove:swapItems', function(item, count, code)
     local xPlayer = ESX.GetPlayerFromId(source)
     local inventoryItem = xPlayer.getInventoryItem(item).count
    
     if inventoryItem >= count then 
          xPlayer.removeInventoryItem(item, count)
          for i=1, count do
               MySQL.Async.execute('INSERT INTO storage (code, item, type) VALUES (@code, @item, @type)', {
                    ['@code'] = code,
                    ['@item'] = item,
                    ['@type'] = 'item'
               })
          end
     else
          TriggerClientEvent('esx:showNotification', xPlayer.source, 'Invalid Quantity')  
     end    
end)

RegisterNetEvent('esx_armories:remove:swapWeapons')
AddEventHandler('esx_armories:remove:swapWeapons', function(item, code, ammo)
     local xPlayer = ESX.GetPlayerFromId(source)

     xPlayer.removeWeapon(item)
     MySQL.Async.execute('INSERT INTO storage (code, item, type, ammo) VALUES (@code, @item, @type, @ammo)', {
          ['@code'] = code,
          ['@item'] = item,
          ['@type'] = 'weapon',
          ['@ammo'] = ammo
     })
end) 

RegisterNetEvent('esx_armories:add:swapWeapons')
AddEventHandler('esx_armories:add:swapWeapons', function(item, code)
     local xPlayer = ESX.GetPlayerFromId(source)

     MySQL.Async.fetchAll('SELECT ammo FROM storage WHERE code = @code AND item = @item', { 
          ['@code'] = code,
          ['@item'] = item
     },   function(result)
          if result[1] ~= nil then
               for k,v in pairs(result[1]) do 
                    ammo = v
               end
          end
     end)

     Wait(400)
    
     if not xPlayer.hasWeapon(item) then
          xPlayer.addWeapon(item, tonumber(ammo))
          MySQL.Async.execute('DELETE FROM storage WHERE code = @code AND item = @item LIMIT 1', {
               ['@code'] = code,
               ['@item'] = item
          })
     else
          TriggerClientEvent('esx:showNotification', xPlayer.source, 'You already have this weapon')
     end
end)

RegisterNetEvent('esx_armories:add:swapItems')
AddEventHandler('esx_armories:add:swapItems', function(item, count, code)
     local xPlayer = ESX.GetPlayerFromId(source)
     local sourceItem = xPlayer.getInventoryItem(item)

     MySQL.Async.fetchAll('SELECT * FROM storage WHERE code = @code AND item = @item', {
          ['@code']= code,
          ['@item'] = item
     }, function(result)
        
          if result ~= nil then
               local amount = 0
               for k, v in pairs(result) do
                    amount = amount + 1
               end
               if amount >= count then
                    if sourceItem.limit < count then
                         TriggerClientEvent('esx:showNotification', xPlayer.source, 'Invalid Quantity')
                         return
                    end
                    if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
                         TriggerClientEvent('esx:showNotification', xPlayer.source, 'Invalid Quantity')
                    else     
                         xPlayer.addInventoryItem(item, count)
                         TriggerClientEvent('esx:showNotification', xPlayer.source, 'You have withdrawn x'..count..' '..item)
                         for i=1, count do
                              MySQL.Async.execute('DELETE FROM storage WHERE code = @code AND item = @item LIMIT '..tostring(count), {
                              ['@code'] = code,
                              ['@item'] = item
                              })
                              break
                         end
                    end
               end
          end
     end)
end)

ESX.RegisterServerCallback('esx_armories:getServerData', function(source, cb)
     cb(data)
end)

ESX.RegisterServerCallback('esx_armories:getInventory', function(source, cb)
     local xPlayer = ESX.GetPlayerFromId(source)
     cb(xPlayer.getInventory())
end)

RegisterCommand('changecode', function(source, args, rawCommand)
     if args[1] ~= nil and string.len(args[1]) == 4 then
          local xPlayer = ESX.GetPlayerFromId(source)
          local senderIdentifier = getSteamIdentifier(xPlayer.source)
          local newCode = tostring(args[1])
          for k, v in pairs(data) do
               if senderIdentifier == v.identifier then
                    MySQL.Async.fetchAll('SELECT * FROM warehouses WHERE identifier = @identifier', {
                         ['@identifier'] = senderIdentifier
                    }, function(result)
                         if result ~= nil then
                              for k, v in pairs(result) do
                                   local oldCode = tostring(v.code)
                                   local oldLocation = vector3(v.x, v.y, v.z)
                                   MySQL.Async.execute('UPDATE warehouses SET code = @code WHERE identifier = @identifier', {
                                        ['@code'] = newCode,
                                        ['@identifier'] = senderIdentifier,
                                        ['@label'] = v.label
                                   }, function(result)
                                        data[oldCode] = nil
                                        data[newCode] = {
                                             identifier = senderIdentifier,
                                             location = oldLocation,
                                             label = v.label
                                        }
                                        TriggerClientEvent('esx:showNotification', xPlayer.source, 'You successfully set your new code to ' .. newCode)
                                   end)
                                   MySQL.Async.execute('UPDATE storage SET code = @code2 WHERE code = @code', {
                                        ['@code2'] = newCode,
                                        ['@code'] = oldCode
                                   })
                              end
                         end
                    end)
               end
          end
          TriggerClientEvent('esx:showNotification', xPlayer.source, 'You don\'t own a warehouse')
     end
end, false)

ESX.RegisterServerCallback('esx_armories:getStorageInventory', function(source, cb, code)
    MySQL.Async.fetchAll('SELECT * FROM storage WHERE code = @code', {
        ['@code'] = code
    }, function(result)
        local items = {}
        if result ~= nil then
            for k, v in pairs(result) do
                if v.type == 'item' then
                    if items[v.item] then
                        items[v.item] = items[v.item] + 1
                    else
                        items[v.item] = 1
                    end
                end
            end    
            cb(items)
        else
            cb(items)
        end
    end)
end)

ESX.RegisterServerCallback('esx_armories:getWeaponInventory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer.getLoadout())
end)

ESX.RegisterServerCallback('esx_armories:getWeaponStorageInventory', function(source, cb, code)
     MySQL.Async.fetchAll('SELECT * FROM storage WHERE code = @code', {
          ['@code'] = code
     }, function(result)
          local items = {}
          if result ~= nil then
               for k, v in pairs(result) do
                    if v.type == 'weapon' then
                         if items[v.item] then
                              items[v.item] = items[v.item] + 1
                         else
                              items[v.item] = 1
                         end
                    end
               end
               cb(items)
          else
               cb(items)
          end
     end)
end)

ESX.RegisterUsableItem('warehouse', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent('esx_armories:Itemtoclient', xPlayer.source, 1)
end)

RegisterServerEvent('esx_armories:updateLocation')
AddEventHandler('esx_armories:updateLocation', function(code, x, y, z)
     local xPlayer = ESX.GetPlayerFromId(source)
     MySQL.Async.execute('UPDATE warehouses SET x=@x,y=@y,z=@z WHERE code=@code',{
          ['@code'] = code,
          ['@x'] = x,
          ['@y'] = y, 
          ['@z'] = z
     })
     Wait(3000)
     xPlayer.showNotification('Armory moved successfully')
     TriggerClientEvent('esx_armories:allowLoop', -1)
end)

RegisterNetEvent('esx_armories:insertArmory')
AddEventHandler('esx_armories:insertArmory', function(code, label, coords)
     local xPlayer = ESX.GetPlayerFromId(source)
     local xItem = xPlayer.getInventoryItem('warehouse')
     local crew = MySQL.Sync.fetchScalar('SELECT crew FROM users WHERE identifier = @identifier', {['@identifier'] = xPlayer.identifier})
     MySQL.Async.fetchAll('SELECT * FROM warehouses WHERE code = @code', {
          ['@code'] = code
     }, function(results)
          if (#results > 0) then
               TriggerClientEvent('esx:showNotification', xPlayer.source, 'You can\'t use that password!')
          else
               MySQL.Async.fetchAll('SELECT * FROM warehouses WHERE identifier = @identifier', {
                    ['@identifier'] = getSteamIdentifier(xPlayer.source)
               }, function(results)
                    if (#results > 0) then
                         TriggerClientEvent('esx:showNotification', xPlayer.source, 'You can\'t have more than one armory!')
                    else
                         MySQL.Async.execute('INSERT INTO warehouses (identifier,label, code, x, y, z, crew) VALUES (@identifier,@label, @code, @x, @y, @z, @crew)', {
                              ['@identifier'] = getSteamIdentifier(xPlayer.source),
                              ['@label'] = label,
                              ['@code'] = code,
                              ['@x'] = coords.x,
                              ['@y'] = coords.y,
                              ['@z'] = coords.z - 0.97,
                              ['@crew'] = crew
                         }, function(affectedRows)
                              if xItem.count > 0 then
                                   xPlayer.removeInventoryItem('warehouse', 1)
                                   TriggerClientEvent('esx_armories:allowLoop', -1)
                                   data[code] = {
                                   identifier = getSteamIdentifier(xPlayer.source),
                                   location = vector3(coords.x, coords.y, coords.z-0.97),
                                   label = label
                                   }
                                   TriggerClientEvent('esx:showNotification', xPlayer.source, 'Your armory has been successfully created!')
                                   print("[^4"..GetCurrentResourceName().."^7] Armory created with code : ^4"..code.."^7 and label : ^4"..label.."^7")
                              end
                         end) 
                    end
               end)
          end
     end)
end)

RegisterCommand('deletearmory', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    local senderIdentifier = getSteamIdentifier(xPlayer.source)
    for k, v in pairs(data) do
        if senderIdentifier == v.identifier then
            MySQL.Async.fetchAll('SELECT * FROM warehouses WHERE identifier = @identifier', {
                ['@identifier'] = senderIdentifier
            }, function(result)
                if result ~= nil then
                    for k, v in pairs(result) do
                        local code = tostring(v.code)
                        MySQL.Async.execute('DELETE FROM warehouses WHERE identifier = @identifier', {
                            ['@identifier'] = senderIdentifier
                        }, function(result)
                            MySQL.Async.execute('DELETE FROM storage WHERE code = @code', {
                                ['@code'] = code
                            }, function(result)
                                data[code] = nil
                                TriggerClientEvent('esx_armories:allowLoop', -1)
                                TriggerClientEvent('esx:showNotification', xPlayer.source, 'Your warehouse has been deleted')
                            end)
                        end)
                    end
                end
            end)
            return
        end
    end

    TriggerClientEvent('esx:showNotification', xPlayer.source, 'You do not own a warehouse')
end, false)

MySQL.ready(function()
     MySQL.Async.fetchAll('SELECT * FROM warehouses', {}, function(result)
          if result ~= nil then
               for k, v in pairs(result) do
                    local location = vector3(v.x, v.y, v.z)
                    local code = tostring(v.code)
                    local label = v.label
                    local identifier = tostring(v.identifier)
                    data[code] = {
                         identifier = identifier,
                         location = location,
                         label = label
                    }
               end
          end
     end)
end)

RegisterCommand('removearmory', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    local code = tonumber(args[1])
    
     if xPlayer.getGroup() ~= 'user' then 
          for k, v in pairs(data) do
               MySQL.Async.fetchAll('SELECT * FROM warehouses WHERE code = @code', {
                    ['@code'] = code
               }, function(result)
                    if result ~= nil then
                         for k, v in pairs(result) do
                              local code = tostring(v.code)
                              MySQL.Async.execute('DELETE FROM warehouses WHERE code = @code', {
                                   ['@code'] = code
                              }, function(result)
                                   MySQL.Async.execute('DELETE FROM storage WHERE code = @code', {
                                        ['@code'] = code
                                   }, function(result)
                                        data[code] = nil
                                        TriggerClientEvent('esx:showNotification', xPlayer.source, 'You removed the warehouse with code : ' .. code .. '')
                                        TriggerClientEvent('esx_armories:allowLoop', -1)
                                   end)
                              end)
                         end
                    end
               end)
          end
     else 
          TriggerClientEvent('esx:showNotification', xPlayer.source, 'No permissions')
     end
end)

RegisterCommand('refresharmories', function(source, args, rawCommand)
     local xPlayer = ESX.GetPlayerFromId(source)
    
     if xPlayer.getGroup() ~= 'user' then
          TriggerClientEvent('esx_armories:allowLoop', -1)
     end
end)

function getSteamIdentifier(id)
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(id) - 1 do
        local raw = GetPlayerIdentifier(id, i)
        local source, value = raw:match("^([^:]+):(.+)$")
        if source and value then
            identifiers[source] = value
        end
    end
    return identifiers.steam
end
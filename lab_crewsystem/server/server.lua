ESX = nil

local PlayerCrew

local PlayerCrewGrade

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function sendInfo(source)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier
     Wait(2000)
     MySQL.Async.fetchAll('SELECT crew, crew_grade FROM users WHERE identifier = @identifier', {
          ['@identifier'] = identifier
     }, function(results)
          if results then
               TriggerClientEvent('lab_crewsystem:setCrew', xPlayer.source, results[1].crew, results[1].crew_grade)
               PlayerCrew = results[1].crew
               PlayerCrewGrade = results[1].crew_grade
          end
     end)
end

function getCrewServer(source)
     local xPlayer = ESX.GetPlayerFromId(source)
     return PlayerCrew
end

function getCrewGradeServer(source)
     local xPlayer = ESX.GetPlayerFromId(source)
     return PlayerCrewGrade
end

RegisterServerEvent('lab_crewsystem:playerJoined')
AddEventHandler('lab_crewsystem:playerJoined', function() 
     local xPlayer = ESX.GetPlayerFromId(source)
     sendInfo(xPlayer.source)
end)

RegisterServerEvent('lab_crewsystem:registerCrew')
AddEventHandler('lab_crewsystem:registerCrew', function(crew)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier
     
     MySQL.Async.fetchAll('SELECT * FROM users WHERE crew = @crew', {
          ['@crew'] = crew:lower()
     }, function(results)
          if (#results > 0) then
               xPlayer.showNotification('There is already a crew with this name.')
          else
               if xPlayer.getAccount('bank').money >= CrewConfig.RequiredMoney then
                    xPlayer.removeAccountMoney('bank', CrewConfig.RequiredMoney)
                    MySQL.Async.execute('UPDATE users SET crew = @crew, crew_grade = @crew_grade WHERE identifier = @identifier', {
                         ['@crew'] = crew:lower(),
                         ['@crew_grade'] = 'leader',
                         ['@identifier'] = identifier
                    }, function(rowsChanged)
                         if (rowsChanged > 0) then
                              
                              if xPlayer.canCarryItem('warehouse', 1) then 
                                   xPlayer.addInventoryItem('warehouse', 1)
                              end
                              
                              sendInfo(xPlayer.source)
                              
                              MySQL.Async.execute('INSERT INTO crew_list(identifier, crew, money, xp, rank) VALUES(@identifier, @crew, @money, @xp, @rank)', {
                                   ['@identifier'] = identifier,
                                   ['@crew'] = crew:lower(),
                                   ['@money'] = 0,
                                   ['@xp'] = 0,
                                   ['@rank'] = 0
                              })

                         end
                    end)
               else
                  xPlayer.showNotification('Not enough money to create a crew')
               end
          end
     end)

end)

RegisterServerEvent('lab_crewsystem:getReward')
AddEventHandler('lab_crewsystem:getReward', function(row, crew)
     local xPlayer = ESX.GetPlayerFromId(source)
     local rank = MySQL.Sync.fetchScalar('SELECT rank FROM crew_list WHERE crew = @crew',{['@crew'] = crew})
     if row.type == 'weapon' then
          if rank >= row.rank then
               if xPlayer.getInventoryItem(CrewConfig.RequiredItem).count >= row.requiredCount then
                    xPlayer.addWeapon(row.weapon, row.ammo)
                    xPlayer.removeInventoryItem(CrewConfig.RequiredItem, row.requiredCount)
               else
                    xPlayer.showNotification('You don\'t have enough crew coins, you need'.. row.requiredCount)
               end
          else
               xPlayer.showNotification('Your crew doesn\'t meet the required rank level to get this weapon')
          end
     elseif row.type == 'money' then
          if rank >= row.rank then
               if xPlayer.getInventoryItem(CrewConfig.RequiredItem).count >= row.requiredCount then
                    xPlayer.addMoney(row.amount)
                    xPlayer.removeInventoryItem(CrewConfig.RequiredItem, row.requiredCount)
               else
                    xPlayer.showNotification('You don\'t have enough crew coins, you need'.. row.requiredCount)
               end
          else
               xPlayer.showNotification('Your crew doesn\'t meet the required rank level to get the money')
          end
     elseif row.type == 'item' then
          if rank >= row.rank then
               if xPlayer.getInventoryItem(CrewConfig.RequiredItem).count >= row.requiredCount then
                    xPlayer.addInventoryItem(row.item, row.requiredCount)
                    xPlayer.removeInventoryItem(CrewConfig.RequiredItem, row.requiredCount)
               else
                    xPlayer.showNotification('You don\'t have enough crew coins, you need'.. row.requiredCount)
               end
          else
               xPlayer.showNotification('Your crew doesn\'t meet the required rank level to get this item')
          end
     end
end)

RegisterServerEvent('lab_crewsystem:deleteCrew')
AddEventHandler('lab_crewsystem:deleteCrew', function(crew)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier

     MySQL.Async.fetchAll('SELECT crew FROM users WHERE identifier = @identifier', {
          ['@identifier'] = identifier
     }, function(crewResults)
          if crewResults then
               crew = crewResults[1].crew
               MySQL.Async.fetchAll('SELECT * FROM users WHERE crew = @crew', {
                    ['crew'] = crew:lower()
               }, function(results)
                    if results then
                         local AllPlayers = ESX.GetPlayers()
                         for k, v in pairs(results) do
                              MySQL.Async.execute('UPDATE users SET crew = @crew, crew_grade = @crew_grade WHERE identifier = @identifier', {
                                   ['@crew'] = 'nocrew',
                                   ['@crew_grade'] = 'nocrew',
                                   ['@identifier'] = v.identifier
                              })
                         end

                         MySQL.Async.execute('DELETE FROM crew_list WHERE identifier = @identifier', {
                              ['@identifier'] = identifier
                         })

                         for i = 1, #AllPlayers, 1 do
                              local xPlayer = ESX.GetPlayerFromId(AllPlayers[i])
                              sendInfo(xPlayer.source)
                         end

                         xPlayer.showNotification("Crew deleted successfully")
                    else
                         xPlayer.showNotification("There is not such a crew")
                    end
               end)
          end
     end)
end)

RegisterServerEvent('lab_crewsystem:kickPlayer')
AddEventHandler('lab_crewsystem:kickPlayer', function(target)
     local xPlayer = ESX.GetPlayerFromId(source)
     local xTarget = ESX.GetPlayerFromIdentifier(target)
     MySQL.Async.execute('UPDATE users SET crew = @crew, crew_grade = @crew_grade WHERE identifier = @identifier', {
          ['@crew'] = 'nocrew',
          ['@crew_grade'] = 'nocrew',
          ['@identifier'] = xTarget.identifier
     }, function(rowsChanged)
          if (rowsChanged > 0) then
               xPlayer.showNotification('You kicked '.. GetPlayerName(xTarget.source))
               xTarget.showNotification('You have been kicked from your crew')
               sendInfo(xTarget.source)
          end
    end)
end)

RegisterServerEvent('lab_crewsystem:changeGrade')
AddEventHandler('lab_crewsystem:changeGrade', function(target, grade)
     local xPlayer = ESX.GetPlayerFromId(source)
     local xTarget = ESX.GetPlayerFromIdentifier(target)
     MySQL.Async.execute('UPDATE users SET crew_grade = @crew_grade WHERE identifier = @identifier', {
          ['@crew_grade'] = grade,
          ['@identifier'] = xTarget.identifier
     }, function(rowsChanged)
          if (rowsChanged > 0) then
               xPlayer.showNotification('You made changes to '.. GetPlayerName(xTarget.source)..' grade')
               xTarget.showNotification('Your grade has been changed to '..grade)
               sendInfo(xTarget.source)
          end
    end)
end)

RegisterServerEvent('lab_crewsystem:setPlayerCrew')
AddEventHandler('lab_crewsystem:setPlayerCrew', function(target, crew)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromIdentifier(target)

     MySQL.Async.execute('UPDATE users SET crew = @crew, crew_grade = @crew_grade WHERE identifier = @identifier', {
          ['@crew'] = crew,
          ['@crew_grade'] = 'rookie',
          ['@identifier'] = xTarget.identifier
     }, function(rowsChanged)
          if (rowsChanged > 0) then
               xPlayer.showNotification('You recruited '.. GetPlayerName(xTarget.source))
               xTarget.showNotification('You have been recruited to ' .. crew)
               sendInfo(xTarget.source)
          end
     end)
end)

RegisterServerEvent('lab_crewsystem:removeXP')
AddEventHandler('lab_crewsystem:removeXP', function(amount)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier

     MySQL.Async.fetchAll('SELECT name, identifier, crew FROM users WHERE identifier = @identifier', {
          ['identifier'] = identifier
     }, function(results)
          local crew = results[1].crew
          if crew == 'nocrew' then
               return
          end  
          if results then
               local crew = results[1].crew
               MySQL.Sync.execute('UPDATE `crew_list` SET `xp` = `xp` - @xp WHERE `crew` = @crew',{
                    ['@xp'] = amount, 
                    ['@crew'] = crew
               })
          end
     end)
end)

RegisterServerEvent('lab_crewsystem:addSocietyMoney')
AddEventHandler('lab_crewsystem:addSocietyMoney', function(crew, amount)
     local xPlayer = ESX.GetPlayerFromId(source)
     local money = xPlayer.getMoney()
     if money >= amount then
          MySQL.Sync.execute('UPDATE `crew_list` SET `money` = `money` + @money WHERE `crew` = @crew',{
               ['@money'] = amount, 
               ['@crew'] = crew
          })
          xPlayer.removeMoney(amount)
     else
          xPlayer.showNotification('You dont have enough money on you')
     end
end)

RegisterServerEvent('lab_crewsystem:removeSocietyMoney')
AddEventHandler('lab_crewsystem:removeSocietyMoney', function(crew, amount)
     local xPlayer = ESX.GetPlayerFromId(source)
     local money = MySQL.Sync.fetchScalar('SELECT money FROM `crew_list` WHERE crew = @crew',{['@crew'] = crew})
     if money >= amount then
          MySQL.Sync.execute('UPDATE `crew_list` SET `money` = `money` - @money WHERE `crew` = @crew',{
               ['@money'] = amount, 
               ['@crew'] = crew
          })
          xPlayer.addMoney(amount)
     else
          xPlayer.showNotification('Your crew society has '..money..'$')
     end
end)

RegisterServerEvent('lab_crewsystem:rankUP')
AddEventHandler('lab_crewsystem:rankUP', function(crew)
     local xPlayer = ESX.GetPlayerFromId(source)
     MySQL.Async.fetchAll('SELECT * FROM crew_list WHERE crew = @crew', {
          ['@crew'] = crew
     }, function(results)
          if tonumber(results[1].xp) >= tonumber(CrewConfig.XPforRankUp) then
               MySQL.Sync.execute('UPDATE `crew_list` SET `rank` = `rank` + @rank WHERE `crew` = @crew',{
                    ['@rank'] = 1, 
                    ['@crew'] = crew
               })
               MySQL.Sync.execute('UPDATE `crew_list` SET `xp` = `xp` - @xp WHERE `crew` = @crew',{
                    ['@xp'] = CrewConfig.XPforRankUp, 
                    ['@crew'] = crew
               })
          else
               xPlayer.showNotification('Not enough crew XP to rank up.')
          end
     end)
end)

RegisterServerEvent('lab_crewsystem:addXP')
AddEventHandler('lab_crewsystem:addXP', function(amount)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier

     MySQL.Async.fetchAll('SELECT name, identifier, crew FROM users WHERE identifier = @identifier', {
          ['identifier'] = identifier
     }, function(results)
          local crew = results[1].crew
          if crew == 'nocrew' then
               return
          end  
          if results then
               local crew = results[1].crew
               MySQL.Sync.execute('UPDATE `crew_list` SET `xp` = `xp` + @xp WHERE `crew` = @crew',{
                    ['@xp'] = amount, 
                    ['@crew'] = crew
               })
          end
     end)
end)

ESX.RegisterServerCallback('lab_crewsystem:getMembers', function(source, cb, crew)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier
     MySQL.Async.fetchAll('SELECT * FROM users WHERE crew = @crew', {
          ['@crew'] = crew:lower(),
     }, function(results)
          if results then
               cb(results)
          else
               cb(false)
          end
     end)
end)

ESX.RegisterServerCallback('lab_crewsystem:getCrewStatus', function(source, cb, crew)
     local xPlayer = ESX.GetPlayerFromId(source)
     local identifier = xPlayer.identifier
     MySQL.Async.fetchAll('SELECT * FROM crew_list WHERE identifier = @identifier AND crew = @crew', {
          ['@identifier'] = identifier,
          ['@crew'] = crew:lower()
     }, function(results)
          if results then
               cb(results)
          else
               cb(false)
          end
    end)
end)

ESX.RegisterServerCallback('lab_crewsystem:getOnlinePlayers', function(source, cb)
     local AllPlayers = ESX.GetPlayers()
     local you = ESX.GetPlayerFromId(source)
     local OnlinePlayers = {}
     for i = 1, #AllPlayers, 1 do
          local xPlayer = ESX.GetPlayerFromId(AllPlayers[i])
          table.insert(OnlinePlayers, {
               id = xPlayer.source,
               identifier = xPlayer.identifier,
               name = xPlayer.name
          })
     end
     cb(OnlinePlayers)
end)

ESX.RegisterServerCallback('lab_crewsystem:getArmoryLocation', function(source, cb, crew)
     MySQL.Async.fetchAll('SELECT * FROM warehouses WHERE crew = @crew', {
          ['@crew'] = crew
     }, function(results)
          if results then
               cb(results)
          else
               cb(nil)
          end
     end)
end)

RegisterCommand('setcrew', function(source, args, rawCommand)
     local xPlayer = ESX.GetPlayerFromId(source)
     local xTarget = ESX.GetPlayerFromId(args[1])
     if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
          MySQL.Async.fetchAll('SELECT * FROM crew_list WHERE crew = @crew', {
               ['@crew'] = args[2]
          }, function(results)
               if (#results > 0) then
                    if args[3] == 'leader' or args[3] == 'co-leader' or args[3] == 'member' or args[3] == 'rookie' then
                         MySQL.Async.execute('UPDATE users SET crew = @crew, crew_grade = @crew_grade WHERE identifier = @identifier', {
                              ['@identifier'] = xTarget.identifier,
                              ['@crew'] = args[2],
                              ['@crew_grade'] = args[3]
                         })
                         sendInfo(xTarget.source)
                    else
                         xPlayer.showNotification('That grade does not exist, existing grades(leader, , member, rookie)')
                    end
               else
                   xPlayer.showNotification('Crew with name '..args[2]..' does not exist')
               end
          end)
     else
          xPlayer.showNotification('You don\'t have permission to do this')
     end
end, false)
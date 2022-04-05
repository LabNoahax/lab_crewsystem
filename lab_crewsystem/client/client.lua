ESX = nil

local PlayerData = {}

CreateThread(function()
     while ESX == nil do
          TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
          Wait(0)
     end

     while ESX.GetPlayerData() == nil do
          Wait(10)
     end

	while ESX.GetPlayerData().job == nil do
          Wait(10)
     end
     
     PlayerData = ESX.GetPlayerData()

	TriggerServerEvent('lab_crewsystem:playerJoined')
	
end)


RegisterNetEvent('lab_crewsystem:setCrew')
AddEventHandler('lab_crewsystem:setCrew', function(crew, crew_grade)
     PlayerCrew = crew
     PlayerCrewGrade = crew_grade
end)

function getCrew()
     return PlayerCrew
end
 
function getCrewGrade()
     return PlayerCrewGrade
end

RegisterCommand('crewmenu', function(source, args, rawCommand)
     if PlayerCrew ~= 'nocrew' then
		OpenCrewMenu()
     else
          ESX.ShowNotification('You are not in a crew')
     end
end, false)

RegisterKeyMapping('crewmenu', 'Open Crew Menu', 'keyboard', 'F6')

function OpenCrewMenu()
     	local elements = {}

     	ESX.UI.Menu.CloseAll()

     	if PlayerCrewGrade == 'leader' then
	     	table.insert(elements, {label = '<span style="color:blue;">Crew Info</span>',  value = 'information'})	
		table.insert(elements, {label = '<span style="color:yellow;">Crew Rewards</span>',  value = 'rewards'})	
	    	table.insert(elements, {label = '<span style="color:orange;">Invite Player</span>',  value = 'invite'})	
	     	table.insert(elements, {label = '<span style="color:cyan;">Manage Members</span>',  value = 'manage'})	
	     	table.insert(elements, {label = '<span style="color:green;">Rank UP</span>', value = 'rank'})  
		table.insert(elements, {label = '<span style="color:pink;">Armory Password</span>', value = 'pwd'})  
		table.insert(elements, {label = '<span style="color:red;">Delete Crew</span>', value = 'delete'})
     	elseif PlayerCrewGrade == 'co-leader' then
          	table.insert(elements, {label = '<span style="color:blue;">Crew Info</span>',  value = 'information'})	
		table.insert(elements, {label = '<span style="color:yellow;">Crew Rewards</span>',  value = 'rewards'})	
	     	table.insert(elements, {label = '<span style="color:orange;">Invite Player</span>',  value = 'invite'})		
	    	table.insert(elements, {label = '<span style="color:green;">Rank UP</span>', value = 'rank'}) 
     	elseif PlayerCrewGrade == 'member' then
          	table.insert(elements, {label = '<span style="color:blue;">Crew Info</span>',  value = 'information'})	
		table.insert(elements, {label = '<span style="color:yellow;">Crew Rewards</span>',  value = 'rewards'})
     	elseif PlayerCrewGrade == 'rookie' then
          	table.insert(elements, {label = '<span style="color:blue;">Crew Info</span>',  value = 'information'})
    	end

     ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'Crew',
		{
			title = 'Crew Menu',	
			align    = 'right',
			elements = elements
		}, function(data, menu)
			if data.current.value == 'information' then
			     ShowCrewInformation(PlayerCrew)
			elseif data.current.value == 'rewards' then
				OpenRewardsMenu(PlayerCrew)
			elseif data.current.value == 'invite' then
				OpenInviteMenu(PlayerCrew)	
			elseif data.current.value == 'manage' then
				OpenManagementMenu(PlayerCrew)
			elseif data.current.value == 'rank' then
				RankUP(PlayerCrew)
			elseif data.current.value == 'delete' then
				DeleteCrew(PlayerCrew)
			elseif data.current.value == 'pwd' then
				ESX.TriggerServerCallback('lab_crewsystem:getArmoryLocation', function(results)
					if results[1] ~= nil then
						ESX.ShowNotification('You armory\'s password is : '..results[1].code)
					else
						ESX.ShowNotification('Your crew hasn\'t still got an armory')
					end
				end, PlayerCrew)
			end
		end, function(data, menu)
		menu.close()
	end)

end

function ShowCrewInformation(crew)
     local elements = {}
     
     ESX.UI.Menu.CloseAll()
     
     ESX.TriggerServerCallback('lab_crewsystem:getCrewStatus', function(result)
          table.insert(elements, {label = 'Crew XP : '..result[1].xp..'', value = 'nothing'})
          table.insert(elements, {label = 'Crew Rank : '..result[1].rank..'', value = 'nothing'})
          table.insert(elements, {label = 'Top Crews', value = 'top'})
		  table.insert(elements, {label = 'Show Armory Location', value = 'armory'})

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'Crew',
			{
				title = 'Crew Information',	
				align    = 'right',
				elements = elements
			}, function(data, menu)
				if data.current.value == 'nothing' then
					ESX.UI.Menu.CloseAll()
				elseif data.current.value == 'top' then
					ExecuteCommand('topcrews')	
				elseif data.current.value == 'armory' then
					ESX.TriggerServerCallback('lab_crewsystem:getArmoryLocation', function(results)
						if results[1] ~= nil then
							SetNewWaypoint(results[1].x, results[1].y)
						else
							ESX.ShowNotification('Your crew does not have an armory')
						end
					end, crew)
				end
			end, function(data, menu)
			menu.close()
		end) 
	end, crew)
end

function OpenInviteMenu(crew)
	ESX.UI.Menu.CloseAll()

	ESX.TriggerServerCallback('lab_crewsystem:getOnlinePlayers', function(players)
		local elements = {}

		for i = 1, #players, 1 do
			table.insert(elements, {
				label = players[i].name,
				value = players[i].identifier,
			})
		end
		
		ESX.UI.Menu.Open("default", GetCurrentResourceName(), "recruit_players", {
		  title = "Online Players",
		  align = "right",
		  elements = elements
		}, function(data, menu)
			
			ESX.UI.Menu.Open("default", GetCurrentResourceName(), "recruit_confirm", {
				title = "Are you sure?",
				align = "right",
				elements = {
					{label = '<span style="color:green;">YES</span>', value = "yes"},
					{label = '<span style="color:red;">NO</span>', value = "no"}
				}
			}, function(data2, menu2)
				menu2.close()
				if data2.current.value == "yes" then
					TriggerServerEvent('lab_crewsystem:setPlayerCrew', data.current.value, PlayerCrew)
					ESX.UI.Menu.CloseAll()
				else
					ESX.UI.Menu.CloseAll()
				end
			end, function(data2, menu2)
				menu2.close()
			end)

		end, function(data, menu)
		    menu.close()
		end)

	end)
end

function OpenManagementMenu(crew)
	
	ESX.UI.Menu.CloseAll()

	ESX.TriggerServerCallback('lab_crewsystem:getMembers', function(players)
		local elements = {}
		for i = 1, #players, 1 do
		    	table.insert(elements, {
			   	label = '['..players[i].name..' - '..players[i].crew_grade..']',
			   	value = players[i].identifier
		    	})
		end
		
		ESX.UI.Menu.Open("default", GetCurrentResourceName(), "manage_players", {
		    title = 'Management Menu',
		    align = "right",
		    elements = elements
		}, function(data, menu)
		    	ESX.UI.Menu.Open("default", GetCurrentResourceName(), "kick_confirm", {
			   	title = "Make changes",
			   	align = "right",
			   	elements = {
				  	{label = "Change Grade", value = "grade"},
				  	{label = "Kick", value = "kick"}
			   	}
		    	}, function(data2, menu2)
				if data2.current.value == 'kick' then
					TriggerServerEvent('lab_crewsystem:kickPlayer', data.current.value)
					ESX.UI.Menu.CloseAll()
				elseif data2.current.value == 'grade' then
					ESX.UI.Menu.CloseAll()
					ESX.UI.Menu.Open("default", GetCurrentResourceName(), "kick_confirm", {
						title = "Make changes",
						align = "right",
						elements = {
						    {label = "Leader", value = "leader"},
						    {label = "Co-Leader", value = "co-leader"},
						    {label = "Member", value = "member"},
						    {label = "Rookie", value = "rookie"}
						}
					}, function(data3, menu3)
						TriggerServerEvent('lab_crewsystem:changeGrade', data.current.value, data3.current.value, PlayerCrew)
						ESX.UI.Menu.CloseAll()
					end, function(data3, menu3)
						menu3.close()
					end)
				end
		    	end, function(data2, menu2)
			   	menu2.close()
		    	end)
		end, function(data, menu)
		    menu.close()
		end)
	end, PlayerCrew)
end

function RankUP(crew)
	local elements = {}
     
     ESX.UI.Menu.CloseAll()
     
     ESX.TriggerServerCallback('lab_crewsystem:getCrewStatus', function(result)
          table.insert(elements, {label = 'Crew XP : '..result[1].xp..' / '..CrewConfig.XPforRankUp..'', value = 'xp'})
          table.insert(elements, {label = 'Rank UP', value = 'rankup'})

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'Crew',
			{
				title = 'Rank UP',	
				align    = 'right',
				elements = elements
			}, function(data, menu)
				if data.current.value == 'xp' then
					ESX.ShowNotification('Your crew has '..result[1].xp..'')
					ESX.UI.Menu.CloseAll()
				elseif data.current.value == 'rankup' then
					TriggerServerEvent('lab_crewsystem:rankUP', crew)
					ESX.UI.Menu.CloseAll()	
				end
			end, function(data, menu)
			menu.close()
		end) 
	end, crew)
end

function OpenRewardsMenu(crew)
	local elements = {}
	ESX.TriggerServerCallback('lab_crewsystem:getCrewStatus', function(result)
          for k, v in pairs(CrewConfig.Rewards) do
			if v.type == 'item' then
          		table.insert(elements, {label = '<span style="color:blue;">'..v.label..'</span>', row = v})
			elseif v.type == 'money' then
				table.insert(elements, {label = '<span style="color:green;">'..v.label..'</span>', row = v})
			elseif v.type == 'weapon' then
				table.insert(elements, {label = '<span style="color:red;">'..v.label..'</span>', row = v})
			end
		end
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'Crew',
			{
				title = 'Crew Rewards',	
				align    = 'right',
				elements = elements
			}, function(data, menu)
				TriggerServerEvent('lab_crewsystem:getReward', data.current.row, PlayerCrew)
				ESX.UI.Menu.CloseAll()
			end, function(data, menu)
			menu.close()
		end) 
	end, crew)
end

function DeleteCrew(crew)
	ESX.UI.Menu.Open("default", GetCurrentResourceName(), "delete_confirm", {
		title = "Are you sure?",
		align = "right",
		elements = {
			{label = '<span style="color:green;">YES</span>', value = "yes"},
			{label = '<span style="color:red;">NO</span>', value = "no"}
		}
	}, function(data, menu)
		menu.close()
		if data.current.value == "yes" then
			TriggerServerEvent('lab_crewsystem:deleteCrew', PlayerCrew)
			ESX.UI.Menu.CloseAll()
		else
			ESX.UI.Menu.CloseAll()
		end
	end, function(data, menu)
		menu.close()
	end)
end


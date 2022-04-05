ESX = nil
local data = {}
local ped = nil
local coords = nil
local usedcode = {}
local activeforloop = false
local beingMoved = nil
local isMoving = false
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	
	while ESX.GetPlayerData().job == nil do
          Wait(10)
     end

	ESX.PlayerData = ESX.GetPlayerData()

	activeforloop = true
	Wait(3000)
	activeforloop = false

	TriggerServerEvent('lab_crewsystem:playerJoined')

end)

RegisterNetEvent('lab_crewsystem:setCrew')
AddEventHandler('lab_crewsystem:setCrew', function(crew, crew_grade)
     PlayerCrew = crew
     PlayerCrewGrade = crew_grade
end)

RegisterNetEvent('esx_armories:allowLoop')
AddEventHandler('esx_armories:allowLoop', function()
	activeforloop = true
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	while ESX.GetPlayerData() == nil do
		Citizen.Wait(10)
	end
	activeforloop = true
	Citizen.Wait(10000)
	activeforloop = false
end) 

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(2000)
		if activeforloop then
			ESX.TriggerServerCallback('esx_armories:getServerData', function(cb)
				data = cb
			end)
			Citizen.Wait(2000)
			activeforloop = false
		end
	end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
		sleep = false
		for k, v in pairs(data) do
			if #(coords - v.location) < 15.0 then
				sleep = true
				DrawMarker(1, v.location, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 140, false, true, 2, true, false, false, false)
			end
		end
		if not sleep then
			Wait(1000)
		end	
    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		for k, v in pairs(data) do
			if #(coords - v.location) < 1.2 then
				ESX.ShowHelpNotification("Press ~r~[E] ~w~to open ~r~"..v.label)
			end
			if #(coords - v.location) < 1.2 and IsControlJustPressed(0, 38) then
				ESX.TriggerServerCallback('esx_armories:isInventoryBusy', function(cb)
					if not cb then	
						if not usedcode[k] then 
							TriggerServerEvent('esx_armories:inventoryBusy', k, true)
							toggleField(true, k)
						else
							TriggerServerEvent('esx_armories:inventoryBusy', k, true)
							openSelectionMenu(k)
						end
					else
						ESX.ShowNotification('Armory is already being used')
					end
				end, k)
			end
		end
	end
end)

function openSelectionMenu(code)
	
	usedcode[code] = true

	FreezeEntityPosition(GetPlayerPed(-1), true)

	ClearPedTasksImmediately(PlayerPedId())

	TriggerEvent('closeInventory') 

	local elements = {}

	if PlayerCrewGrade == 'leader' then
		table.insert(elements, {label = "Deposit Item",  value = 'deposit_item'})	
		table.insert(elements, {label = "Withdraw Item",  value = 'withdraw_item'})	
		table.insert(elements, {label = "Deposit Weapon",  value = 'deposit_weapon'})	
		table.insert(elements, {label = "Withdraw Weapon", value = 'withdraw_weapon'})
		table.insert(elements, {label = "Deposit Money", value = 'deposit_money'})
		table.insert(elements, {label = "Withdraw Money", value = 'withdraw_money'})
		table.insert(elements, {label = "Move Armory", value = 'movearmory'})
	elseif PlayerCrewGrade == 'co-leader' then
		table.insert(elements, {label = "Deposit Item",  value = 'deposit_item'})	
		table.insert(elements, {label = "Withdraw Item",  value = 'withdraw_item'})	
		table.insert(elements, {label = "Deposit Weapon",  value = 'deposit_weapon'})	
		table.insert(elements, {label = "Withdraw Weapon", value = 'withdraw_weapon'})
		table.insert(elements, {label = "Deposit Money", value = 'deposit_money'})
	elseif PlayerCrewGrade == 'member' then
		table.insert(elements, {label = "Deposit Item",  value = 'deposit_item'})	
		table.insert(elements, {label = "Withdraw Item",  value = 'withdraw_item'})	
		table.insert(elements, {label = "Deposit Weapon",  value = 'deposit_weapon'})	
		table.insert(elements, {label = "Deposit Money", value = 'deposit_money'})
	elseif PlayerCrewGrade == 'rookie' then
		table.insert(elements, {label = "Deposit Item",  value = 'deposit_item'})	
		table.insert(elements, {label = "Deposit Weapon",  value = 'deposit_weapon'})
		table.insert(elements, {label = "Deposit Money", value = 'deposit_money'})	
	end

	

	ESX.UI.Menu.CloseAll()
	
	CreateThread(function()

		while not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'armory') do

			Wait(0)

		end


		while ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'armory') do

			Wait(0)

			TriggerEvent("closeInventory")

			TriggerEvent('esx_inventoryhud:canGiveItem',false)

			DisableControlAction(0 , 289 , true)

		end

		TriggerEvent('esx_inventoryhud:canGiveItem',true)

	end)
	
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory',

		{

			title = 'Armory',	
	
			align    = 'right',
	
			elements = elements

		}, function(data, menu)

			if data.current.value == 'deposit_item' then

				openDepositMenu(code)

			elseif data.current.value == 'withdraw_item' then

				openWithdrawMenu(code)	

			elseif data.current.value == 'deposit_weapon' then

				openWeaponDepositMenu(code)

			elseif data.current.value == 'withdraw_weapon' then

				openWeaponWithdrawMenu(code)

			elseif data.current.value == 'deposit_money' then

				openMoneyDepositMenu(code, PlayerCrew)

			elseif data.current.value == 'withdraw_money' then

				openMoneyWithdrawMenu(code, PlayerCrew)

			elseif data.current.value == 'movearmory' then

				MoveArmory(code)

			end

		end, function(data, menu)

		menu.close()

		FreezeEntityPosition(GetPlayerPed(-1), false)
		TriggerServerEvent('esx_armories:inventoryBusy', code, false)
	end)
end

function openMoneyWithdrawMenu(code, crew)
	FreezeEntityPosition(GetPlayerPed(-1), true)
	ClearPedTasksImmediately(PlayerPedId())
	TriggerEvent('closeInventory')
	
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'deposit_money_dialog', {
		title = 'Select an amount:'
	}, function(data, menu)
		local amount = tonumber(data.value)
		TriggerServerEvent('lab_crewsystem:removeSocietyMoney', crew, amount)
		TriggerServerEvent('esx_armories:inventoryBusy', code, false)
		FreezeEntityPosition(GetPlayerPed(-1), false)
		ESX.UI.Menu.CloseAll()
	end, function(data, menu)
		menu.close()
		FreezeEntityPosition(GetPlayerPed(-1), false)
	end)
end

function openMoneyDepositMenu(code, crew)
	FreezeEntityPosition(GetPlayerPed(-1), true)
	ClearPedTasksImmediately(PlayerPedId())
	TriggerEvent('closeInventory')
	
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'deposit_money_dialog', {
		title = 'Select an amount:'
	}, function(data, menu)
		local amount = tonumber(data.value)
		TriggerServerEvent('lab_crewsystem:addSocietyMoney', crew, amount)
		TriggerServerEvent('esx_armories:inventoryBusy', code, false)
		FreezeEntityPosition(GetPlayerPed(-1), false)
		ESX.UI.Menu.CloseAll()
	end, function(data, menu)
		menu.close()
		FreezeEntityPosition(GetPlayerPed(-1), false)
	end)
end

function openWeaponDepositMenu(code)
	ESX.TriggerServerCallback('esx_armories:getWeaponInventory', function(cb)
		local weapons = {}

		FreezeEntityPosition(GetPlayerPed(-1), true)
		for k, v in pairs(cb) do
			table.insert(weapons, {label = v.label .. ' ' .. '(' .. v.ammo .. ' ' .. 'ammo' .. ')', value = v.name})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'deposit_weapon', {
			title = 'Deposit Weapon',
			align    = 'right',
			elements = weapons
		}, function(data, menu)
			local item = tostring(data.current.value)
			local ammo = GetAmmoInPedWeapon(PlayerPedId(),item)

			local chk, wpn = GetCurrentPedWeapon(PlayerPedId())
			if wpn == GetHashKey(data.current.value) then    
				ESX.ShowNotification("Can't deposit weapons in your hand!")
				menu.close()
				return
			end
			
			ClearPedTasksImmediately(PlayerPedId())
			menu.close()
			ESX.ShowNotification("Depositing weapon, please wait..")
			FreezeEntityPosition(GetPlayerPed(-1), true)
			TriggerEvent('esx_thief:canSearch', false)
			local time = GetGameTimer() + math.random(1000,3000)
			while GetGameTimer() < time do
				DisableControlAction(0, 18)
				DisableControlAction(0, 289)
				TriggerEvent("closeInventory")
				ESX.UI.Menu.CloseAll()
				Wait(0)
				FreezeEntityPosition(GetPlayerPed(-1), true)
			end
			if IsEntityDead(PlayerPedId()) then            
				ESX.ShowNotification("Can't deposit while dead!")
				return
			end
			
			ClearPedTasksImmediately(PlayerPedId())
			menu.close()
	
			TriggerServerEvent('esx_armories:remove:swapWeapons', item, code, ammo)
			ESX.ShowNotification("Weapon Deposited")
			TriggerServerEvent('esx_armories:inventoryBusy', code, false)
			FreezeEntityPosition(GetPlayerPed(-1), false)
			TriggerEvent('esx_thief:canSearch', true)
			ESX.UI.Menu.CloseAll()
		end, function(data, menu)
			FreezeEntityPosition(GetPlayerPed(-1), false)
			ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'deposit_weapon')
		end)
	end)
end

function openDepositMenu(code)
	ESX.TriggerServerCallback('esx_armories:getInventory', function(cb)
		local items = {}
		FreezeEntityPosition(GetPlayerPed(-1), true)
		ClearPedTasksImmediately(PlayerPedId())
		TriggerEvent('closeInventory') 

		for k, v in pairs(cb) do
			if v.count > 0 then
				table.insert(items, {label = 'x' .. v.count .. ' ' .. v.label, value = v.name})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'deposit_item', {
			title = 'Deposit Item',
			align    = 'right',
			elements = items
		}, function(data, menu)
			local item = tostring(data.current.value)
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'deposit_item_dialog', {
				title = 'Select an amount:'
			}, function(data, menu)
				local amount = tonumber(data.value)
				TriggerServerEvent('esx_armories:remove:swapItems', item, amount, code)
					TriggerServerEvent('esx_armories:inventoryBusy', code, false)
					FreezeEntityPosition(GetPlayerPed(-1), false)
					ESX.UI.Menu.CloseAll()
			end, function(data, menu)
				menu.close()
				FreezeEntityPosition(GetPlayerPed(-1), false)
			end)
		end, function(data, menu)
			menu.close()
			FreezeEntityPosition(GetPlayerPed(-1), false)
		end)
	end)
end

function openWeaponWithdrawMenu(code)
	ESX.TriggerServerCallback('esx_armories:getWeaponStorageInventory', function(cb)
		local weapons = {}
		FreezeEntityPosition(GetPlayerPed(-1), true)
		ClearPedTasksImmediately(PlayerPedId())
		TriggerEvent('closeInventory') 
		for k, v in pairs(cb) do
			table.insert(weapons, {label = 'x' .. v .. ' ' .. ESX.GetWeaponLabel(k), value = k})
		end

		CreateThread(function()
			Wait(1000)
			while ESX.UI.Menu.IsOpen("default", GetCurrentResourceName(), 'withdraw_weapon') do
				Wait(500)
			end
			TriggerServerEvent('esx_armories:inventoryBusy', code, false)
		end)

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'withdraw_weapon', {
			title = 'Withdraw Weapon',
			align    = 'right',
			elements = weapons
		}, function(data, menu)
			local item = tostring(data.current.value)
			TriggerServerEvent('esx_armories:add:swapWeapons', item, code)
			FreezeEntityPosition(GetPlayerPed(-1), false)
			TriggerServerEvent('esx_armories:inventoryBusy', k, false)
			ESX.UI.Menu.CloseAll()
		end, function(data, menu)
			FreezeEntityPosition(GetPlayerPed(-1), false)
			TriggerServerEvent('esx_armories:inventoryBusy', code, false)
			ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'withdraw_weapon')
		end)
	end, code)
end


function openWithdrawMenu(code)
	ESX.TriggerServerCallback('esx_armories:getStorageInventory', function(cb)
		local items = {}
		FreezeEntityPosition(GetPlayerPed(-1), true)
		ClearPedTasksImmediately(PlayerPedId())
		TriggerEvent('closeInventory') 


		for k, v in pairs(cb) do
			table.insert(items, {label = 'x' .. v .. ' ' .. k, value = k}) -- add label
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'withdraw_item', {
			title = 'Withdraw Item',
			align    = 'right',
			elements = items
		}, function(data, menu)
		local item = tostring(data.current.value)
		ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'withdraw_item_dialog', {
			title = 'Select an amount:'
		}, function(data, menu)
			local amount = tonumber(data.value)
			TriggerServerEvent('esx_armories:add:swapItems', item, amount, code)
			ESX.UI.Menu.CloseAll()
			FreezeEntityPosition(GetPlayerPed(-1), false)
			TriggerServerEvent('esx_armories:inventoryBusy', code, false)
		end, function(data, menu)
			ESX.UI.Menu.Close('dialog', GetCurrentResourceName(), 'withdraw_item_dialog')
			FreezeEntityPosition(GetPlayerPed(-1), false)
			TriggerServerEvent('esx_armories:inventoryBusy', code, false)
		end)
	end, function(data, menu)
		ESX.UI.Menu.Close('default', GetCurrentResourceName(), 'withdraw_item')
		FreezeEntityPosition(GetPlayerPed(-1), false)
		TriggerServerEvent('esx_armories:inventoryBusy', code, false)
		end)
	end, code)
end

RegisterNetEvent("esx_armories:Itemtoclient")
AddEventHandler("esx_armories:Itemtoclient", function()
	TriggerEvent('closeInventory') 

	Wait(300)
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'esx_armories:Dialog',
	{
		title    = 'Enter Password (Numbers Only)',
		align    = 'right',
		elements = elements
	}, function(data, menu)
		ESX.UI.Menu.CloseAll()
		if (string.match(data.value,"[^%d]")==nil) and data.value ~= nil and data.value ~= "" then
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'esx_armories:Dialog',
			{
				title    = 'Enter your armory\'s name',
				align    = 'right',
				elements = elements
			}, function(data2, menu)
				if data2.value ~= nil and data2.value ~= "" then
					ESX.UI.Menu.CloseAll()
					TriggerServerEvent("esx_armories:insertArmory", data.value, data2.value, GetEntityCoords(PlayerPedId()))	
				else
					ESX.ShowNotification("Error: Enter a text")
				end
			end, function(data2, menu)
				menu.close()
			end)
		else
			ESX.ShowNotification("Error: Numbers Only")
		end
	end, function(data, menu)
		menu.close()
	end)
end)

function toggleField(enable, pass)
	SetNuiFocus(enable, enable)
	if pass then
		SendNUIMessage({
			type = "enableui",
			enable = enable,
			action = pass
		})
	end
end

RegisterNUICallback('escape', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('try', function(data, cb)
	SetNuiFocus(false, false)
	local code = data.code
	local warehouseCode = data.warehouseCode
	if code == warehouseCode then
		openSelectionMenu(code)
	else
		TriggerServerEvent('esx_armories:inventoryBusy', warehouseCode, false)
		ESX.ShowNotification('The password is not correct. Please try again!')
	end
	cb('ok')
end)

Citizen.CreateThread(function()
	Wait(50)
	local notinmenu = false
	while true do
		while ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'armory') or ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'withdraw_item') or ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'withdraw_weapon') or ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'deposit_item') or ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'deposit_weapon') do
			DisableControlAction(0, 289)  
			DisableControlAction(0, 57)
			DisableControlAction(0, 51)
			FreezeEntityPosition(GetPlayerPed(-1), true)
			DisableControlAction(0, 73)
			notinmenu = true
			Wait(0)
		end
		Wait(500) 
	end
	if not notinmenu then
		Wait(1000)
	end	
end)

function MoveArmory(code)
	TriggerServerEvent('esx_armories:inventoryBusy', code, false)
	isMoving = true
	beingMoved = code
	ESX.UI.Menu.CloseAll()
	FreezeEntityPosition(GetPlayerPed(-1), false)
	CreateThread(function()
		while isMoving do
			Wait(750)
			if GetVehiclePedIsIn(PlayerPedId(),false) ~= 0 then
				ESX.ShowNotification("Can't use a vehicle while moving your amory!")
				isMoving = false
				beingMoved = nil
			elseif IsEntityAttached(PlayerPedId()) then
				ESX.ShowNotification("Can't be carried moving your amory!")
				isMoving = false
				beingMoved = nil
			elseif IsEntityDead(PlayerPedId()) then
				ESX.ShowNotification("Can't move your armory while dead... Kinda obvious I suppose!")
				isMoving = false
				beingMoved = nil
			end
		end
	end)
	while isMoving do
		Wait(0)
		local coords = GetEntityCoords(GetPlayerPed(-1))
		DrawMarker(1, coords.x, coords.y, coords.z - 1, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 0, 255, 100, false, true, 2, false, false, false, false)

		DrawMessage("Press [~b~E~s~] to put armory here.\nPress [~b~BACKSPACE~s~] to cancel.")
		if IsControlPressed(0, 38) then
			local coords2 = {x = coords.x, y = coords.y, z = coords.z - 1.0} 
			TriggerServerEvent('esx_armories:updateLocation', code, coords2.x,coords2.y, coords2.z)
	
			isMoving = false
			beingMoved = nil
		elseif IsControlPressed(0, 177) or IsControlPressed(0, 200) then
			isMoving = false
			beingMoved = nil
		end
	end
end


function DrawMessage(text)
	SetTextFont(4)
	SetTextProportional(0)
	SetTextScale(0.0, 0.5)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(0.5, 0.8)
end
# lab_crewsystem
Crew System made by Lab#0101 for Noahax Team

#Do not Resell

#Noahax Development Team 

https://discord.gg/rjKN9Vwxc7

#No support given cause the script is clean code

** EXAMPLE ON HOW TO CREATE A CREW**

``RegisterCommand('createcrew', function(source, args, rawCommand)
    if args[1] then
        TriggerServerEvent(lab_crewsystem:registerCrew', args[1]) 
    else
        ESX.ShowNotification('Invalid arguments')
    end
end, false)``

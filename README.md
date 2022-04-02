``Crew System made by Lab#5863 for Noahax Team``

``Reselling is not allowed``

-- Noahax Development Team Discord --

https://discord.gg/rjKN9Vwxc7

** EXAMPLE ON HOW TO CREATE A CREW **

```
RegisterCommand('createcrew', function(source, args, rawCommand)
    if args[1] then
        TriggerServerEvent(lab_crewsystem:registerCrew', args[1]) 
    else
        ESX.ShowNotification('Invalid arguments')
    end
end, false)
```

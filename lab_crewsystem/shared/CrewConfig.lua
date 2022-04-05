CrewConfig = {}

CrewConfig.RequiredMoney = 10000

CrewConfig.Location = vector3(145.67, 25.64, 32.4)

CrewConfig.BotHeading = 234.66

CrewConfig.XPforRankUp = 5000

CrewConfig.Rewards = {
     {label = 'Assault Rifle', rank = 5, type = 'weapon', ammo = math.random(100, 200), weapon = 'WEAPON_ASSAULTRIFLE'},
     {label = '5000$', rank = 3, type = 'money', amount = 5000},
     {label = 'Bread', rank = 1, type = 'item', amount = 3, item = 'bread'},
}

CrewConfig.RequiredItem = 'crewcoin'
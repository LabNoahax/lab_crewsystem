fx_version 'cerulean'

game 'gta5'

author 'Lab'

description 'Crew System for DayZ Survival'

client_scripts {
     'shared/CrewConfig.lua',
     'client/client.lua',
     'client/armories.lua'
}

server_scripts {
     '@mysql-async/lib/MySQL.lua',
     'shared/CrewConfig.lua',
     'server/server.lua',
     'server/armories.lua'
}

ui_page   'html/index.html'

files {
     'html/index.html', 
     'html/index.js', 
     'html/index.css',
     'html/numField.mp3',
     'html/*.png',
}

exports {
     'getCrew',
     'getCrewGrade'
}

server_exports {
     'getCrewServer',
     'getCrewGradeServer'
}
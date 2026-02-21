fx_version 'cerulean'
game 'gta5'

author 'Max'
description 'No Hesi Score'
version '1.0.0'

shared_script '@ox_lib/init.lua'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

ui_page 'html/ui.html'
files {
    'html/ui.html',
    'html/style.css'
}
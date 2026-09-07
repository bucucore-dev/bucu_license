fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bucu_license'
author 'BUCU Core Development Team'
description 'BUCU License & Physical Identity Cards System (KTP, SIM Mobil, SIM Motor, Senjata Api, Pilot)'
version '1.0.0'

shared_scripts {
    '@bucu_shared/shared/config.lua',
    '@bucu_shared/shared/locales.lua',
    'locales/id.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/images/*.png'
}

exports {
    'ShowLicenseCard',
    'ShowLicenseToNearby',
    'GetPlayerLicenses',
    'HasLicense'
}

server_exports {
    'GetLicenses',
    'HasLicense',
    'GrantLicense',
    'RevokeLicense'
}

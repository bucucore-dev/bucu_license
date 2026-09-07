-- ============================================================================
-- BUCU License & Identity Cards — Configuration
-- Supports: KTP (Citizen ID), SIM Mobil, SIM Motor, SIM Truk, Senjata Api, Pilot, Boat
-- Multi-Mode: Roleplay Whitelist, Public Kiosk, or Dynamic Hybrid
-- ============================================================================

Config = Config or {}

Config.Debug = false
Config.DefaultLocale = 'id' -- 'id' or 'en'

-- Max distance (in meters) to detect nearby players when presenting a physical card
Config.ShowDistance = 2.5

-- Play ped presentation animation when showing cards
Config.PlayAnimation = true
Config.Animation = {
    dict = 'mp_common',
    anim = 'givetake2_a',
    duration = 2000
}

-- ============================================================================
-- Licensing Issuance Policy
-- 'roleplay': Wajib melalui petugas whitelist on-duty (bucu_police_job / bucu_government_job)
-- 'kiosk'   : Kiosk mandiri selalu aktif untuk semua warga di kantor masing-masing
-- 'hybrid'  : Prioritas petugas (jika ada petugas on-duty, warga wajib lewat petugas; jika nihil, kiosk mandiri otomatis terbuka)
-- ============================================================================
Config.IssuanceMode = 'hybrid' -- 'roleplay', 'kiosk', or 'hybrid'

-- Department Whitelist Assignments
Config.DepartmentJobs = {
    ['police'] = {
        jobName = 'police',
        label = 'Kepolisian & Samsat Wilayah Hukum Bucu',
        licenses = { 'driver_car', 'driver_bike', 'driver_truck', 'weapon' }
    },
    ['government'] = {
        jobName = 'government',
        label = 'Pemerintah Kota & Dinas Kependudukan Bucu',
        licenses = { 'id_card', 'pilot', 'boat' }
    }
}

-- Registry of physical cards supported by BUCU Core
Config.Cards = {
    ['id_card'] = {
        type = 'id_card',
        item = 'id_card',
        label = 'Kartu Tanda Penduduk (KTP)',
        shortLabel = 'KTP',
        authority = 'PEMERINTAH KOTA BUCU',
        department = 'DINAS KEPENDUDUKAN & PENCATATAN SIPIL',
        theme = 'ktp',
        badgeColor = '#0ea5e9',
        gradient = 'linear-gradient(135deg, #1e3a8a 0%, #0c4a6e 60%, #082f49 100%)',
        accentColor = '#38bdf8',
        icon = 'images/id_card.png',
        watermark = 'BUCU CITY REGISTRY',
        lifetime = true, -- Seumur Hidup
        price = 250,
        issuerJob = 'government',
        minGrade = 0,
        showCommand = 'showid'
    },
    ['driver_car'] = {
        type = 'driver_car',
        item = 'driver_license',
        label = 'SIM Golongan A (Mobil)',
        shortLabel = 'SIM A',
        authority = 'KORLANTAS KEPOLISIAN BUCU',
        department = 'DIREKTORAT LALU LINTAS WILAYAH HUKUM',
        theme = 'sim_car',
        badgeColor = '#db2777',
        gradient = 'linear-gradient(135deg, #be185d 0%, #831843 60%, #500724 100%)',
        accentColor = '#f472b6',
        icon = 'images/driver_license.png',
        watermark = 'DRIVING LICENSE • CLASS A',
        lifetime = false,
        validityYears = 5,
        price = 500,
        issuerJob = 'police',
        minGrade = 1,
        showCommand = 'showdriver'
    },
    ['driver_bike'] = {
        type = 'driver_bike',
        item = 'driver_bike',
        label = 'SIM Golongan C (Sepeda Motor)',
        shortLabel = 'SIM C',
        authority = 'KORLANTAS KEPOLISIAN BUCU',
        department = 'DIREKTORAT LALU LINTAS WILAYAH HUKUM',
        theme = 'sim_bike',
        badgeColor = '#f59e0b',
        gradient = 'linear-gradient(135deg, #d97706 0%, #92400e 60%, #78350f 100%)',
        accentColor = '#fbbf24',
        icon = 'images/driver_bike.png',
        watermark = 'MOTORCYCLE PERMIT • CLASS C',
        lifetime = false,
        validityYears = 5,
        price = 350,
        issuerJob = 'police',
        minGrade = 1,
        showCommand = 'showbike'
    },
    ['driver_truck'] = {
        type = 'driver_truck',
        item = 'driver_truck',
        label = 'SIM Golongan B (Truk & Niaga)',
        shortLabel = 'SIM B',
        authority = 'KORLANTAS KEPOLISIAN BUCU',
        department = 'DIREKTORAT ANGKUTAN BARANG & KOMERSIAL',
        theme = 'sim_truck',
        badgeColor = '#ea580c',
        gradient = 'linear-gradient(135deg, #c2410c 0%, #7c2d12 60%, #431407 100%)',
        accentColor = '#fb923c',
        icon = 'images/driver_truck.png',
        watermark = 'COMMERCIAL TRUCK PERMIT • CLASS B',
        lifetime = false,
        validityYears = 5,
        price = 750,
        issuerJob = 'police',
        minGrade = 2,
        showCommand = 'showtruck'
    },
    ['weapon'] = {
        type = 'weapon',
        item = 'weapon_license',
        label = 'Surat Izin Senjata Api (Concealed Carry)',
        shortLabel = 'SENJATA',
        authority = 'POLICE DEPARTMENT INTERNAL AFFAIRS',
        department = 'BIRO PENGAWASAN SENJATA & AMUNISI',
        theme = 'weapon',
        badgeColor = '#ca8a04',
        gradient = 'linear-gradient(135deg, #334155 0%, #1e293b 50%, #0f172a 100%)',
        accentColor = '#facc15',
        icon = 'images/weapon_license.png',
        watermark = 'CONCEALED FIREARM PERMIT',
        lifetime = false,
        validityYears = 3,
        price = 2500,
        issuerJob = 'police',
        minGrade = 3,
        showCommand = 'showweapon'
    },
    ['pilot'] = {
        type = 'pilot',
        item = 'pilot_license',
        label = 'Lisensi Penerbang Sipil (Pilot Permit)',
        shortLabel = 'PILOT',
        authority = 'BUCU CIVIL AVIATION AUTHORITY',
        department = 'DIREKTORAT KELAYAKAN UDARA & OPERASI',
        theme = 'pilot',
        badgeColor = '#0284c7',
        gradient = 'linear-gradient(135deg, #0369a1 0%, #075985 60%, #0c4a6e 100%)',
        accentColor = '#7dd3fc',
        icon = 'images/pilot_license.png',
        watermark = 'CIVIL AVIATION PILOT LICENSE',
        lifetime = false,
        validityYears = 2,
        price = 5000,
        issuerJob = 'government',
        minGrade = 2,
        showCommand = 'showpilot'
    },
    ['boat'] = {
        type = 'boat',
        item = 'boat_license',
        label = 'Surat Izin Berlayar (Nautical Boat Permit)',
        shortLabel = 'PELAUT',
        authority = 'BUCU MARITIME & PORT AUTHORITY',
        department = 'DIREKTORAT KEPELABUHANAN & KELAUTAN',
        theme = 'boat',
        badgeColor = '#0d9488',
        gradient = 'linear-gradient(135deg, #0f766e 0%, #115e59 60%, #134e4a 100%)',
        accentColor = '#5eead4',
        icon = 'images/boat_license.png',
        watermark = 'MARITIME CAPTAIN PERMIT',
        lifetime = false,
        validityYears = 3,
        price = 1500,
        issuerJob = 'government',
        minGrade = 1,
        showCommand = 'showboat'
    }
}

-- Physical Kiosks & Department Desks in the City
Config.Locations = {
    ['cityhall_kiosk'] = {
        id = 'cityhall_kiosk',
        label = 'Layanan Kependudukan & Balai Kota',
        department = 'government',
        coords = vector3(-544.8, -204.3, 38.2),
        pedCoords = vector4(-544.8, -204.3, 37.2, 210.0),
        pedModel = 'a_m_m_hasjew_01',
        blip = { sprite = 419, color = 3, scale = 0.7, label = 'Balai Kota — Perizinan Sipil' },
        allowedLicenses = { 'id_card', 'pilot', 'boat' }
    },
    ['police_missionrow_kiosk'] = {
        id = 'police_missionrow_kiosk',
        label = 'Samsat & Perizinan Kepolisian (Mission Row)',
        department = 'police',
        coords = vector3(441.2, -981.8, 30.7),
        pedCoords = vector4(441.2, -981.8, 29.7, 90.0),
        pedModel = 's_m_y_cop_01',
        blip = { sprite = 523, color = 38, scale = 0.7, label = 'Samsat — SIM & Senjata' },
        allowedLicenses = { 'driver_car', 'driver_bike', 'driver_truck', 'weapon' }
    },
    ['police_sandyshores_kiosk'] = {
        id = 'police_sandyshores_kiosk',
        label = 'Samsat & Perizinan Polisi (Sandy Shores)',
        department = 'police',
        coords = vector3(1853.2, 3686.4, 34.3),
        pedCoords = vector4(1853.2, 3686.4, 33.3, 215.0),
        pedModel = 's_m_y_sheriff_01',
        blip = { sprite = 523, color = 38, scale = 0.65, label = 'Samsat Sandy Shores' },
        allowedLicenses = { 'driver_car', 'driver_bike', 'driver_truck', 'weapon' }
    },
    ['police_paleto_kiosk'] = {
        id = 'police_paleto_kiosk',
        label = 'Samsat & Perizinan Polisi (Paleto Bay)',
        department = 'police',
        coords = vector3(-449.2, 6013.0, 31.7),
        pedCoords = vector4(-449.2, 6013.0, 30.7, 315.0),
        pedModel = 's_m_y_sheriff_01',
        blip = { sprite = 523, color = 38, scale = 0.65, label = 'Samsat Paleto Bay' },
        allowedLicenses = { 'driver_car', 'driver_bike', 'driver_truck', 'weapon' }
    }
}

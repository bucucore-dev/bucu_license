-- ============================================================================
-- BUCU License System — Client Engine
-- Ped animations, 3D card presentation, physical kiosks, and officer console
-- ============================================================================

local isCardOpen = false
local currentCardData = nil
local spawnedPeds = {}

-- Helper: Request and load animation dictionary
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 100
        while not HasAnimDictLoaded(dict) and timeout > 0 do
            Wait(10)
            timeout = timeout - 1
        end
    end
end

-- Play realistic physical card presentation animation
local function PlayCardAnimation()
    if not Config.PlayAnimation then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local anim = Config.Animation or { dict = 'mp_common', anim = 'givetake2_a', duration = 2000 }
    LoadAnimDict(anim.dict)

    TaskPlayAnim(ped, anim.dict, anim.anim, 8.0, -8.0, anim.duration or 2000, 49, 0, false, false, false)
end

-- Find nearest active player ped within distance
local function GetClosestPlayer(maxDist)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()
    local closestPlayer = -1
    local closestDist = maxDist or Config.ShowDistance

    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= myPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)
            if dist < closestDist then
                closestDist = dist
                closestPlayer = player
            end
        end
    end

    return closestPlayer, closestDist
end

-- Get list of all nearby citizens for officer console
local function GetNearbyCitizens(maxDist)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()
    local list = {}

    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= myPed and DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(myCoords - targetCoords)
            if dist <= (maxDist or 6.0) then
                local serverId = GetPlayerServerId(player)
                table.insert(list, {
                    serverId = serverId,
                    name = GetPlayerName(player),
                    distance = math.floor(dist * 10) / 10
                })
            end
        end
    end
    return list
end

-- ─── Physical Blips & Kiosk Service Desks ────────────────────────────────────

CreateThread(function()
    for locId, loc in pairs(Config.Locations or {}) do
        if loc.blip then
            local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
            SetBlipSprite(blip, loc.blip.sprite or 523)
            SetBlipColour(blip, loc.blip.color or 3)
            SetBlipScale(blip, loc.blip.scale or 0.7)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(loc.blip.label or loc.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Proximity loop for interaction at service desks
CreateThread(function()
    while true do
        local sleep = 1200
        local ped = PlayerPedId()
        if not isCardOpen and not IsPedInAnyVehicle(ped, false) then
            local coords = GetEntityCoords(ped)

            for locId, loc in pairs(Config.Locations or {}) do
                local dist = #(coords - loc.coords)
                if dist < 6.0 then
                    sleep = 0
                    DrawMarker(2, loc.coords.x, loc.coords.y, loc.coords.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 56, 189, 248, 160, false, false, 2, true, nil, nil, false)

                    if dist < 1.8 then
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName("Tekan ~INPUT_CONTEXT~ untuk " .. loc.label)
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if IsControlJustReleased(0, 38) then -- Key E
                            TriggerServerEvent('bucu:license:server:interactLocation', locId)
                            Wait(500)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ─── Event Handlers ─────────────────────────────────────────────────────────

RegisterNetEvent('bucu:license:client:displayCard', function(cardData, isTarget, senderName)
    if not cardData then return end

    currentCardData = cardData
    isCardOpen = true

    if not isTarget then
        PlayCardAnimation()
    end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'showCard',
        card = cardData,
        isTarget = isTarget or false,
        senderName = senderName or nil
    })
end)

RegisterNetEvent('bucu:license:client:openKiosk', function(payload)
    isCardOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openKiosk',
        location = payload.location,
        allowedLicenses = payload.allowedLicenses,
        cardsConfig = Config.Cards,
        existingLicenses = payload.existingLicenses,
        character = payload.character
    })
end)

RegisterNetEvent('bucu:license:client:closeKiosk', function()
    isCardOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeKiosk' })
end)

RegisterNetEvent('bucu:license:client:openOfficerConsole', function(payload)
    isCardOpen = true
    SetNuiFocus(true, true)
    local nearby = GetNearbyCitizens(6.0)

    SendNUIMessage({
        action = 'openOfficerConsole',
        department = payload.department,
        location = payload.location,
        allowedLicenses = payload.allowedLicenses,
        cardsConfig = Config.Cards,
        character = payload.character,
        nearbyCitizens = nearby
    })
end)

RegisterNetEvent('bucu:license:client:closeOfficerConsole', function()
    isCardOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeOfficerConsole' })
end)

-- ─── NUI Callbacks ──────────────────────────────────────────────────────────

RegisterNUICallback('close', function(_, cb)
    isCardOpen = false
    currentCardData = nil
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('showToNearby', function(_, cb)
    if not currentCardData then
        cb({ success = false, error = 'No card loaded' })
        return
    end

    local closestPlayer, dist = GetClosestPlayer(Config.ShowDistance)
    if closestPlayer == -1 then
        TriggerEvent('bucu:notify:show', {
            type = 'error',
            text = 'Tidak ada warga lain di dekat Anda (jarak maks: ' .. Config.ShowDistance .. 'm).'
        })
        cb({ success = false, error = 'No player nearby' })
        return
    end

    local targetServerId = GetPlayerServerId(closestPlayer)
    TriggerServerEvent('bucu:license:server:showToNearby', currentCardData, targetServerId)
    cb({ success = true })
end)

RegisterNUICallback('kioskPurchase', function(data, cb)
    if data and data.cardType then
        TriggerServerEvent('bucu:license:server:kioskPurchase', data.cardType, data.paymentMethod or 'cash')
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('officerIssue', function(data, cb)
    if data and data.targetServerId and data.cardType then
        TriggerServerEvent('bucu:license:server:officerIssue', tonumber(data.targetServerId), data.cardType, data.note)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('officerRevoke', function(data, cb)
    if data and data.targetServerId and data.cardType then
        TriggerServerEvent('bucu:license:server:officerRevoke', tonumber(data.targetServerId), data.cardType, data.reason)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)

RegisterNUICallback('refreshNearbyCitizens', function(_, cb)
    local nearby = GetNearbyCitizens(6.0)
    cb({ citizens = nearby })
end)

-- ─── Chat Commands ──────────────────────────────────────────────────────────

for cardType, cfg in pairs(Config.Cards) do
    if cfg.showCommand then
        RegisterCommand(cfg.showCommand, function()
            TriggerServerEvent('bucu:license:server:openCardForPlayer', GetPlayerServerId(PlayerId()), cardType, nil)
        end, false)
    end
end

RegisterCommand('licenses', function()
    TriggerServerEvent('bucu:license:server:openCardForPlayer', GetPlayerServerId(PlayerId()), 'id_card', nil)
end, false)

-- ─── Exports ────────────────────────────────────────────────────────────────

exports('ShowLicenseCard', function(cardType)
    TriggerServerEvent('bucu:license:server:openCardForPlayer', GetPlayerServerId(PlayerId()), cardType or 'id_card', nil)
end)

exports('ShowLicenseToNearby', function(cardType)
    local closestPlayer, _ = GetClosestPlayer(Config.ShowDistance)
    if closestPlayer == -1 then
        TriggerEvent('bucu:notify:show', { type = 'error', text = 'Tidak ada warga terdekat.' })
        return false
    end
    TriggerServerEvent('bucu:license:server:openCardForPlayer', GetPlayerServerId(PlayerId()), cardType or 'id_card', nil)
    return true
end)

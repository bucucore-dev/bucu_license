-- ============================================================================
-- BUCU License System — Server Engine
-- Database persistence, inventory usable items, whitelist jobs & kiosk
-- ============================================================================

local function GetPlayerCitizenId(src)
    if not src or src <= 0 then return nil end
    local state = Player(src).state
    if state and state.citizenid then
        return state.citizenid
    end
    return nil
end

local function GetPlayerCharacterDetails(src, cb)
    local state = Player(src).state
    local citizenId = state and state.citizenid

    if not citizenId then
        local license = GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license')
        if not license then
            local num = GetNumPlayerIdentifiers(src)
            for i = 0, num - 1 do
                local id = GetPlayerIdentifier(src, i)
                if id and string.sub(id, 1, 8) == 'license:' then
                    license = id
                    break
                end
            end
        end

        if not license then license = 'license:' .. tostring(src) end

        MySQL.query([[
            SELECT id, firstname, lastname, date_of_birth, gender, metadata
            FROM bucu_characters
            WHERE identifier LIKE ?
            LIMIT 1
        ]], { license .. ':%' }, function(rows)
            if rows and rows[1] then
                local row = rows[1]
                local meta = {}
                if row.metadata and row.metadata ~= '' then
                    pcall(function() meta = json.decode(row.metadata) end)
                end
                cb({
                    id = row.id,
                    citizenid = (meta and meta.citizenid) or ('BUCU-' .. tostring(row.id)),
                    firstname = row.firstname,
                    lastname = row.lastname,
                    fullname = row.firstname .. ' ' .. row.lastname,
                    dob = row.date_of_birth or '1990-01-01',
                    gender = row.gender or 'male',
                    nationality = (meta and meta.nationality) or 'San Andreas',
                    avatar = (meta and meta.avatar) or 'images/default_avatar.png'
                })
            else
                cb(nil)
            end
        end)
        return
    end

    MySQL.query([[
        SELECT id, firstname, lastname, date_of_birth, gender, metadata
        FROM bucu_characters
        WHERE metadata LIKE ?
        LIMIT 1
    ]], { '%"citizenid":"' .. citizenId .. '"%' }, function(rows)
        if rows and rows[1] then
            local row = rows[1]
            local meta = {}
            if row.metadata and row.metadata ~= '' then
                pcall(function() meta = json.decode(row.metadata) end)
            end
            cb({
                id = row.id,
                citizenid = citizenId,
                firstname = row.firstname,
                lastname = row.lastname,
                fullname = row.firstname .. ' ' .. row.lastname,
                dob = row.date_of_birth or '1990-01-01',
                gender = row.gender or 'male',
                nationality = (meta and meta.nationality) or 'San Andreas',
                avatar = (meta and meta.avatar) or 'images/default_avatar.png'
            })
        else
            cb({
                id = src,
                citizenid = citizenId,
                firstname = 'Citizen',
                lastname = tostring(src),
                fullname = 'Citizen ' .. tostring(src),
                dob = '1995-01-01',
                gender = 'male',
                nationality = 'San Andreas',
                avatar = 'images/default_avatar.png'
            })
        end
    end)
end

-- Check number of on-duty staff for department
function GetDepartmentOnDutyCount(department)
    local count = 0
    local targetJob = (department == 'police') and 'police' or 'government'
    local stateKey = (department == 'police') and 'police_duty' or 'gov_duty'
    local playerList = (type(GetPlayers) == 'function') and GetPlayers() or {}

    for _, playerId in ipairs(playerList) do
        local src = tonumber(playerId)
        local hasDutyState = false
        if type(Player) == 'function' then
            local state = Player(src).state
            if state and state[stateKey] == true then
                hasDutyState = true
                count = count + 1
            end
        end

        if not hasDutyState and exports and exports['bucu_core'] and exports['bucu_core'].GetJob then
            local j = exports['bucu_core']:GetJob(src)
            if j and j.name == targetJob and (j.on_duty == 1 or j.on_duty == true) then
                count = count + 1
            end
        end
    end
    return count
end
exports('GetDepartmentOnDutyCount', GetDepartmentOnDutyCount)

-- ─── Database Operations & Exports ───────────────────────────────────────────

function GetLicenses(citizenid, cb)
    if not citizenid then if cb then cb({}) end return end
    MySQL.query([[
        SELECT type, status, issued_date, expires_date, metadata
        FROM bucu_user_licenses
        WHERE citizenid = ? AND status = 1
    ]], { citizenid }, function(rows)
        local results = {}
        if rows then
            for _, r in ipairs(rows) do
                local meta = {}
                if r.metadata and r.metadata ~= '' then
                    pcall(function() meta = json.decode(r.metadata) end)
                end
                results[r.type] = {
                    type = r.type,
                    status = r.status,
                    issued_date = r.issued_date,
                    expires_date = r.expires_date,
                    metadata = meta
                }
            end
        end
        if cb then cb(results) end
    end)
end
exports('GetLicenses', GetLicenses)

function HasLicense(citizenid, licenseType, cb)
    if not citizenid or not licenseType then if cb then cb(false) end return end
    MySQL.scalar([[
        SELECT COUNT(1)
        FROM bucu_user_licenses
        WHERE citizenid = ? AND type = ? AND status = 1
    ]], { citizenid, licenseType }, function(count)
        local has = (count and count > 0)
        if cb then cb(has) end
    end)
end
exports('HasLicense', HasLicense)

function GrantLicense(citizenid, licenseType, metadata, cb)
    if not citizenid or not licenseType then if cb then cb(false) end return end
    local cfg = Config.Cards[licenseType]
    local metaStr = '{}'
    if json and json.encode then
        metaStr = (type(metadata) == 'table') and json.encode(metadata) or (metadata or '{}')
    else
        metaStr = (type(metadata) == 'table') and '{}' or (metadata or '{}')
    end
    
    local expiresSql = "NULL"
    if cfg and not cfg.lifetime and cfg.validityYears then
        expiresSql = string.format("DATE_ADD(CURDATE(), INTERVAL %d YEAR)", cfg.validityYears)
    end

    local query = string.format([[
        INSERT INTO bucu_user_licenses (citizenid, type, status, issued_date, expires_date, metadata)
        VALUES (?, ?, 1, CURDATE(), %s, ?)
        ON DUPLICATE KEY UPDATE status = 1, metadata = VALUES(metadata)
    ]], expiresSql)

    MySQL.execute(query, { citizenid, licenseType, metaStr }, function(affected)
        local ok = (affected and affected > 0)
        if cb then cb(ok) end
    end)
end
exports('GrantLicense', GrantLicense)

function RevokeLicense(citizenid, licenseType, cb)
    if not citizenid or not licenseType then if cb then cb(false) end return end
    MySQL.execute([[
        UPDATE bucu_user_licenses
        SET status = 0
        WHERE citizenid = ? AND type = ?
    ]], { citizenid, licenseType }, function(affected)
        local ok = (affected and affected > 0)
        if cb then cb(ok) end
    end)
end
exports('RevokeLicense', RevokeLicense)

-- ─── Usable Items Integration ────────────────────────────────────────────────

local function RegisterInventoryUsableItems()
    if not GetResourceState or GetResourceState('bucu_inventory') ~= 'started' then
        return
    end

    for cardType, cfg in pairs(Config.Cards) do
        if cfg.item then
            pcall(function()
                exports['bucu_inventory']:CreateUsableItem(cfg.item, function(src, item)
                    TriggerEvent('bucu:license:server:openCardForPlayer', src, cardType, item and item.metadata)
                end)
            end)
        end
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == 'bucu_inventory' then
        RegisterInventoryUsableItems()
    end
end)

-- ─── Presentation & NUI Bridge Events ────────────────────────────────────────

RegisterNetEvent('bucu:license:server:openCardForPlayer', function(src, cardType, itemMeta)
    local cfg = Config.Cards[cardType]
    if not cfg then return end

    GetPlayerCharacterDetails(src, function(char)
        if not char then return end

        local citizenId = char.citizenid

        HasLicense(citizenId, cardType, function(has)
            -- For basic id_card, grant automatically if missing
            if not has and cardType == 'id_card' then
                GrantLicense(citizenId, 'id_card', { name = char.fullname, citizenid = citizenId }, function()
                    has = true
                end)
            end

            local cardPayload = {
                cardType = cardType,
                title = cfg.label,
                shortLabel = cfg.shortLabel,
                authority = cfg.authority,
                department = cfg.department,
                theme = cfg.theme,
                gradient = cfg.gradient,
                badgeColor = cfg.badgeColor,
                accentColor = cfg.accentColor,
                watermark = cfg.watermark,
                lifetime = cfg.lifetime,
                validityYears = cfg.validityYears or 5,
                -- Citizen Details
                citizenid = citizenId,
                fullname = (itemMeta and itemMeta.name) or char.fullname,
                dob = (itemMeta and itemMeta.date_of_birth) or char.dob,
                gender = (itemMeta and itemMeta.gender) or char.gender,
                nationality = char.nationality,
                avatar = (itemMeta and itemMeta.avatar) or char.avatar or 'images/default_avatar.png',
                issuedDate = (itemMeta and itemMeta.issued_date) or os.date('!%Y-%m-%d'),
                status = has and 'VALID' or 'UNREGISTERED'
            }

            TriggerClientEvent('bucu:license:client:displayCard', src, cardPayload, false)
        end)
    end)
end)

RegisterNetEvent('bucu:license:server:showToNearby', function(cardData, targetServerId)
    local src = source
    if not cardData or not targetServerId then return end

    local targetPed = GetPlayerPed(targetServerId)
    local sourcePed = GetPlayerPed(src)

    if not targetPed or targetPed <= 0 or not sourcePed or sourcePed <= 0 then
        return
    end

    local srcCoords = GetEntityCoords(sourcePed)
    local trgCoords = GetEntityCoords(targetPed)
    local dist = #(srcCoords - trgCoords)

    if dist > (Config.ShowDistance + 1.5) then
        TriggerClientEvent('bucu:notify:show', src, {
            type = 'error',
            text = 'Warga tujuan berada terlalu jauh dari jangkauan fisik Anda.'
        })
        return
    end

    TriggerClientEvent('bucu:license:client:displayCard', targetServerId, cardData, true, GetPlayerName(src))

    TriggerClientEvent('bucu:notify:show', src, {
        type = 'info',
        text = string.format('Anda menunjukkan %s kepada %s.', cardData.shortLabel or 'Kartu', GetPlayerName(targetServerId))
    })

    TriggerClientEvent('bucu:notify:show', targetServerId, {
        type = 'info',
        text = string.format('%s menunjukkan %s kepada Anda.', GetPlayerName(src), cardData.shortLabel or 'Kartu')
    })
end)

-- ─── Kiosk & Whitelist Issuance Events ───────────────────────────────────────

RegisterNetEvent('bucu:license:server:interactLocation', function(locId)
    local src = source
    local loc = Config.Locations[locId]
    if not loc then return end

    GetPlayerCharacterDetails(src, function(char)
        if not char then return end

        local citizenId = char.citizenid
        local dept = loc.department
        local onDutyStaff = GetDepartmentOnDutyCount(dept)

        -- Check player's own job
        local playerJob = 'unemployed'
        local playerGrade = 0
        local isDuty = false

        if exports and exports['bucu_core'] and exports['bucu_core'].GetJob then
            local j = exports['bucu_core']:GetJob(src)
            if j then
                playerJob = j.name or 'unemployed'
                playerGrade = tonumber(j.grade) or 0
                isDuty = (j.on_duty == 1 or j.on_duty == true)
            end
        end

        local isStaff = (playerJob == dept and isDuty)

        -- If player is on-duty staff at their own department -> Open Officer Console!
        if isStaff then
            GetLicenses(citizenId, function(currentLicenses)
                TriggerClientEvent('bucu:license:client:openOfficerConsole', src, {
                    location = loc,
                    department = dept,
                    allowedLicenses = loc.allowedLicenses,
                    character = char,
                    currentLicenses = currentLicenses
                })
            end)
            return
        end

        -- Citizen visitor handling based on Config.IssuanceMode
        local mode = Config.IssuanceMode or 'hybrid'

        if mode == 'roleplay' and onDutyStaff == 0 then
            TriggerClientEvent('bucu:notify:show', src, {
                type = 'warning',
                text = 'Petugas pelayanan sedang tidak bertugas di kantor. Silakan kembali saat jam dinas aktif.'
            })
            return
        end

        if mode == 'hybrid' and onDutyStaff > 0 then
            TriggerClientEvent('bucu:notify:show', src, {
                type = 'info',
                text = string.format('Ada %d petugas resmi yang sedang bertugas di kantor. Silakan temui petugas di loket pelayanan.', onDutyStaff)
            })
            return
        end

        -- Open Citizen Self-Service Kiosk
        GetLicenses(citizenId, function(existingLicenses)
            TriggerClientEvent('bucu:license:client:openKiosk', src, {
                location = loc,
                allowedLicenses = loc.allowedLicenses,
                existingLicenses = existingLicenses,
                character = char
            })
        end)
    end)
end)

-- Citizen purchases license via self-service kiosk
RegisterNetEvent('bucu:license:server:kioskPurchase', function(cardType, paymentMethod)
    local src = source
    local cfg = Config.Cards[cardType]
    if not cfg then return end

    GetPlayerCharacterDetails(src, function(char)
        if not char then return end

        local citizenId = char.citizenid
        local price = cfg.price or 500

        -- Payment verification
        local function completeIssuance()
            local itemMeta = {
                name = char.fullname,
                citizenid = citizenId,
                date_of_birth = char.dob,
                gender = char.gender,
                nationality = char.nationality,
                avatar = char.avatar,
                issued_date = os.date('!%Y-%m-%d'),
                issuer = 'Terminal Kiosk Mandiri'
            }

            GrantLicense(citizenId, cardType, itemMeta, function(success)
                if success then
                    if exports and exports['bucu_inventory'] and exports['bucu_inventory'].AddItem then
                        exports['bucu_inventory']:AddItem(citizenId, cfg.item, 1, nil, itemMeta, 'pocket')
                    end

                    TriggerClientEvent('bucu:notify:show', src, {
                        type = 'success',
                        text = string.format('Berhasil mencetak %s. Dokumen fisik telah masuk ke kantong Anda.', cfg.shortLabel)
                    })

                    TriggerClientEvent('bucu:license:client:closeKiosk', src)
                else
                    TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = 'Gagal memproses pendaftaran dokumen.' })
                end
            end)
        end

        -- Deduct funds
        if paymentMethod == 'bank' and exports and exports['bucu_banking'] and exports['bucu_banking'].Withdraw then
            exports['bucu_banking']:Withdraw(src, price, function(ok)
                if ok then completeIssuance() else
                    TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = 'Saldo rekening bank tidak mencukupi.' })
                end
            end)
        elseif exports and exports['bucu_core'] and exports['bucu_core'].RemoveMoney then
            local payType = (paymentMethod == 'bank') and 'bank' or 'cash'
            local ok = exports['bucu_core']:RemoveMoney(src, payType, price, 'License Kiosk ' .. cfg.shortLabel)
            if ok then completeIssuance() else
                TriggerClientEvent('bucu:notify:show', src, { type = 'error', text = 'Uang tidak mencukupi untuk biaya administrasi.' })
            end
        else
            -- Fallback test/standalone
            completeIssuance()
        end
    end)
end)

-- Officer issues license to a citizen
RegisterNetEvent('bucu:license:server:officerIssue', function(targetServerId, cardType, officerNote)
    local officerSrc = source
    local cfg = Config.Cards[cardType]
    if not cfg or not targetServerId then return end

    -- Verify officer job & grade
    local officerJob = 'police'
    local officerGrade = 1
    if exports and exports['bucu_core'] and exports['bucu_core'].GetJob then
        local j = exports['bucu_core']:GetJob(officerSrc)
        if j then
            officerJob = j.name or 'police'
            officerGrade = tonumber(j.grade) or 0
        end
    end

    if cfg.issuerJob and officerJob ~= cfg.issuerJob then
        TriggerClientEvent('bucu:notify:show', officerSrc, { type = 'error', text = 'Departemen Anda tidak berwenang menerbitkan lisensi ini.' })
        return
    end

    if cfg.minGrade and officerGrade < cfg.minGrade then
        TriggerClientEvent('bucu:notify:show', officerSrc, { type = 'error', text = 'Pangkat Anda belum memenuhi syarat otorisasi dokumen ini.' })
        return
    end

    GetPlayerCharacterDetails(targetServerId, function(targetChar)
        if not targetChar then
            TriggerClientEvent('bucu:notify:show', officerSrc, { type = 'error', text = 'Data warga tujuan tidak ditemukan.' })
            return
        end

        GetPlayerCharacterDetails(officerSrc, function(officerChar)
            local itemMeta = {
                name = targetChar.fullname,
                citizenid = targetChar.citizenid,
                date_of_birth = targetChar.dob,
                gender = targetChar.gender,
                nationality = targetChar.nationality,
                avatar = targetChar.avatar,
                issued_date = os.date('!%Y-%m-%d'),
                issuer_name = officerChar and officerChar.fullname or 'Officer',
                officer_note = officerNote or 'Memenuhi Syarat Resmi'
            }

            GrantLicense(targetChar.citizenid, cardType, itemMeta, function(ok)
                if ok then
                    if exports and exports['bucu_inventory'] and exports['bucu_inventory'].AddItem then
                        exports['bucu_inventory']:AddItem(targetChar.citizenid, cfg.item, 1, nil, itemMeta, 'pocket')
                    end

                    TriggerClientEvent('bucu:notify:show', officerSrc, {
                        type = 'success',
                        text = string.format('Berhasil menerbitkan %s untuk %s (#%s).', cfg.shortLabel, targetChar.fullname, targetChar.citizenid)
                    })

                    TriggerClientEvent('bucu:notify:show', targetServerId, {
                        type = 'success',
                        text = string.format('Petugas %s telah menerbitkan %s untuk Anda.', officerChar and officerChar.fullname or 'Petugas', cfg.shortLabel)
                    })

                    TriggerClientEvent('bucu:license:client:closeOfficerConsole', officerSrc)
                else
                    TriggerClientEvent('bucu:notify:show', officerSrc, { type = 'error', text = 'Gagal memproses penerbitan ke database.' })
                end
            end)
        end)
    end)
end)

-- Officer revokes license from a citizen
RegisterNetEvent('bucu:license:server:officerRevoke', function(targetServerId, cardType, reason)
    local officerSrc = source
    local cfg = Config.Cards[cardType]
    if not cfg or not targetServerId then return end

    GetPlayerCharacterDetails(targetServerId, function(targetChar)
        if not targetChar then return end

        RevokeLicense(targetChar.citizenid, cardType, function(ok)
            if ok then
                if exports and exports['bucu_inventory'] and exports['bucu_inventory'].RemoveItem then
                    exports['bucu_inventory']:RemoveItem(targetChar.citizenid, cfg.item, 1)
                end

                TriggerClientEvent('bucu:notify:show', officerSrc, {
                    type = 'warning',
                    text = string.format('%s milik %s telah resmi dicabut. Alasan: %s', cfg.shortLabel, targetChar.fullname, reason or 'Pelanggaran Hukum')
                })

                TriggerClientEvent('bucu:notify:show', targetServerId, {
                    type = 'error',
                    text = string.format('Pemberitahuan Resmi: %s Anda telah dicabut oleh pihak berwenang.', cfg.shortLabel)
                })

                TriggerClientEvent('bucu:license:client:closeOfficerConsole', officerSrc)
            end
        end)
    end)
end)

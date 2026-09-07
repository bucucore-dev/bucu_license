// ============================================================================
// BUCU License System — 3D Interactive Client Controller
// ============================================================================

(function() {
    'use strict';

    const cardAppEl = document.getElementById('card-app');
    const physicalCardEl = document.getElementById('physical-card');
    const glareEl = document.getElementById('hologram-glare');
    const incomingBannerEl = document.getElementById('incoming-banner');
    const incomingSenderEl = document.getElementById('incoming-sender-name');

    // UI Elements
    const cardAuthorityEl = document.getElementById('card-authority');
    const cardDepartmentEl = document.getElementById('card-department');
    const cardBadgeEl = document.getElementById('card-badge');
    const cardAvatarImgEl = document.getElementById('card-avatar-img');
    const cardAvatarFallbackEl = document.getElementById('card-avatar-fallback');
    const cardCitizenIdEl = document.getElementById('card-citizenid');
    const cardFullNameEl = document.getElementById('card-fullname');
    const cardDobEl = document.getElementById('card-dob');
    const cardGenderEl = document.getElementById('card-gender');
    const cardNationalityEl = document.getElementById('card-nationality');
    const cardStatusEl = document.getElementById('card-status');
    const cardIssuedEl = document.getElementById('card-issued');
    const cardExpiresEl = document.getElementById('card-expires');
    const cardBarcodeTextEl = document.getElementById('card-barcode-text');
    const cardSignatureEl = document.getElementById('card-signature');

    // Buttons
    const btnClose = document.getElementById('btn-close-card');
    const btnShowNearby = document.getElementById('btn-show-nearby');

    let currentCard = null;
    let isVisible = false;

    // ─── Web Audio API: Realistic Physical Card Slide Sounds ─────────────────
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    let audioCtx = null;

    function initAudio() {
        if (!audioCtx) {
            try { audioCtx = new AudioCtx(); } catch(e) {}
        }
    }

    function playCardSlideSound() {
        initAudio();
        if (!audioCtx) return;
        try {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            const filter = audioCtx.createBiquadFilter();

            osc.type = 'sine';
            osc.frequency.setValueAtTime(320, audioCtx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(140, audioCtx.currentTime + 0.18);

            filter.type = 'lowpass';
            filter.frequency.setValueAtTime(1200, audioCtx.currentTime);
            filter.frequency.exponentialRampToValueAtTime(400, audioCtx.currentTime + 0.18);

            gain.gain.setValueAtTime(0.28, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.18);

            osc.connect(filter);
            filter.connect(gain);
            gain.connect(audioCtx.destination);

            osc.start();
            osc.stop(audioCtx.currentTime + 0.18);
        } catch (e) {}
    }

    function playCardCloseSound() {
        initAudio();
        if (!audioCtx) return;
        try {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(220, audioCtx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(80, audioCtx.currentTime + 0.12);

            gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
            gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.12);

            osc.connect(gain);
            gain.connect(audioCtx.destination);

            osc.start();
            osc.stop(audioCtx.currentTime + 0.12);
        } catch (e) {}
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────
    function getInitials(name) {
        if (!name) return 'BB';
        const parts = name.trim().split(/\s+/);
        if (parts.length === 1) return parts[0].substring(0, 2).toUpperCase();
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }

    function fetchPost(endpoint, data) {
        try {
            fetch(`https://${GetParentResourceName ? GetParentResourceName() : 'bucu_license'}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data || {})
            }).catch(() => {});
        } catch (e) {}
    }

    // ─── Render Card Content ─────────────────────────────────────────────────
    function renderCard(card, isTarget, senderName) {
        currentCard = card;

        // Reset theme classes
        physicalCardEl.className = 'physical-card';
        const themeClass = `theme-${card.theme || card.cardType || 'ktp'}`;
        physicalCardEl.classList.add(themeClass);

        // Header
        cardAuthorityEl.textContent = card.authority || 'PEMERINTAH KOTA BUCU';
        cardDepartmentEl.textContent = card.department || 'DIREKTORAT KEPENDUDUKAN & KEPOLISIAN';
        cardBadgeEl.textContent = card.shortLabel || 'ID';
        if (card.badgeColor) {
            cardBadgeEl.style.backgroundColor = card.badgeColor;
        }

        // Avatar
        const avatarSrc = card.avatar || 'images/default_avatar.png';
        if (avatarSrc && avatarSrc !== '') {
            cardAvatarImgEl.src = avatarSrc;
            cardAvatarImgEl.style.display = 'block';
            cardAvatarFallbackEl.style.display = 'none';
            cardAvatarImgEl.onerror = () => {
                cardAvatarImgEl.style.display = 'none';
                cardAvatarFallbackEl.style.display = 'flex';
                cardAvatarFallbackEl.textContent = getInitials(card.fullname);
            };
        } else {
            cardAvatarImgEl.style.display = 'none';
            cardAvatarFallbackEl.style.display = 'flex';
            cardAvatarFallbackEl.textContent = getInitials(card.fullname);
        }

        // Details
        cardCitizenIdEl.textContent = '#' + (card.citizenid || 'BUCU-000000');
        cardFullNameEl.textContent = (card.fullname || 'BUCU CITIZEN').toUpperCase();
        cardDobEl.textContent = card.dob || '1990-01-01';
        cardGenderEl.textContent = (card.gender || 'male').toUpperCase();
        cardNationalityEl.textContent = (card.nationality || 'SAN ANDREAS').toUpperCase();

        // Legal Status
        if (card.status === 'VALID' || card.status === 1) {
            cardStatusEl.className = 'status-pill active';
            cardStatusEl.textContent = 'RESMI / AKTIF';
        } else {
            cardStatusEl.className = 'status-pill revoked';
            cardStatusEl.textContent = 'TIDAK TERDAFTAR';
        }

        // Dates
        cardIssuedEl.textContent = card.issuedDate || '2026-09-01';
        if (card.lifetime) {
            cardExpiresEl.textContent = 'SEUMUR HIDUP';
            cardExpiresEl.classList.add('highlight');
        } else {
            cardExpiresEl.textContent = card.expiresDate || '2031-09-01';
            cardExpiresEl.classList.remove('highlight');
        }

        // Barcode & Signature
        const cleanType = (card.cardType || 'ID').toUpperCase();
        cardBarcodeTextEl.textContent = `BC-${cleanType}-${card.citizenid || '0000'}-SA`;
        cardSignatureEl.textContent = card.fullname || 'Bucu Banget';

        // Incoming share banner
        if (isTarget && senderName) {
            incomingSenderEl.textContent = senderName;
            incomingBannerEl.classList.remove('hidden');
            // Hide "Show to Nearby" button since this is an inspected card
            btnShowNearby.style.display = 'none';
        } else {
            incomingBannerEl.classList.add('hidden');
            btnShowNearby.style.display = 'flex';
        }

        // Show UI
        cardAppEl.classList.remove('hidden');
        isVisible = true;

        playCardSlideSound();
    }

    function closeCard() {
        if (!isVisible) return;
        isVisible = false;
        playCardCloseSound();
        cardAppEl.classList.add('hidden');
        incomingBannerEl.classList.add('hidden');
        // Reset card 3D tilt
        physicalCardEl.style.transform = 'perspective(1200px) rotateX(0deg) rotateY(0deg) scale(1)';
        fetchPost('close', {});
    }

    // ─── 3D Parallax Tilt Effect ─────────────────────────────────────────────
    let bounds = null;

    function handleMouseMove(e) {
        if (!isVisible) return;
        if (!bounds) bounds = physicalCardEl.getBoundingClientRect();

        const mouseX = e.clientX;
        const mouseY = e.clientY;

        const cardCenterX = bounds.left + bounds.width / 2;
        const cardCenterY = bounds.top + bounds.height / 2;

        const deltaX = (mouseX - cardCenterX) / (bounds.width / 2);
        const deltaY = (mouseY - cardCenterY) / (bounds.height / 2);

        // Clamp rotation between -16 and +16 degrees
        const rotY = Math.max(-16, Math.min(16, deltaX * 16));
        const rotX = Math.max(-16, Math.min(16, -deltaY * 16));

        physicalCardEl.style.transform = `perspective(1200px) rotateX(${rotX.toFixed(2)}deg) rotateY(${rotY.toFixed(2)}deg) scale(1.02)`;

        // Shift holographic glare
        if (glareEl) {
            const glareX = -deltaX * 60;
            const glareY = -deltaY * 60;
            glareEl.style.transform = `translate(${glareX.toFixed(1)}px, ${glareY.toFixed(1)}px)`;
            glareEl.style.opacity = (0.5 + Math.abs(deltaX * 0.3) + Math.abs(deltaY * 0.2)).toFixed(2);
        }
    }

    function handleMouseLeave() {
        if (!isVisible) return;
        bounds = null;
        physicalCardEl.style.transform = 'perspective(1200px) rotateX(0deg) rotateY(0deg) scale(1)';
        if (glareEl) {
            glareEl.style.transform = 'translate(0px, 0px)';
            glareEl.style.opacity = '0.5';
        }
    }

    window.addEventListener('mousemove', handleMouseMove);
    physicalCardEl.addEventListener('mouseleave', handleMouseLeave);

    // ─── Actions & Keybindings ───────────────────────────────────────────────
    btnClose.addEventListener('click', closeCard);

    btnShowNearby.addEventListener('click', () => {
        if (!currentCard) return;
        fetchPost('showToNearby', {});
    });

    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' || e.key === 'Backspace') {
            if (!officerAppEl.classList.contains('hidden')) {
                closeOfficerConsole();
            } else if (!kioskAppEl.classList.contains('hidden')) {
                closeKiosk();
            } else if (isVisible) {
                closeCard();
            }
        } else if (e.key === 'f' || e.key === 'F') {
            if (isVisible && btnShowNearby && btnShowNearby.style.display !== 'none') {
                fetchPost('showToNearby', {});
            }
        }
    });

    // ─── NUI Message Listener ────────────────────────────────────────────────
    window.addEventListener('message', (event) => {
        const item = event.data;
        if (!item || !item.action) return;

        const payload = item.data || item;

        if (item.action === 'showCard') {
            bounds = null;
            renderCard(payload.card || payload, payload.isTarget, payload.senderName);
        } else if (item.action === 'openKiosk') {
            openKiosk(payload);
        } else if (item.action === 'closeKiosk') {
            closeKiosk();
        } else if (item.action === 'openOfficerConsole') {
            openOfficerConsole(payload);
        } else if (item.action === 'closeOfficerConsole') {
            closeOfficerConsole();
        }
    });

    // ─── Kiosk Controller ────────────────────────────────────────────────────
    const kioskAppEl = document.getElementById('kiosk-app');
    const kioskGridEl = document.getElementById('kiosk-cards-grid');
    const kioskTitleEl = document.getElementById('kiosk-title');
    const kioskDeptTagEl = document.getElementById('kiosk-dept-tag');
    const kioskPriceValEl = document.getElementById('kiosk-selected-price');
    const btnKioskConfirm = document.getElementById('btn-kiosk-confirm');
    const btnKioskClose = document.getElementById('btn-kiosk-close');

    let selectedKioskCard = null;
    let kioskConfigData = null;

    const defaultCardsConfig = {
        'id_card': { label: 'Kartu Tanda Penduduk (KTP)', shortLabel: 'KTP', price: 50, lifetime: true, icon: 'images/id_card.png', badge: 'KTP' },
        'driver_car': { label: 'SIM Mobil (Golongan A)', shortLabel: 'SIM A', price: 250, validityYears: 5, icon: 'images/id_card.png', badge: 'A' },
        'driver_bike': { label: 'SIM Motor (Golongan C)', shortLabel: 'SIM C', price: 150, validityYears: 5, icon: 'images/id_card.png', badge: 'C' },
        'driver_truck': { label: 'SIM Truk & Alat Berat (Golongan B)', shortLabel: 'SIM B', price: 500, validityYears: 5, icon: 'images/id_card.png', badge: 'B' },
        'weapon': { label: 'Surat Izin Kepemilikan Senjata Api', shortLabel: 'SENJATA', price: 2500, validityYears: 3, icon: 'images/id_card.png', badge: '🔫' },
        'pilot': { label: 'Lisensi Penerbang Sipil', shortLabel: 'PILOT', price: 3500, validityYears: 2, icon: 'images/id_card.png', badge: '✈' },
        'boat': { label: 'Surat Izin Berlayar & Kapal', shortLabel: 'PELAUT', price: 1200, validityYears: 3, icon: 'images/id_card.png', badge: '⚓' }
    };

    function openKiosk(data) {
        data = data || {};
        kioskConfigData = data;
        selectedKioskCard = null;
        btnKioskConfirm.disabled = true;
        kioskPriceValEl.textContent = '$0';

        if (cardContainer) cardContainer.classList.add('hidden');
        if (officerAppEl) officerAppEl.classList.add('hidden');

        if (data.location) {
            kioskTitleEl.textContent = data.location.label || 'TERMINAL PERIZINAN MANDIRI';
            kioskDeptTagEl.textContent = (data.location.department === 'police') ? 'SAMSAT KEPOLISIAN' : 'BALAI KOTA DUKCAPIL';
        }

        kioskGridEl.innerHTML = '';
        const cardsCfg = Object.assign({}, defaultCardsConfig, data.cardsConfig || {});
        const allowed = (data.allowedLicenses && data.allowedLicenses.length > 0) ? data.allowedLicenses : ['id_card', 'driver_car', 'driver_bike', 'driver_truck'];
        const existing = data.existingLicenses || {};

        allowed.forEach(type => {
            const cfg = cardsCfg[type];
            if (!cfg) return;

            const hasAlready = existing[type] !== undefined;
            const cardEl = document.createElement('div');
            cardEl.className = `kiosk-card-item ${hasAlready ? 'owned' : ''}`;
            cardEl.dataset.type = type;

            cardEl.innerHTML = `
                <div class="kiosk-card-thumb">
                    <img src="${cfg.icon || 'images/id_card.png'}" alt="${cfg.shortLabel}" />
                </div>
                <div class="kiosk-card-info">
                    <div class="kiosk-card-title">${cfg.label}</div>
                    <div class="kiosk-card-meta">${cfg.lifetime ? 'Masa Berlaku: Seumur Hidup' : 'Masa Berlaku: ' + (cfg.validityYears || 5) + ' Tahun'}</div>
                </div>
                <div class="kiosk-card-price-badge">
                    ${hasAlready ? 'SUDAH DIMILIKI' : '$' + (cfg.price || 500)}
                </div>
            `;

            cardEl.addEventListener('click', () => {
                document.querySelectorAll('.kiosk-card-item').forEach(c => c.classList.remove('selected'));
                cardEl.classList.add('selected');
                selectedKioskCard = type;
                kioskPriceValEl.textContent = '$' + (cfg.price || 500);
                btnKioskConfirm.disabled = false;
                playCardSlideSound();
            });

            kioskGridEl.appendChild(cardEl);
        });

        kioskAppEl.classList.remove('hidden');
    }

    function closeKiosk() {
        kioskAppEl.classList.add('hidden');
        selectedKioskCard = null;
        fetchPost('close', {});
    }

    btnKioskClose.addEventListener('click', closeKiosk);

    btnKioskConfirm.addEventListener('click', () => {
        if (!selectedKioskCard) return;
        const payRadio = document.querySelector('input[name="kiosk-pay"]:checked');
        const payMethod = payRadio ? payRadio.value : 'cash';

        fetchPost('kioskPurchase', {
            cardType: selectedKioskCard,
            paymentMethod: payMethod
        });
    });

    // ─── Officer Bureau Console Controller ───────────────────────────────────
    const officerAppEl = document.getElementById('officer-app');
    const officerDeptIconEl = document.getElementById('officer-dept-icon');
    const officerDeptLabelEl = document.getElementById('officer-dept-label');
    const officerCitizensListEl = document.getElementById('officer-citizens-list');
    const officerSelectedBoxEl = document.getElementById('officer-selected-citizen-box');
    const officerLicenseSelectEl = document.getElementById('officer-license-select');
    const officerNotesInputEl = document.getElementById('officer-notes-input');
    const btnOfficerIssue = document.getElementById('btn-officer-issue');
    const btnOfficerRevoke = document.getElementById('btn-officer-revoke');
    const btnOfficerClose = document.getElementById('btn-officer-close');
    const btnRefreshCitizens = document.getElementById('btn-refresh-citizens');

    let selectedCitizen = null;

    function openOfficerConsole(data) {
        data = data || {};
        selectedCitizen = null;
        btnOfficerIssue.disabled = true;
        btnOfficerRevoke.disabled = true;
        officerSelectedBoxEl.innerHTML = '<span class="placeholder-text">Pilih warga dari daftar sebelah kiri...</span>';

        if (cardContainer) cardContainer.classList.add('hidden');
        if (kioskAppEl) kioskAppEl.classList.add('hidden');

        const isPolice = (data.department === 'police');
        officerDeptIconEl.textContent = isPolice ? '👮' : '🏛️';
        officerDeptLabelEl.textContent = isPolice ? 'BIRO PERIZINAN & LALU LINTAS POLISI' : 'DINAS KEPENDUDUKAN & PENCATATAN SIPIL';

        // Populate Licenses Select
        officerLicenseSelectEl.innerHTML = '';
        const cardsCfg = Object.assign({}, defaultCardsConfig, data.cardsConfig || {});
        const allowed = (data.allowedLicenses && data.allowedLicenses.length > 0) ? data.allowedLicenses : (isPolice ? ['driver_car', 'driver_bike', 'driver_truck', 'weapon'] : ['id_card', 'pilot', 'boat']);

        allowed.forEach(type => {
            const cfg = cardsCfg[type];
            if (cfg) {
                const opt = document.createElement('option');
                opt.value = type;
                opt.textContent = `${cfg.shortLabel} — ${cfg.label}`;
                officerLicenseSelectEl.appendChild(opt);
            }
        });

        renderNearbyCitizens(data.nearbyCitizens || []);
        officerAppEl.classList.remove('hidden');
    }

    function renderNearbyCitizens(citizens) {
        officerCitizensListEl.innerHTML = '';

        if (!citizens || citizens.length === 0) {
            officerCitizensListEl.innerHTML = '<div class="no-citizens-msg" style="color:#94a3b8; font-size:12px; padding:12px;">Tidak ada warga di sekitar loket (radius 6m).</div>';
            return;
        }

        citizens.forEach(c => {
            const itemEl = document.createElement('div');
            itemEl.className = 'citizen-item';
            itemEl.innerHTML = `
                <div class="citizen-item-info">
                    <div class="citizen-item-name">${c.name}</div>
                    <div class="citizen-item-sub">Server ID: #${c.serverId}</div>
                </div>
                <div class="citizen-item-dist" style="font-size:11px; color:#38bdf8;">${c.distance}m</div>
            `;

            itemEl.addEventListener('click', () => {
                document.querySelectorAll('.citizen-item').forEach(el => el.classList.remove('active'));
                itemEl.classList.add('active');
                selectedCitizen = c;

                officerSelectedBoxEl.innerHTML = `
                    <div style="font-weight:700; color:#38bdf8;">${c.name}</div>
                    <div style="font-size:11px; color:#94a3b8;">Server ID: #${c.serverId} • Jarak: ${c.distance}m</div>
                `;
                btnOfficerIssue.disabled = false;
                btnOfficerRevoke.disabled = false;
            });

            officerCitizensListEl.appendChild(itemEl);
        });
    }

    function closeOfficerConsole() {
        officerAppEl.classList.add('hidden');
        selectedCitizen = null;
        fetchPost('close', {});
    }

    btnOfficerClose.addEventListener('click', closeOfficerConsole);

    btnRefreshCitizens.addEventListener('click', () => {
        fetchPost('refreshNearbyCitizens', {});
    });

    btnOfficerIssue.addEventListener('click', () => {
        if (!selectedCitizen) return;
        fetchPost('officerIssue', {
            targetServerId: selectedCitizen.serverId,
            cardType: officerLicenseSelectEl.value,
            note: officerNotesInputEl.value || 'Telah Memenuhi Syarat & Terverifikasi'
        });
    });

    btnOfficerRevoke.addEventListener('click', () => {
        if (!selectedCitizen) return;
        fetchPost('officerRevoke', {
            targetServerId: selectedCitizen.serverId,
            cardType: officerLicenseSelectEl.value,
            reason: officerNotesInputEl.value || 'Pelanggaran Aturan / Tidak Memenuhi Standar'
        });
    });
    // ─── Standalone Browser Preview & Card Switching Demo ─────────────────────
    const sampleCards = {
        '1': {
            cardType: 'id_card',
            title: 'Kartu Tanda Penduduk (KTP)',
            shortLabel: 'KTP',
            authority: 'PEMERINTAH KOTA BUCU',
            department: 'DINAS KEPENDUDUKAN & PENCATATAN SIPIL',
            theme: 'ktp',
            badgeColor: '#0ea5e9',
            watermark: 'BUCU CITY REGISTRY',
            lifetime: true,
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        },
        '2': {
            cardType: 'driver_car',
            title: 'SIM Golongan A (Mobil)',
            shortLabel: 'SIM A',
            authority: 'KORLANTAS KEPOLISIAN BUCU',
            department: 'DIREKTORAT LALU LINTAS WILAYAH HUKUM',
            theme: 'sim_car',
            badgeColor: '#db2777',
            watermark: 'DRIVING LICENSE • CLASS A',
            lifetime: false,
            expiresDate: '2031-09-01',
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        },
        '3': {
            cardType: 'driver_bike',
            title: 'SIM Golongan C (Sepeda Motor)',
            shortLabel: 'SIM C',
            authority: 'KORLANTAS KEPOLISIAN BUCU',
            department: 'DIREKTORAT LALU LINTAS WILAYAH HUKUM',
            theme: 'sim_bike',
            badgeColor: '#f59e0b',
            watermark: 'MOTORCYCLE PERMIT • CLASS C',
            lifetime: false,
            expiresDate: '2031-09-01',
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        },
        '4': {
            cardType: 'driver_truck',
            title: 'SIM Golongan B (Truk & Niaga)',
            shortLabel: 'SIM B',
            authority: 'KORLANTAS KEPOLISIAN BUCU',
            department: 'DIREKTORAT ANGKUTAN BARANG & KOMERSIAL',
            theme: 'sim_truck',
            badgeColor: '#ea580c',
            watermark: 'COMMERCIAL TRUCK PERMIT • CLASS B',
            lifetime: false,
            expiresDate: '2031-09-01',
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        },
        '5': {
            cardType: 'weapon',
            title: 'Surat Izin Senjata Api',
            shortLabel: 'SENJATA',
            authority: 'POLICE DEPARTMENT INTERNAL AFFAIRS',
            department: 'BIRO PENGAWASAN SENJATA & AMUNISI',
            theme: 'weapon',
            badgeColor: '#ca8a04',
            watermark: 'CONCEALED FIREARM PERMIT',
            lifetime: false,
            expiresDate: '2029-09-01',
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        },
        '6': {
            cardType: 'pilot',
            title: 'Lisensi Penerbang Sipil',
            shortLabel: 'PILOT',
            authority: 'BUCU CIVIL AVIATION AUTHORITY',
            department: 'DIREKTORAT KELAYAKAN UDARA & OPERASI',
            theme: 'pilot',
            badgeColor: '#0284c7',
            watermark: 'CIVIL AVIATION PILOT LICENSE',
            lifetime: false,
            expiresDate: '2028-09-01',
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        },
        '7': {
            cardType: 'boat',
            title: 'Surat Izin Berlayar',
            shortLabel: 'PELAUT',
            authority: 'BUCU MARITIME & PORT AUTHORITY',
            department: 'DIREKTORAT KEPELABUHANAN & KELAUTAN',
            theme: 'boat',
            badgeColor: '#0d9488',
            watermark: 'MARITIME CAPTAIN PERMIT',
            lifetime: false,
            expiresDate: '2029-09-01',
            citizenid: 'BUCU-121436',
            fullname: 'Bucu Banget',
            dob: '1990-01-01',
            gender: 'LAKI-LAKI',
            nationality: 'SAN ANDREAS',
            avatar: 'images/default_avatar.png',
            issuedDate: '2026-09-01',
            status: 'VALID'
        }
    };

    window.addEventListener('keydown', (e) => {
        if (sampleCards[e.key]) {
            renderCard(sampleCards[e.key], false);
        } else if (e.key === '8' || e.key === 'k' || e.key === 'K') {
            openKiosk({
                location: { label: 'Samsat & Kantor Polisi Mission Row', department: 'police' },
                allowedLicenses: ['driver_car', 'driver_bike', 'driver_truck', 'weapon'],
                cardsConfig: defaultCardsConfig,
                existingLicenses: {}
            });
        } else if (e.key === '9' || e.key === 'o' || e.key === 'O') {
            openOfficerConsole({
                department: 'police',
                allowedLicenses: ['driver_car', 'driver_bike', 'driver_truck', 'weapon'],
                cardsConfig: defaultCardsConfig,
                nearbyCitizens: [
                    { serverId: 1, name: 'Budi Santoso', citizenid: 'BUCU-782190', distance: 1.2 },
                    { serverId: 2, name: 'Siti Rahma', citizenid: 'BUCU-341902', distance: 2.4 }
                ]
            });
        }
    });

    // Auto-display default KTP if running in standalone browser without FiveM
    if (!window.invokeNative && window.location.protocol === 'file:') {
        setTimeout(() => {
            renderCard(sampleCards['1'], false);
        }, 120);
    }

})();

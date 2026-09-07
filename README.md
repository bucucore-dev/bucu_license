# BUCU License & Physical Cards (`bucu_license`)

Sistem identifikasi fisik interaktif dan manajemen lisensi kependudukan, izin mengemudi, kepemilikan senjata api, lisensi penerbangan, dan pelaut untuk FiveM / BucuCore.

---

## Fitur Utama

- **Desain Kartu Fisik Realistis**:
  - **KTP (Citizen Identity Card)**: Kartu biru kenegaraan resmi dengan watermark BUCU City Registry, chip EMV emas, foto studio biometrik warga, dan barcode PDF417.
  - **SIM Mobil (Class A Driver License)**: Nuansa pink/magenta dan platinum vibrant ala Sans RP dengan piktogram mobil dan tanggal masa berlaku 5 tahun.
  - **SIM Motor (Class C Motorcycle License)**: Nuansa oranye dan kuning emas dengan piktogram sepeda motor.
  - **SIM Truk (Class B Commercial License)**: Nuansa karbon amber untuk angkutan niaga berat.
  - **Surat Izin Senjata Api (Concealed Firearm Permit)**: Nuansa slate gray taktis dengan stempel segel kepolisian resmi.
  - **Lisensi Penerbang (Civil Aviation Pilot License)**: Nuansa navy dan emas aeronautika.
  - **Surat Izin Berlayar (Nautical Boat Permit)**: Nuansa pirus dan biru laut pelabuhan.
- **Interaksi 3D Parallax & Kilauan Holografik**:
  - Mengikuti pergerakan kursor mouse dengan perspective tilt 3D dinamis.
  - Efek kilauan holografik iridescent (*holographic glare reflection*) yang bergeser dinamis.
- **Animasi Fisik & Tunjukkan ke Warga Sekitar**:
  - Animasi ped resmi (`mp_common:givetake2_a`) saat mengeluarkan kartu.
  - Tombol aksi `[TUNJUKKAN KE WARGA SEKITAR]` untuk menampilkan kartu fisik ke pemain lain dalam radius 2.5 meter.
  - Efek audio gesekan kartu fisik nyata (Web Audio API).
- **Integrasi Inventaris & Chat Commands**:
  - Item usable inventaris: `id_card`, `driver_license`, `driver_bike`, `driver_truck`, `weapon_license`, `pilot_license`, `boat_license`.
  - Chat commands: `/showid`, `/showdriver`, `/showbike`, `/showtruck`, `/showweapon`, `/showpilot`, `/showboat`.
  - Export API lengkap untuk resource pekerjaan (Polisi, Samsat, Lisensi).

---

## Instalasi

1. Pastikan folder resource berada di `resources/[bucu]/bucu_license`.
2. Impor tabel database `database/schema.sql` ke database server Anda (`bucu_city`).
3. Tambahkan ke `server.cfg`:
   ```cfg
   ensure bucu_license
   ```

---

## Exports

### Client
```lua
-- Membuka kartu lisensi
exports['bucu_license']:ShowLicenseCard('id_card')

-- Menunjukkan kartu lisensi ke warga terdekat
exports['bucu_license']:ShowLicenseToNearby('driver_car')
```

### Server
```lua
-- Cek apakah warga memiliki lisensi aktif
exports['bucu_license']:HasLicense(citizenid, 'driver_car', function(hasLicense)
    print("Memiliki SIM Mobil:", hasLicense)
end)

-- Memberikan lisensi baru
exports['bucu_license']:GrantLicense(citizenid, 'weapon', { issued_by = 'Police Chief' }, function(success)
    print("Lisensi diberikan:", success)
end)
```

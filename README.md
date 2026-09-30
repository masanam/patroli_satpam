# Police Patrol App

Police Patrol App adalah aplikasi mobile yang dirancang untuk membantu petugas kepolisian dalam melakukan patroli, melaporkan insiden, dan mengoordinasikan kegiatan patroli secara efektif. Aplikasi ini memanfaatkan teknologi berbasis lokasi untuk melacak rute patroli, melaporkan insiden dengan bukti foto, dan memberikan laporan detail patroli.

## Fitur

- **Login dan Registrasi:** Pengguna dapat masuk dan membuat akun baru dengan pilihan peran (Officer, CommandCenter).
- **Dasbor Insiden:** Memungkinkan pengguna untuk melihat semua insiden yang telah dilaporkan, lengkap dengan detail waktu dan deskripsi insiden.
- **Peta Patroli:** Menampilkan peta interaktif yang menunjukkan lokasi pengguna saat ini, rute patroli yang telah diambil, dan lokasi insiden.
- **Pelaporan Insiden:** Fitur untuk melaporkan insiden dengan mengisi jenis insiden, deskripsi, dan mengambil foto bukti.
- **Laporan Patroli:** Menyediakan detail rute patroli yang diambil, termasuk waktu mulai dan akhir, jumlah personel, dan informasi terkait lainnya.
- **Obrolan Tim:** Fitur obrolan untuk berkomunikasi antar anggota tim patroli.
- **Scan Checkpoint:** Verifikasi kehadiran petugas di titik patroli menggunakan barcode QR.
- **Contact Center:** Direktori kontak penting (layanan darurat, koordinasi patroli, pengaduan) yang dapat dihubungi langsung via WhatsApp.

## Teknologi yang Digunakan

- **Flutter & Dart:** Digunakan untuk mengembangkan antarmuka pengguna dan logika aplikasi.
- **Firebase:** Digunakan untuk autentikasi, penyimpanan database (Firestore), penyimpanan cloud untuk media, dan layanan notifikasi push.
- **Google Maps API:** Untuk menampilkan peta interaktif dan melacak rute patroli.
- **GetX:** Library Flutter untuk manajemen status, routing, dan dependensi.
- **Unit Testing:** Menggunakan `flutter_test` untuk menguji model dan fungsi aplikasi.

## Instalasi

1. **Kloning Repositori:**

   ```bash
   git clone 
   cd Police-Patrol-App-main
   ```

2. **Install Dependencies:**

   ```bash
   flutter pub get
   ```

3. **Menjalankan Aplikasi:**

   ```bash
   flutter run
   ```

## Struktur Koleksi Firestore

| Koleksi           | Deskripsi                                                   |
|-------------------|-------------------------------------------------------------|
| `users`           | Data pengguna terdaftar (petugas & command center)          |
| `PreApprovedUsers`| Daftar email yang disetujui untuk mendaftar                 |
| `incidents`       | Laporan insiden dari lapangan                               |
| `patrolRoutes`    | Rute GPS patroli yang direkam                               |
| `patrolReports`   | Laporan resmi patroli (surat perintah, jenis patroli, dsb.) |
| `officers`        | Data petugas (nama, pangkat, unit)                          |
| `resources`       | Sumber daya (kendaraan, peralatan, dll.)                    |
| `checkpoints`     | Titik barcode QR yang harus dipindai saat patroli           |
| `contactCenters`  | Daftar kontak (WhatsApp & telepon) untuk koordinasi         |

## Checkpoint Barcode

Checkpoint disimpan di collection `checkpoints`. Document ID harus sama dengan nilai yang dicetak pada barcode, misalnya `CP-GATE-001`.

Contoh document:

```json
{
   "name": "Gerbang Utama",
   "siteId": "site-001",
   "latitude": -6.2001,
   "longitude": 106.8167,
   "radiusMeters": 50,
   "sequence": 1,
   "isActive": true
}
```

Alur penggunaan:

1. Login sebagai petugas.
2. Buka `View Incidents` atau peta patroli.
3. Tekan `Start Recording` dan submit patrol report.
4. Tekan `Scan Checkpoint`.
5. Scan barcode yang ID-nya terdaftar di `checkpoints`.
6. Hasil scan tersimpan di `patrolRoutes/{sessionId}/scans`.

## Contact Center

Contact Center disimpan di collection `contactCenters`. Setiap dokumen berisi nama, nomor WhatsApp, nomor telepon, jabatan, dan kategori kontak.

Kategori kontak (`category` — integer):

| Nilai | Kategori         | Keterangan                          |
|-------|------------------|-------------------------------------|
| 0     | emergency        | Darurat (110, 119, 113)             |
| 1     | patrol           | Koordinasi patroli & komandan regu  |
| 2     | report           | Pengaduan masyarakat                |
| 3     | administrative   | Administrasi & dokumentasi          |

Contoh document (`CC-001`):

```json
{
  "id": "CC-001",
  "name": "Komandan Regu Patroli",
  "whatsappNumber": "6281234567890",
  "phoneNumber": "021-5551001",
  "position": "Komandan Regu",
  "unit": "Unit Patroli Alpha",
  "category": 1,
  "isActive": true,
  "description": "Komandan utama regu patroli."
}
```

> **Catatan:** Field `whatsappNumber` menggunakan format internasional **tanpa** tanda `+` (contoh: `6281234567890` bukan `+6281234567890`).

## Data Dummy Firebase

File `firebase_dummy_data.json` di root proyek berisi data dummy siap pakai untuk semua koleksi Firestore. Lihat panduan upload di bawah.

### Cara Upload Data Dummy ke Firebase

#### Opsi 1 — Firebase Console (Manual, Direkomendasikan untuk Pemula)

1. Buka [Firebase Console](https://console.firebase.google.com) → pilih project Anda.
2. Klik menu **Firestore Database** di sidebar kiri.
3. Klik **+ Start Collection** atau pilih koleksi yang sudah ada.
4. Klik **+ Add Document**, isi **Document ID** (sesuai key di JSON, contoh `CC-001`), lalu tambahkan setiap field secara manual.

#### Opsi 2 — Firebase CLI dengan `firestore:import` (Bulk Import)

> Cocok untuk data besar. Memerlukan format khusus Firebase Firestore Export.

```bash
# Install Firebase CLI jika belum ada
npm install -g firebase-tools

# Login
firebase login

# Konversi JSON ke format Firestore Export (gunakan tool pihak ketiga seperti `node-firestore-import-export`)
npm install -g node-firestore-import-export

# Upload ke Firestore
firestore-import -a path/to/serviceAccountKey.json -b firebase_dummy_data.json
```

#### Opsi 3 — Script Node.js (Pendekatan Programatik)

Buat file `seed_firestore.js` di root proyek:

```javascript
const admin = require('firebase-admin');
const data = require('./firebase_dummy_data.json');

// Ganti dengan path ke service account key Anda
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seedCollection(collectionName, documents) {
  const batch = db.batch();
  Object.entries(documents).forEach(([docId, docData]) => {
    const ref = db.collection(collectionName).doc(docId);
    batch.set(ref, docData);
  });
  await batch.commit();
  console.log(`✅ Seeded collection: ${collectionName} (${Object.keys(documents).length} docs)`);
}

async function main() {
  const collections = [
    'contactCenters',
    'checkpoints',
    'officers',
    'resources',
    'incidents',
    'patrolRoutes',
    'patrolReports',
    'PreApprovedUsers',
  ];

  for (const col of collections) {
    if (data[col]) {
      await seedCollection(col, data[col]);
    }
  }
  console.log('🎉 Seeding selesai!');
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Terjadi error:', err);
  process.exit(1);
});
```

```bash
# Jalankan script
node seed_firestore.js
```

#### Mendapatkan Service Account Key

1. Buka [Firebase Console](https://console.firebase.google.com) → Pengaturan Proyek (⚙️).
2. Klik tab **Service accounts**.
3. Klik **Generate new private key** → Simpan sebagai `serviceAccountKey.json` di root proyek.
4. **Jangan commit** file `serviceAccountKey.json` ke repositori! Tambahkan ke `.gitignore`.

#### Akun Demo (PreApprovedUsers)

Setelah data dummy terupload, daftarkan akun berikut melalui halaman **Registrasi** di aplikasi:

| Email                      | Password (bebas) | Peran          |
|----------------------------|------------------|----------------|
| `petugas1@polisi.go.id`    | minimal 6 karakter | Officer       |
| `petugas2@polisi.go.id`    | minimal 6 karakter | Officer       |
| `komandan@polisi.go.id`    | minimal 6 karakter | CommandCenter |

> Akun `admin@polisi.go.id` sengaja dibuat `isApproved: false` untuk demonstrasi alur penolakan.

## Deploy Rules Firestore

```bash
firebase deploy --only firestore:rules
```


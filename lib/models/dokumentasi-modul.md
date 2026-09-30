# Dokumentasi Modul Police Patrol Management System

## 1. Modul User

### Deskripsi
Modul User merepresentasikan pengguna dalam sistem, termasuk petugas dan pusat komando.

### Kelas: User
- **Atribut:**
  - `id` (String): Identifikasi unik pengguna
  - `email` (String): Alamat email pengguna
  - `name` (String?): Nama pengguna (opsional)
  - `patrolUnit` (String?): Unit atau divisi patroli (opsional)
  - `profileImageUrl` (String?): URL gambar profil (opsional)
  - `lastOnlineTimestamp` (DateTime?): Waktu terakhir online
  - `role` (UserRole): Peran pengguna (Officer, CommandCenter)
  - `latitude` (double?): Latitude lokasi pengguna (opsional)
  - `longitude` (double?): Longitude lokasi pengguna (opsional)

- **Metode:**
  - `toJson()`: Mengkonversi objek User menjadi Map JSON
  - `fromJson(json)`: Membuat objek User dari Map JSON

### Enum: UserRole
- Nilai: Officer, CommandCenter

---

## 2. Modul Incident

### Deskripsi
Modul Incident menangani pelaporan dan pengelolaan insiden selama patroli.

### Kelas: Incident
- **Atribut:**
  - `id` (String): Identifikasi unik insiden
  - `latitude` (double): Latitude lokasi insiden
  - `longitude` (double): Longitude lokasi insiden
  - `description` (String): Deskripsi insiden
  - `timestamp` (DateTime): Waktu insiden terjadi
  - `reportedBy` (String?): ID pengguna yang melaporkan (opsional)
  - `type` (String?): Jenis insiden (opsional)
  - `mediaUrl` (String?): URL media terkait insiden (opsional)
  - `mediaType` (String?): Jenis media (opsional)
  - `patrolRouteId` (String?): ID rute patroli terkait (opsional)
  - `status` (IncidentStatus?): Status insiden

- **Metode:**
  - `toJson()`: Mengkonversi objek Incident menjadi Map JSON
  - `fromJson(json)`: Membuat objek Incident dari Map JSON

### Enum: IncidentStatus
- Nilai: Pending, Resolved, InProgress

---

## 3. Modul Officer

### Deskripsi
Modul Officer merepresentasikan petugas kepolisian yang melakukan patroli.

### Kelas: Officer
- **Atribut:**
  - `id` (String): Identifikasi unik petugas
  - `name` (String): Nama petugas
  - `rank` (String): Pangkat petugas
  - `patrolUnit` (String): Unit atau divisi patroli
  - `status` (String): Status petugas (On Duty, Off Duty, dll)

- **Metode:**
  - `toJson()`: Mengkonversi objek Officer menjadi Map JSON
  - `fromJson(json)`: Membuat objek Officer dari Map JSON

---

## 4. Modul PatrolReport

### Deskripsi
Modul PatrolReport menangani pembuatan dan pengelolaan laporan patroli.

### Kelas: PatrolReport
- **Atribut:**
  - `id` (String): Identifikasi unik laporan patroli
  - `officerId` (String): ID petugas yang membuat laporan
  - `warrantDateTime` (DateTime): Waktu surat perintah patroli
  - `typeOfPatrol` (String): Jenis patroli
  - `natureOfPatrol` (String): Sifat patroli
  - `isFootPatrol` (bool): Apakah patroli jalan kaki
  - `numberOfPersonnel` (int): Jumlah personel yang terlibat
  - `patrolRouteId` (String): ID rute patroli terkait

- **Metode:**
  - `toMap()`: Mengkonversi objek PatrolReport menjadi Map
  - `fromMap(map)`: Membuat objek PatrolReport dari Map

---

## 5. Modul PatrolRoute

### Deskripsi
Modul PatrolRoute menangani informasi tentang rute patroli yang dilakukan.

### Kelas: PatrolRoute
- **Atribut:**
  - `id` (String): Identifikasi unik rute patroli
  - `officerId` (String): ID petugas yang merekam rute
  - `startTime` (DateTime): Waktu mulai patroli
  - `endTime` (DateTime?): Waktu selesai patroli (opsional)
  - `locations` (List\<LocationPoint\>): Daftar titik lokasi yang direkam
  - `incidents` (List\<Incident\>?): Daftar insiden yang dilaporkan selama patroli (opsional)

- **Metode:**
  - `toJson()`: Mengkonversi objek PatrolRoute menjadi Map JSON
  - `fromJson(json)`: Membuat objek PatrolRoute dari Map JSON

### Kelas: LocationPoint
- **Atribut:**
  - `latitude` (double): Latitude titik lokasi
  - `longitude` (double): Longitude titik lokasi
  - `timestamp` (DateTime): Waktu perekaman titik lokasi

- **Metode:**
  - `toJson()`: Mengkonversi objek LocationPoint menjadi Map JSON
  - `fromJson(json)`: Membuat objek LocationPoint dari Map JSON

---

## 6. Modul Resource

### Deskripsi
Modul Resource menangani informasi tentang sumber daya yang digunakan dalam operasi kepolisian.

### Kelas: Resource
- **Atribut:**
  - `id` (String): Identifikasi unik sumber daya
  - `name` (String): Nama sumber daya
  - `type` (String): Jenis sumber daya (Kendaraan, Peralatan Komunikasi, dll)
  - `status` (String): Status sumber daya (Tersedia, Sedang Digunakan, Dalam Perbaikan)

- **Metode:**
  - `toJson()`: Mengkonversi objek Resource menjadi Map JSON
  - `fromJson(json)`: Membuat objek Resource dari Map JSON

---

## 7. Modul Checkpoint

### Deskripsi
Modul Checkpoint merepresentasikan titik pemeriksaan (pos barcode QR) yang harus dipindai petugas selama patroli untuk memverifikasi kehadiran fisik di titik tersebut.

### Kelas: Checkpoint
- **Atribut:**
  - `id` (String): ID unik checkpoint, sekaligus nilai barcode yang dicetak
  - `name` (String): Nama lokasi checkpoint
  - `siteId` (String): ID area/situs tempat checkpoint berada
  - `latitude` (double): Latitude checkpoint
  - `longitude` (double): Longitude checkpoint
  - `radiusMeters` (double): Radius toleransi dalam meter (default 50m)
  - `sequence` (int): Urutan checkpoint dalam rute patroli
  - `isActive` (bool): Status aktif checkpoint

- **Metode:**
  - `fromJson(json, id)`: Membuat objek Checkpoint dari Map JSON dan document ID Firestore

---

## 8. Modul PatrolScan

### Deskripsi
Modul PatrolScan mencatat hasil pemindaian barcode QR di setiap checkpoint. Tersimpan sebagai sub-koleksi `scans` di dalam `patrolRoutes/{sessionId}/scans`.

### Kelas: PatrolScan
- **Atribut:**
  - `id` (String): Identifikasi unik scan
  - `sessionId` (String): ID sesi patroli atau checkpoint
  - `checkpointId` (String): ID checkpoint yang dipindai
  - `officerId` (String): ID petugas yang memindai
  - `latitude` (double): Latitude lokasi saat scan
  - `longitude` (double): Longitude lokasi saat scan
  - `accuracy` (double?): Akurasi GPS saat scan (dalam meter)
  - `isWithinRadius` (bool): Apakah posisi petugas dalam radius checkpoint
  - `scannedAt` (DateTime): Waktu pemindaian

- **Metode:**
  - `toJson()`: Mengkonversi objek PatrolScan menjadi Map JSON

---

## 9. Modul ContactCenter *(Ditambahkan)*

### Deskripsi
Modul ContactCenter menyimpan data kontak penting yang dapat dihubungi melalui WhatsApp maupun telepon. Mencakup layanan darurat, koordinasi patroli, pengaduan masyarakat, dan administrasi. Data disimpan di koleksi Firestore `contactCenters`.

### Kelas: ContactCenter
**File:** `lib/models/contact_center.dart`

- **Atribut:**
  - `id` (String): Identifikasi unik kontak
  - `name` (String): Nama kontak atau layanan
  - `whatsappNumber` (String): Nomor WhatsApp format internasional tanpa `+` (contoh: `6281234567890`)
  - `phoneNumber` (String?): Nomor telepon biasa (opsional)
  - `position` (String?): Jabatan atau posisi (opsional)
  - `unit` (String?): Unit atau divisi (opsional)
  - `category` (ContactCategory): Kategori kontak
  - `isActive` (bool): Status aktif kontak — digunakan sebagai soft-delete (default `true`)
  - `description` (String?): Deskripsi singkat fungsi kontak (opsional)
  - `avatarUrl` (String?): URL foto profil atau logo (opsional)

- **Properti Kalkulasi:**
  - `whatsappUrl` → `String`: Menghasilkan URL deep-link `https://wa.me/{whatsappNumber}`

- **Metode:**
  - `whatsappUrlWithMessage(message)`: Menghasilkan URL WhatsApp dengan pesan awal (pre-filled message)
  - `toJson()`: Mengkonversi objek ContactCenter menjadi Map JSON untuk disimpan ke Firestore
  - `fromJson(json)`: Membuat objek ContactCenter dari Map JSON yang diterima dari Firestore
  - `copyWith(...)`: Membuat salinan objek dengan field tertentu yang diubah

### Enum: ContactCategory

| Index | Nilai            | Keterangan                                          |
|-------|------------------|-----------------------------------------------------|
| 0     | `emergency`      | Darurat (Polisi 110, Ambulans 119, Pemadam Api 113) |
| 1     | `patrol`         | Koordinasi Patroli (Komandan, Anggota Regu)         |
| 2     | `report`         | Pelaporan Insiden & Pengaduan Masyarakat            |
| 3     | `administrative` | Administrasi & Dokumentasi                         |

### Koleksi Firestore: `contactCenters`

**Document ID:** ID kontak (contoh: `CC-001`)

| Field            | Tipe    | Keterangan                                              |
|------------------|---------|---------------------------------------------------------|
| `id`             | String  | Sama dengan document ID                                 |
| `name`           | String  | Nama kontak                                             |
| `whatsappNumber` | String  | Format internasional tanpa `+` (contoh: `628xxxxxxxxx`) |
| `phoneNumber`    | String? | Nomor telepon biasa (opsional)                          |
| `position`       | String? | Jabatan                                                 |
| `unit`           | String? | Unit/divisi                                             |
| `category`       | Integer | Index enum `ContactCategory` (0-3)                     |
| `isActive`       | Boolean | `true` = aktif, `false` = dihapus (soft-delete)         |
| `description`    | String? | Deskripsi singkat                                       |
| `avatarUrl`      | String? | URL foto profil                                         |

### Method CRUD di FirebaseService

| Method | Return Type | Deskripsi |
|--------|-------------|-----------|
| `getContactCenters()` | `Future<List<ContactCenter>>` | Ambil semua kontak aktif (sekali baca) |
| `streamContactCenters()` | `Stream<List<ContactCenter>>` | Stream realtime daftar kontak aktif |
| `getContactCentersByCategory(category)` | `Future<List<ContactCenter>>` | Filter kontak berdasarkan kategori |
| `addContactCenter(contact)` | `Future<String>` | Tambah kontak baru, mengembalikan ID |
| `updateContactCenter(contact)` | `Future<void>` | Perbarui data kontak yang sudah ada |
| `deleteContactCenter(id)` | `Future<void>` | Soft-delete (set `isActive: false`) |

# PharmaGuard — Mobile FEFO Medicine Inventory System

Sistem Informasi Manajemen Inventaris Obat Berbasis Mobile dengan Algoritma **First Expired First Out (FEFO)**, Pemindai Barcode 2D **GS1 DataMatrix**, Peringatan Dini Kedaluwarsa (EWS H-5), Kepatuhan **UU PDP No. 27/2022**, dan Interoperabilitas Nasional **SATUSEHAT Kemenkes RI (HL7 FHIR)**.

---

## 🚀 Fitur Utama & Alur Pengguna

1. **Alur 0 — Autentikasi Bersih Petugas Apotek**
   - Layar Masuk / Daftar Akun dengan Segmented Pill.
   - Opsi Single Sign-On (SSO) Google Workspace Apotek.
   - Pengaturan hak akses berbasis *Attribute-Based Access Control* (ABAC).

2. **Alur 1 — Dasbor Beranda & Peringatan Obat Kritis (H-5)**
   - Salam ramah petugas: "Halo, Apoteker Pija" (*Apotek Sehat Medika*).
   - **Hero Warning Card**: Kartu coral-red menyala menampilkan jumlah obat yang mendekati batas waktu pakai ($\le$ 5 hari).
   - **Daftar Perlu Tindakan**: Kartu obat prioritas FEFO dengan indikator lokasi rak fisik.

3. **Alur 2 — Pemindai Barcode Cerdas & Input Cepat Obat Baru**
   - Dual Engine Scanner: Mendukung Barcode Linier 1D (EAN-13) dan Kode Matriks 2D (GS1 DataMatrix).
   - **GS1 AI Parser**: Ekstraksi instan dari satu kali scan tanpa ketik manual:
     - `AI (01)` $\rightarrow$ Global Trade Item Number (GTIN)
     - `AI (10)` $\rightarrow$ Nomor Batch Produksi
     - `AI (17)` $\rightarrow$ Tanggal Kedaluwarsa (YYMMDD)
   - Stepper counter jumlah unit dan date picker masa kedaluwarsa.

4. **Alur 3 — Katalog Obat & Aksi Karantina 1-Ketuk**
   - Pencarian real-time nama obat atau kode barcode.
   - Filter chips: `Semua`, `Kritis H-5`, `Sirup`, `Tablet`, `Salep`, `Kapsul`.
   - **Layar Rincian Obat**: Tombol besar *"Tarik Obat dari Rak (Karantina)"* yang langsung memindahkan status batch ke karantina fisik demi keselamatan pasien.

5. **Pengaturan & Kepatuhan Hukum**
   - Toggle sakelar Peringatan Otomatis H-5 dan Bunyi Beep Scanner.
   - Status sinkronisasi cloud Supabase.
   - Penegakan privasi data medis pasien sesuai amanat UU PDP No. 27/2022 (*Data Masking*).

---

## 🛠️ Arsitektur Teknologi

- **Frontend Mobile**: Flutter 3.32.4 / Dart 3.8.1 (Clean Architecture MVVM)
- **State Management**: `provider` + `ChangeNotifier`
- **Database Cloud & Backend**: Supabase (PostgreSQL 15+)
- **Format Barcode**: GS1 DataMatrix (2D) & EAN-13 (1D)
- **Interoperabilitas**: Standar HL7 FHIR Release 4 (`Medication` & `InventoryItem`)

---

## 📂 Struktur Proyek

```text
pharmaguard/
├── lib/
│   ├── domain/
│   │   └── models/
│   │       ├── enums.dart              # Status urgensi, kategori sediaan, status batch
│   │       ├── medication.dart         # Master obat & antrean prioritas FEFO terdekat
│   │       └── medication_batch.dart   # Model batch, kalkulasi sisa hari & lokasi rak
│   ├── data/
│   │   ├── services/
│   │   │   └── gs1_parser_service.dart # Logika parsing GS1 DataMatrix AI (01, 10, 17)
│   │   └── repositories/
│   │       └── medication_repository.dart # State repository (data sampel, pencarian, karantina)
│   └── ui/
│       ├── core/
│       │   ├── app_colors.dart         # Palet warna medis modern
│       │   ├── app_theme.dart          # Tema Material 3 clean white & soft teal
│       │   └── widgets/
│       │       └── urgency_badge.dart  # Badge pil sisa hari kedaluwarsa
│       └── features/
│           ├── auth/views/             # Layar Masuk / Daftar
│           ├── dashboard/views/        # Dasbor utama & Hero Warning Card
│           ├── scan/views/             # Viewfinder pemindai & form input cepat
│           ├── catalog/views/          # Katalog obat & rincian obat tarik karantina
│           ├── settings/views/         # Layar pengaturan apoteker
│           └── shell/views/            # Navigasi tab bawah & tombol floating scan
├── supabase/
│   └── migrations/
│       └── 20261102_initial_fefo_schema.sql # Skrip SQL lengkap: Tabel, RPC FEFO, Cron EWS, & FHIR View
└── test/
    └── widget_test.dart                # Pengujian otomatis widget, GS1 parser, & FEFO logic
```

---

## 🧪 Menjalankan Pengujian

Jalankan pengujian unit dan widget otomatis:
```powershell
flutter test
```

Jalankan analisis kualitas kode:
```powershell
flutter analyze
```

---

## 📱 Menjalankan Aplikasi

Jalankan pada emulator ponsel, perangkat fisik, atau desktop Windows/Chrome:
```powershell
flutter run
```

---

## 🗄️ Menjalankan Skrip Database Supabase

File migrasi database tersedia di:
[`supabase/migrations/20261102_initial_fefo_schema.sql`](file:///c:/Users/ThinkPad/Documents/BLUEPRINT%20GRAVITY/pharmaguard/supabase/migrations/20261102_initial_fefo_schema.sql)

Skrip ini berisi:
1. Skema tabel: `master_medications`, `medication_batches`, `rack_locations`, `stock_mutations`, `user_staff`, `audit_logs`.
2. Fungsi RPC PostgreSQL:
   - `get_fefo_dispense_queue(p_medication_id)`: Menghasilkan antrean sisa masa simpan terdekat secara otonom.
   - `quarantine_batch(p_batch_id, p_staff_id, p_reason)`: Memindahkan status batch ke karantina fisik serta mencatat mutasi audit.
   - `check_and_update_expiry_status()`: Fungsi otomatisasi Cron Job evaluasi status H-5 / H-30 setiap pagi.
3. View interoperabilitas `view_fhir_medication_inventory` yang memformat data ke format resmi **HL7 FHIR SATUSEHAT Kemenkes RI**.
4. Seed data awal yang identik dengan sampel sediaan farmasi di dokumen Blueprint.

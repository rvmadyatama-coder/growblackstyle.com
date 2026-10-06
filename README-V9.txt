GROWBLACKSTYLE V9 PHOTO SYSTEM

Tujuan:
Membuat versi staging 1.000 halaman dengan foto berbeda dan sumber/lisensi tercatat.

AMAN:
- Tidak menyentuh folder hotel yang sedang live/local.
- Tidak mengubah sitemap.
- Tidak push GitHub.
- Sumber gambar: Wikimedia Commons.
- Setiap gambar dicek metadata lisensi dan duplikat URL.
- Jika foto hotel tidak ditemukan, sistem memakai foto destinasi/lokasi dan memberi labelnya.

LANGKAH:
1. Extract ZIP ke C:\GROWBLACK-GITHUB
2. Buka PowerShell
3. Jalankan:
   Set-ExecutionPolicy -Scope Process Bypass
   cd C:\GROWBLACK-GITHUB
   .\update-v9-photo.ps1 -Limit 10

4. Periksa:
   C:\GROWBLACK-GITHUB\hotel-V9-STAGING

5. Jika 10 halaman sudah benar, baru jalankan:
   .\update-v9-photo.ps1

CATATAN:
V9 adalah tahap foto + shell editorial. Artikel masih memakai kerangka editorial berbasis hotel/lokasi dan TIDAK boleh disebut sebagai 1.000 artikel riset mendalam. Untuk AdSense, tahap berikutnya sebaiknya memperkaya halaman dengan fakta hotel yang benar-benar diverifikasi.

GROWBLACKSTYLE V8
=================

Tujuan:
- Mengambil nama + lokasi dari hotel-OLD.
- Membuat ulang halaman hotel dengan desain editorial V7.
- Setiap halaman mempunyai artikel yang berbeda berdasarkan hotel/lokasi.
- Setiap halaman mempunyai cover ilustrasi SVG berbeda.
- Canonical, robots, GA4, lang=en dan anti-translate dipertahankan.

PENTING:
Cover V8 adalah ILUSTRASI ORIGINAL, bukan foto hotel nyata.
Untuk foto hotel nyata, gunakan foto yang memang Anda punya hak pakainya.
Jangan push ke GitHub sebelum audit.

Cara menjalankan:
1. Extract ZIP.
2. Copy update-v8.ps1 ke C:\GROWBLACK-GITHUB
3. Buka PowerShell.
4. Jalankan:
   Set-ExecutionPolicy -Scope Process Bypass
   cd C:\GROWBLACK-GITHUB
   .\update-v8.ps1

Backup:
Folder hotel-OLD tidak disentuh.
Sebaiknya backup folder hotel sebelum menjalankan.

Audit setelah selesai:
(Get-ChildItem "C:\GROWBLACK-GITHUB\hotel" -Directory).Count

Jumlah gambar unik:
Get-ChildItem "C:\GROWBLACK-GITHUB\hotel" -Directory | ForEach-Object {
  Get-ChildItem $_.FullName -Filter "editorial-cover.svg"
} | Measure-Object

Jumlah artikel:
Get-ChildItem "C:\GROWBLACK-GITHUB\hotel" -Directory | ForEach-Object {
  Test-Path (Join-Path $_.FullName "index.html")
} | Where-Object {$_} | Measure-Object

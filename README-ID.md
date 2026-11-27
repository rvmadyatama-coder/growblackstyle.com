# GROWBLACKSTYLE — Premium Editorial Portal

Fondasi portal media digital GROWBLACKSTYLE dengan pendekatan editorial premium: hitam, putih, dan oranye. Fokus liputan otomotif dan industri, dengan cakupan bisnis, teknologi, regulasi, modifikasi, motorsport, dan review.

## Struktur yang disiapkan
- Beranda editorial dan daftar berita terbaru.
- Arsip seluruh artikel.
- Halaman kategori: Otomotif, Industri, Bisnis, Teknologi, Regulasi, Modifikasi, Motorsport, Review.
- Template artikel dengan penulis, tanggal, ringkasan, foto, caption, dan sumber.
- Halaman Tentang, Kontak, Kebijakan Privasi, Pedoman Redaksi, dan Penafian.
- SEO dasar, sitemap, RSS, dan workflow GitHub Actions untuk GitHub Pages.
- Kerangka CMS Decap di `/admin/`.
- Link direktori hotel pada subdomain terpisah `hotel.growblackstyle.com`.

## Repository dan domain
Paket ini disiapkan untuk repository yang terlihat pada screenshot GitHub: `rvmadyatama-coder/growblackstyle.com`, branch `main`. Repository itu juga memuat halaman hotel yang sudah ada. Karena itu, **jangan mengunggah paket ini dengan cara menghapus seluruh isi repository**. Lakukan backup/branch terlebih dahulu, kemudian gabungkan file portal dengan hati-hati. Jangan menimpa folder `hotel/`, `hotel-directory/`, `hotel-before-hero-fix/`, atau konfigurasi terkait hotel tanpa audit.

File `CNAME` mengarah ke `growblackstyle.com`. Jangan ubah DNS subdomain hotel. Domain utama baru dialihkan ke versi portal setelah pengujian dan persetujuan pemilik situs.

## CMS — belum aktif untuk login
`admin/config.yml` diarahkan ke repository di atas, tetapi Decap CMS belum dapat login sampai layanan autentikasi GitHub/OAuth atau Decap Turbo disiapkan. GitHub Pages tidak menyediakan server OAuth. Jangan pernah menyimpan GitHub Personal Access Token atau Client Secret di file publik.

## Menjalankan lokal
Persyaratan: Ruby dan Bundler.

```bash
bundle install
bundle exec jekyll serve
```

Buka `http://127.0.0.1:4000`.

## Menulis artikel
Buat file Markdown di folder `_berita/`. Gunakan front matter seperti berikut:

```yaml
---
layout: artikel
title: "Judul laporan yang spesifik"
date: 2026-11-20 09:00:00 +0700
author: "Nama Penulis"
category: "Otomotif"
category_slug: "otomotif"
description: "Ringkasan faktual artikel untuk pembaca dan mesin pencari."
image: "/assets/uploads/foto-utama.jpg"
image_alt: "Deskripsi faktual foto"
image_caption: "Keterangan foto dan kredit fotografer"
source: "Nama dokumen atau narasumber"
source_url: "https://example.com/sumber"
---

Isi laporan dengan konteks, fakta yang diverifikasi, kutipan beratribusi, dan analisis orisinal.
```

Jangan menerbitkan artikel contoh, placeholder, konten salinan, atau klaim yang belum diverifikasi. Pastikan hak penggunaan foto dan materi visual jelas.

## Checklist sebelum produksi dan AdSense
1. Isi identitas redaksi dan alamat kontak yang benar.
2. Pastikan halaman kebijakan mencerminkan praktik privasi/layanan yang benar-benar digunakan; halaman contoh ini perlu ditinjau dan disesuaikan.
3. Konfigurasikan login CMS dan uji alur draft/review/publikasi.
4. Tambahkan artikel orisinal yang lengkap, relevan, dan memiliki nilai bagi pembaca.
5. Uji tautan, tampilan mobile, performa, sitemap, RSS, 404, dan semua halaman kategori.
6. Audit seluruh halaman hotel yang sudah ada sebelum deployment.
7. Periksa kebijakan Google AdSense dan Search sebelum mengajukan. Tidak ada template yang dapat menjamin persetujuan.

Referensi resmi:
- https://support.google.com/adsense/answer/9724
- https://support.google.com/adsense/answer/7299563
- https://decapcms.org/docs/github-backend/
- https://docs.github.com/en/pages

# Cara Klaim Muse — Pakai VPN & Tanpa VPN

> 🇬🇧 English version: [CLAIM-MUSE.md](CLAIM-MUSE.md)

Petunjuk singkat buat bergabung ke **Muse** dari luar Amerika Serikat/Kanada,
lalu menukarkan kode referral sebelum lanjut memasang muse-vps-tailscale.

---

<div align="center">

## 🎁 KODE REFERRAL: `IB4FJR`

**Tukarkan dalam 48 jam setelah bergabung dan kita berdua mendapatkan
1 miliar token Muse.**

### 👉 [Gabung Muse di sini](https://muse.ai/join)

**Kode: `IB4FJR`**

</div>

---

> Kode di atas adalah kode referral penulis repo ini. Jangan tertukar
> dengan kode orang lain yang mungkin kamu lihat di internet.

## Sebelum mulai

Siapkan:

- Akun Google/email untuk mendaftar Muse
- Browser
- Untuk jalur VPN: VPN tepercaya dengan server **Amerika Serikat** atau
  **Kanada**
- Untuk jalur tanpa VPN: akun Google cadangan disarankan, karena login
  dilakukan lewat layanan pihak ketiga bernama Airtap

Pilih **salah satu** jalur di bawah ini.

## Jalur A — Pakai VPN US/Canada

1. Nyalakan VPN, lalu pilih server **United States** atau **Canada**.
2. Biarkan VPN tetap menyala selama pendaftaran dan penukaran kode.
3. Buka **[https://muse.ai/join](https://muse.ai/join)**.
4. Daftar akun Muse baru seperti biasa sampai masuk ke Dashboard.
5. Tukarkan kode referral dengan langkah di bagian **Cara menukarkan
   kode** di bawah.
6. Pastikan halaman menampilkan hasil bahwa kode diterima. Sekadar membuka
   link atau memasukkan kode belum tentu berarti penukaran berhasil.

Kalau halaman masih menunjukkan batasan wilayah, coba server US/Canada
lain, lalu refresh halaman.

## Jalur B — Tanpa VPN, lewat Airtap

Jalur ini memakai browser/lingkungan Airtap, jadi kamu tidak memasang VPN
di perangkatmu sendiri.

1. Buka **[https://legacy.airtap.ai/app/login](https://legacy.airtap.ai/app/login)**.
2. Daftar atau login ke Airtap. Gunakan akun Google cadangan; login hanya
   lewat tombol/proses Google resmi dan jangan memasukkan password Google
   ke formulir asing yang mencurigakan.
3. Setelah masuk ke lingkungan/browser Airtap, buka Chrome atau browser
   yang tersedia di sana.
4. Ketik **[https://muse.ai/join](https://muse.ai/join)**.
5. Daftar akun Muse baru seperti biasa sampai masuk ke Dashboard.
6. Tukarkan kode referral dengan langkah di bawah.

Ketersediaan dan cara kerja Airtap bisa berubah. Kalau jalurnya sudah
tidak bekerja, gunakan Jalur A.

## Cara menukarkan kode

Lakukan ini **maksimal 48 jam setelah akun Muse dibuat**.

### Kalau memakai website Muse

1. Buka **Settings**.
2. Masuk ke **General → Usage → Redeem invite code**.
3. Masukkan kode ini persis:

<div align="center">

# `IB4FJR`

</div>

4. Klik tombol konfirmasi.
5. Baca hasil di layar: berhasil, tidak valid, sudah dipakai, atau jendela
   penukaran sudah lewat.

### Kalau memakai aplikasi HP

1. Buka **Settings** di aplikasi Muse.
2. Pilih **Redeem token**.
3. Masukkan **`IB4FJR`**, lalu konfirmasi.

> Menu penukaran adalah menu di dalam **Muse**, bukan Settings HP dan
> bukan Settings WhatsApp/aplikasi lain.

## Kalau ada masalah

| Masalah | Coba ini |
|---|---|
| Masih kena batasan wilayah saat pakai VPN | Ganti server US/Canada lain, pastikan VPN belum putus, lalu refresh |
| Airtap tidak membuka browser/lingkungannya | Tunggu sebentar dan coba lagi; kalau tetap gagal, pakai Jalur A |
| Kolom kode tidak ketemu | Cek jalurnya: website di **General → Usage**; aplikasi HP di **Redeem token** |
| Kode ditolak | Baca pesan hasil di layar. Jangan mengulang terlalu sering; kode bisa tidak valid, sudah digunakan, atau masa 48 jam sudah habis |
| Sudah lewat 48 jam | Penukaran referral untuk akun itu mungkin sudah tidak tersedia. Hasil/pesan di Muse adalah penentunya |

## Setelah Muse aktif, lanjut ke muse-vps-tailscale

Akun Muse yang aktif tinggal di sebuah VM yang bisa kamu ajak ngobrol
lewat chat. Project ini bikin kamu bisa masuk ke VM itu beneran pakai
**SSH lewat Tailscale** — privat, pakai kunci (tanpa password), dan tanpa
batas 60 menit:

- VM Muse menelepon keluar ke laptop kamu lewat tailnet dan menitipkan
  satu port di sana;
- kamu masuk lewat port titipan itu dari terminal laptop kamu sendiri;
- tidak ada alamat publik yang dibuka, dan tidak ada relay perusahaan
  di tengahnya.

Lanjut ke:

- 🇮🇩 [Tutorial lengkap muse-vps-tailscale](TUTORIAL.id.md)
- 🇬🇧 [Complete muse-vps-tailscale tutorial](TUTORIAL.md)
- 🏠 [Kembali ke README utama](../README.id.md)

---

*Petunjuk komunitas independen—bukan petunjuk resmi Meta, Muse, atau
Airtap. Ketersediaan wilayah, tampilan menu, cara kerja layanan pihak
ketiga, dan syarat bonus dapat berubah. Jika layar Muse menampilkan
syarat atau hasil yang berbeda, informasi di layar tersebut yang berlaku.*

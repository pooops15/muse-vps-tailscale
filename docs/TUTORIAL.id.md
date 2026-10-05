# Tutorial Lengkap: SSH ke VM Muse Lewat Tailscale (Reverse SSH)

> 🇬🇧 English version: [TUTORIAL.md](TUTORIAL.md)

Tutorial ini ditulis buat **orang yang sangat awam**. Kita pasang
semuanya pelan-pelan, satu baut dalam satu waktu. Di akhir, kamu bisa
masuk ke VM Muse kamu pakai SSH — privat lewat Tailscale, pakai kunci
(tanpa password), tanpa batas 60 menit.

Belum punya akun Muse? Mulai dari
**[petunjuk klaim Muse](CLAIM-MUSE.id.md)** dulu — ada jalur VPN dan
tanpa VPN, plus kode referral **`IB4FJR`** (tukar dalam 48 jam, kita
berdua dapat 1 miliar token).

---

## Bagian 0 — Kita mau bikin apa?

Masalahnya begini, pakai bahasa bayi:

- VM tempat Muse tinggal itu teleponnya **cuma bisa nelepon keluar,
  nggak bisa ditelepon**. Nggak ada alamat publik, dan Tailscale di
  dalamnya cuma jadi *client* (dia yang nyamperin mesin lain, bukan
  disamperin).
- Jadi biar kamu bisa masuk, alurnya dibalik: **VM yang nelepon ke
  laptop kamu** lewat Tailscale, lalu telepon itu dibiarkan terbuka dan
  dipakai buat **nitipin satu port** di laptop kamu (nomor standarnya
  `2223`).
- Kamu tinggal SSH ke **laptop kamu sendiri** di port titipan itu —
  koneksinya diteruskan lewat telepon yang terbuka tadi, mendaratnya
  tetap di VM Muse.

Gambarnya:

```
Kamu (CMD di laptop)
   |
   |  ssh -i muse-key -p 2223 root@127.0.0.1
   v
Port titipan 2223 di laptop kamu
   |
   |  (saluran yang dibuka VM, lewat Tailscale)
   v
sshd di VM Muse (localhost port 2222, key-only)
```

Dua sisi yang dipasang:

- **Sisi laptop (Windows)** — Bagian 1. Dikerjain sekali, permanen.
- **Sisi VM Muse** — Bagian 2. Dikerjain dari chat Muse / terminal VM.

Istilah yang dipakai di tutorial ini dijelasin di
[README utama](../README.id.md) Bab 4 (Kamus kecil).

---

## Bagian 1 — Sisi laptop Windows

### 1.1 Pasang Tailscale dan catat IP laptop kamu

1. Install aplikasi **Tailscale** di laptop dari tailscale.com, lalu
   login pakai akun kamu.
2. Buka Command Prompt (CMD biasa, bukan admin) dan jalanin:

```
"C:\Program Files\Tailscale\tailscale.exe" ip -4
```

3. Keluar satu alamat `100.x.x.x` — itu **IP Tailscale laptop kamu**.
   Catat, nanti dipakai di sisi VM. Di tutorial ini alamat itu disebut
   `YOUR_LAPTOP_TAILNET_IP`.

### 1.2 Cek SSH Server Windows: jalan atau belum

Masih di CMD, jalanin:

```
sc query sshd
```

- Kalau keluar `STATE : 4 RUNNING` — beres, lanjut ke 1.3.
- Kalau keluar error / `FAILED 1060` — server SSH belum terpasang.
  Pasang lewat PowerShell sebagai Administrator:

```
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic
```

Lalu cek lagi pakai `sc query sshd` sampai statusnya `RUNNING`.

### 1.3 Bikin kunci kamu sendiri buat masuk VM

Kamu butuh satu pasang kunci: yang privat tinggal di laptop, yang
publik nanti ditempel di VM.

Di CMD biasa (posisinya di folder rumah kamu, `C:\Users\<kamu>>`):

```
ssh-keygen -t ed25519 -f muse-key
```

Tekan Enter terus (passphrase boleh dikosongkan). Hasilnya dua file:

| File | Isinya |
|---|---|
| `muse-key` | Kunci **privat** kamu. Rahasia, jangan dikasih ke siapa pun, jangan dihapus |
| `muse-key.pub` | Kunci **publik** kamu. Ini yang boleh disebar |

Keluarkan isinya dan kirim ke Muse (di chat) atau tempel sendiri ke VM
nanti di Bagian 2.2:

```
type muse-key.pub
```

Hasilnya satu baris diawali `ssh-ed25519 AAAA...` — itu yang dikirim,
**bukan** file tanpa `.pub`.

> **Pengalaman nyata penulis:** folder `.ssh` bawaan Windows kadang
> terkunci aneh — baca file `.pub` di dalamnya bisa kena
> `Access is denied` bahkan sebagai Administrator. Makanya tutorial ini
> sengaja bikin kunci khusus `muse-key` di folder rumah (di luar folder
> `.ssh`). Jangan lawan folder itu; pakai kunci khusus ini saja.

### 1.4 Buka firewall buat SSH dari Tailscale saja

Sekarang buka **Command Prompt sebagai Administrator** (klik kanan →
Run as administrator). Jalanin:

```
netsh advfirewall firewall add rule name="SSH Tailscale" dir=in action=allow protocol=TCP localport=22 remoteip=100.64.0.0/10
```

- Berhasil kalau keluar: `Ok.`
- `remoteip=100.64.0.0/10` itu artinya: yang boleh masuk **cuma dari
  jaringan Tailscale** — bukan dari seluruh internet. Jangan diganti
  jadi semua alamat.
- Kalau keluar "already exists", langkah ini sudah pernah kelar. Lanjut.

### 1.5 Pasang kunci publik VM ke laptop kamu

Kenapa ini perlu? Nanti VM yang nelepon ke laptop kamu. Laptop harus
kenal siapa yang nelepon — makanya **kunci publik VM** ditempel di
laptop. (Kunci publik memang dibuat buat disebar; kunci privat VM tetap
di VM.)

Cara gampang: pakai script repo ini, `scripts\windows-setup.ps1`, di
PowerShell sebagai Administrator. Script-nya mengecek admin, mengecek
sshd, minta kamu menempel kunci publik VM, lalu ngerjain langkah 1.4
dan 1.5 ini sekaligus.

Cara manual, di CMD Administrator yang sama:

```
echo ssh-ed25519 AAAA...YOUR_VM_PUBLIC_KEY... your-vm>> C:\ProgramData\ssh\administrators_authorized_keys
```

Ganti `AAAA...YOUR_VM_PUBLIC_KEY...` dengan kunci publik VM yang
beneran (satu baris penuh, jangan kepotong). Lalu kunci izin file-nya —
ini syarat mutlak SSH Server Windows:

```
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
```

Berhasil kalau keluar: `Successfully processed 1 files; Failed processing 0 files`

> **Catatan akun bukan admin:** kalau akun Windows kamu **bukan**
> anggota grup Administrators, sshd Windows membaca file lain:
> `C:\Users\<kamu>\.ssh\authorized_keys`. Tempel kunci VM di sana
> sebagai gantinya, dan langkah icacls ProgramData di atas dilewati.

### 1.6 Pastikan "Allow incoming connections" nyala (Shields Up mati)

1. Klik kanan ikon **Tailscale** di pojok kanan bawah, dekat jam.
2. Buka **Preferences**.
3. Pastikan **Allow incoming connections** tercentang.

Itu saklar yang sama dengan "Shields Up": kalau incoming **nggak**
diizinkan, semua koneksi masuk — termasuk telepon dari VM — ditolak
diam-diam, persis gejala yang penulis alami sebelum langkah ini beres.

**Sisi laptop selesai.** Sekali pasang, permanen. Nggak ada lagi yang
perlu diubah di laptop sesudah ini.

---

## Bagian 2 — Sisi VM Muse

Bagian ini dikerjakan di dalam VM (lewat chat Muse, minta dia yang
jalanin — atau dari terminal VM kalau kamu sudah punya akses lain).

### 2.1 Siapkan folder project

```
mkdir -p $HOME/muse-vps-tailscale
cp -r scripts $HOME/muse-vps-tailscale/
cd $HOME/muse-vps-tailscale
chmod +x scripts/*.sh scripts/*.py
```

Di sisa tutorial, folder ini disebut **folder project**. Semua file
penting (host key, authorized_keys, skrip) tinggal di sini, di dalam
`$HOME` yang persisten — bukan di `/etc` yang gampang hilang kalau
mesin sandbox di-reset.

### 2.2 Tempel kunci publik kamu ke VM

Kunci publik dari langkah 1.3 ditempel jadi isi file `authorized_keys`
di folder project — satu baris, satu kunci:

```
echo "ssh-ed25519 AAAA...YOUR_PUBLIC_KEY... your-name" >> authorized_keys
chmod 600 authorized_keys
```

### 2.3 Nyalakan sshd khusus (key-only, port 2222)

```
bash scripts/setup-sshd.sh
```

Skrip itu memasang openssh-server kalau belum ada, bikin host key,
nulis `sshd_config` dari `scripts/sshd_config.example`, dan menyalakan
sshd dengan aturan:

- dengar **hanya** di `127.0.0.1` port `2222`;
- **password dimatikan total** (`PasswordAuthentication no`);
- yang boleh masuk hanya kunci di `authorized_keys`.

Tes lokal dulu pakai kunci tes sementara atau kunci kamu dari mesin
lain — intinya perintah ini harus berhasil sebelum lanjut:

```
ssh -p 2222 root@127.0.0.1 "echo halo-dari-dalem"
```

### 2.4 Gabungkan VM ke tailnet kamu

Pakai konektor Tailscale bawaan runtime VM:

```
tailscale up
```

Perintah itu mengeluarkan satu link. Pemilik akun (kamu) yang membuka
link itu dan menyetujui device-nya (nama device `muse`). Sesudah
disetujui, cek:

```
tailscale status
```

Targetnya: status **Connected**, VM punya IP `100.x.x.x` sendiri
(disebut `YOUR_VM_TAILNET_IP`), dan laptop kamu kelihatan di daftar
peer dengan IP yang kamu catat di 1.1.

> **TRIK PENTING — kalau `tailscale up` macet:** kadang `up` cuma
> membalas *"Could not finish connecting to Tailscale. Retrying."*
> berulang-ulang dan **link-nya nggak pernah keluar**, gara-gara
> identitas lama yang basi nyangkut. Obat yang terbukti di setup
> penulis:
>
> ```
> tailscale down
> tailscale up
> ```
>
> `down` membuang identitas basi itu ("Signed out. Connecting again
> needs a fresh approval."), dan `up` sesudahnya **langsung**
> mengeluarkan link dalam waktu kurang dari semenit.

> **NOTE soal proxy:** di sandbox penulis, mesin nggak bisa menjangkau
> tailnet secara langsung — lalu lintas TCP ke tailnet naik lewat
> proxy egress runtime-nya, port `3130`, pakai alat kecil
> `scripts/tsconnect.py` sebagai ProxyCommand ssh. Sesuaikan alamat
> proxy itu dengan runtime kamu lewat variabel `TSCONNECT_PROXY_HOST` /
> `TSCONNECT_PROXY_PORT` / `TSCONNECT_PROXY_URL`. Kalau VM kamu punya
> routing Tailscale asli, bagian ini nggak diperlukan.

### 2.5 Tes jalan VM → laptop (banner check)

Sebelum buka tunnel, buktikan dulu teleponnya bisa nyambung. Dari VM:

```
ssh -o "ProxyCommand=python3 scripts/tsconnect.py %h %p" \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  YOUR_WINDOWS_USERNAME@YOUR_LAPTOP_TAILNET_IP "echo sampe-laptop"
```

- Kalau keluar `sampe-laptop` — jalan VM → laptop **sehat**. Lanjut.
- Kalau koneksinya kosong / timeout tanpa jawaban — laptop masih
  nahan. Balik ke 1.4 (firewall) dan 1.6 (Allow incoming connections).
  Di setup penulis, persis dua itu biang masalahnya; sesudah beres,
  banner SSH laptop langsung keluar (`SSH-2.0-OpenSSH_for_Windows_...`).

### 2.6 Nyalakan reverse tunnel (dijaga supervisor)

```
LAPTOP_TS_IP=YOUR_LAPTOP_TAILNET_IP WIN_USER=YOUR_WINDOWS_USERNAME \
  bash scripts/reverse-start.sh
```

Yang terjadi: satu proses **supervisor** (pengawas) jalan di latar.
Dia membuka ssh dari VM ke laptop kamu, menitipkan port
`127.0.0.1:2223` di laptop yang diteruskan ke sshd VM port `2222`.
Kalau ssh itu putus, supervisor menyalakannya lagi tiap 10 detik.

Cek dari laptop (CMD biasa):

```
netstat -an | findstr 2223
```

Targetnya ada baris: `TCP 127.0.0.1:2223 ... LISTENING`.

Log tunnel ada di file `reverse.log` di folder project VM.

### 2.7 Tes loop penuh (bukti paling kuat)

Masih dari sesi ssh di 2.5 (kamu sedang "di dalam" laptop dari VM),
jalanin perintah konek final dari Bagian 3 di sana. Kalau yang menjawab
adalah hostname VM Muse kamu — rantai lengkapnya terbukti:
VM → laptop → port titipan → balik ke VM.

---

## Bagian 3 — Cara kamu konek sehari-hari

Dari **CMD biasa** di laptop, posisinya di folder rumah kamu:

```
ssh -i muse-key -p 2223 root@127.0.0.1
```

Pecahan bahasa bayinya:

- `-i muse-key` = "masuk pakai kunci yang ini" (kunci dari 1.3)
- `-p 2223` = lewat port titipan di laptop kamu sendiri
- `root@127.0.0.1` = tujuannya kelihatan laptop sendiri, tapi port itu
  isinya VM — kamu diteruskan ke dalam

Kejadian pertama kali: ditanya `Are you sure you want to continue
connecting?` — ketik `yes`, Enter. Sesudah itu **nggak ada password**
yang ditanya.

Tanda berhasil: prompt berubah jadi prompt VM Muse kamu (misalnya
`root@<nama-host-vm>`). Coba:

```
whoami
hostname
ls
```

Keluar pakai `exit`. Sesi ini **nggak ada batas 60 menit** — selama
laptop kamu online dan tunnel VM menyala, port titipan itu ada terus.

Mematikan tunnel (dari sisi VM): `bash scripts/reverse-stop.sh`.

---

## Bagian 4 — Sesudah mesin VM di-reset (sekarang sembuh sendiri)

Sandbox Muse bisa di-reset sewaktu-waktu. Yang terjadi:

| Hal | Nasibnya |
|---|---|
| Sisi laptop (firewall, kunci VM, Tailscale app) | **Aman permanen**, nggak perlu diulang |
| Koneksi Tailscale VM | Di runtime penulis, nempel terus dan IP-nya sama sesudah reset |
| File di folder project (`$HOME`) | **Aman** — host key dan authorized_keys nggak hilang |
| sshd + supervisor yang sedang jalan | Mati — **tapi penjaga auto-recovery menyalakannya lagi sendiri** (di bawah ini) |

Jadi sesudah reset, pekerjaanmu nol: **tunggu kira-kira 1 menit,
lalu konek kayak biasa.** Kalau sesudah itu masih gagal juga, baru
pakai jalan manual di akhir bagian ini.

### 4.1 Auto-recovery: si penjaga `ensure-up.sh`

Project ini punya skrip penjaga kecil: `scripts/ensure-up.sh`. Tiap
dia jalan, dia memeriksa empat hal **berurutan** dan membetulkan
yang rusak:

1. **Tailscale-nya Connected nggak?** Kalau nggak, dia berhenti dan
   lapor `TAILSCALE_DOWN`. Yang ini nggak bisa dibetulkan skrip —
   menyetujui perangkat itu pekerjaan manusia. Inilah satu-satunya
   batas jujur dari seluruh sistem ini.
2. **Binary sshd-nya masih ada nggak?** Reset bisa menghapus paket
   sistem. Kalau hilang, si penjaga memasang ulang `openssh-server`.
3. **sshd lokalnya lagi dengerin di port `2222` nggak?** Kalau
   nggak, dia nyalakan, pakai config dari folder project sendiri.
4. **Supervisor-nya hidup nggak?** Kalau nggak, dia nyalakan — dan
   port titipan `2223` muncul lagi di laptopmu.

Kalau semuanya sudah sehat, si penjaga **nggak ngapa-ngapain** dan
cuma nulis `HEALTHY`. Makanya aman dipanggil berulang-ulang
(idempotent) — dari penjadwal, atau manual pakai tangan.

### 4.2 Siapa yang manggil penjaganya? Penjadwal yang selamat dari reset

Di setup penulis, yang manggil adalah **hook runtime**
(`scripts/ensure-hook.sh`, didaftarkan pakai
`scripts/ssh-tunnel-ensure.hook.json.example`) yang memeriksa tiap
**30 detik**. Dua pilihan desainnya ini inti seluruh triknya:

- **Hook-nya tinggal di `$HOME`, bukan di systemd.** Reset VM
  menghapus semua yang di luar `$HOME` — unit systemd di `/etc` ikut
  lenyap. Penjadwal yang disimpan di dalam `$HOME` selamat dari
  semua reset — persis saat dia paling dibutuhkan.
- **Perbaikannya murni bash, nol token AI.** Hook cuma
  *membangunkan agent* dalam tiga keadaan, paling banyak sekali per
  kejadian: sesudah auto-repair berhasil (biar agent memverifikasi
  dan mengabari kamu pintunya sudah balik), kalau Tailscale putus
  5 menit lebih (kamu perlu menyetujui ulang), atau kalau
  perbaikannya gagal.

Bukti dari mesin penulis (2026-10-05): sshd dan supervisor-nya
**dibunuh sengaja** buat pura-pura reset — dalam waktu **75 detik**
semuanya nyala lagi sendiri, dan port di laptop balik dengerin.
(Pagi yang sama, sebelum penjaga ini ada, reset beneran jam 06:24
menyambut penulis dengan `Connection refused` — penjaga ini jawaban
buat pagi itu.)

Satu syarat: environment penjadwalnya harus berisi dua variabel
yang sama kayak yang dibutuhkan `reverse-start.sh` (`LAPTOP_TS_IP`,
`WIN_USER`) — pasang di tempat penjadwalmu menyimpan
environment-nya.

### 4.3 Jebakan flock (bug beneran, biar kamu nggak ngulangin)

`ensure-up.sh` mengambil kunci `flock` biar dua penjaga nggak bisa
tabrakan. Versi pertamanya punya bug yang nyebelin: daemon yang
dinyalakan si penjaga (sshd, supervisor) **mewarisi file descriptor
kuncinya** — alhasil kuncinya terkunci *selamanya*, dipegang daemon
yang nggak pernah mati, dan semua penjaga berikutnya cuma lapor
`LOCKED` tanpa membetulkan apa-apa. Obatnya satu pengalihan kecil:
nyalakan semua daemon dengan fd kuncinya ditutup — `9>&-`. Kalau
kamu utak-atik skrip ini, jangan hapus empat karakter itu.

### 4.4 Jalan manual (selalu tersedia)

Kalau auto-recovery belum terpasang, atau sesudah semenit masih
rusak juga, jalankan si penjaga sekali pakai tangan:

```
bash scripts/ensure-up.sh        # sekali jalan: cek + betulkan semua
```

—atau bilang saja ke agent-mu: *"nyalain tailscale ssh"*. Jalan
manual lama yang full manual — langkah 2.3 lalu 2.6 — juga tetap
jalan persis kayak dulu.

### 4.5 Di mesin Linux biasa (tanpa runtime khusus)

Kamu nggak butuh hook runtime punya penulis. Apa pun yang memanggil
`ensure-up.sh` secara teratur bisa:

- **cron** — satu baris (edit pakai `crontab -e`), memeriksa tiap
  menit:

  ```
  * * * * * LAPTOP_TS_IP=YOUR_LAPTOP_TAILNET_IP WIN_USER=YOUR_WINDOWS_USERNAME /path/ke/project/scripts/ensure-up.sh >> /path/ke/project/ensure.log 2>&1
  ```

- atau **service + timer systemd** yang menjalankan skrip yang sama.
  Di VPS biasa yang nggak pernah dihapus, systemd sah-sah saja —
  pilihan hook di `$HOME` di atas cuma penting di sandbox yang
  doyan reset kayak punya penulis.

---

## Bagian 5 — Kalau ada masalah (gejala → sebab → obat)

| Gejala | Sebab paling mungkin | Obatnya |
|---|---|---|
| `Connection refused` pas konek ke 2223 | Tunnel atau sshd VM mati (paling sering: VM-nya baru saja di-reset) | Tunggu kira-kira 1 menit — penjaga auto-recovery (Bagian 4) menyalakannya lagi sendiri. Masih refused? Jalankan `bash scripts/ensure-up.sh` di VM, lalu cek `netstat` laptop: 2223 LISTENING nggak |
| `Permission denied (publickey)` | Kunci yang ditawarkan salah, atau kunci publikmu belum ada di `authorized_keys` VM | Pastikan perintah pakai `-i muse-key`, posisi CMD di folder tempat file `muse-key` berada, dan baris `.pub`-nya sudah ditempel di VM (2.2) |
| VM nelepon laptop selalu gagal / banner kosong | Laptop nahan: firewall belum kebuka atau Allow incoming connections mati | Ulangi 1.4 dan 1.6 persis; dua ini penyebab di setup penulis |
| Baca `.pub` di folder `.ssh` Windows kena `Access is denied` | Folder `.ssh` bawaan Windows terkunci aneh (pengalaman nyata penulis, bahkan sebagai admin) | Jangan lawan. Pakai kunci khusus di folder rumah kayak langkah 1.3 |
| `tailscale up` cuma "Retrying", link nggak keluar | Identitas Tailscale lama basi nyangkut di VM | `tailscale down` dulu, baru `tailscale up` lagi (lihat kotak trik di 2.4) |
| Tes balik dari dalam sandbox penulis kelihatan putus-putus | Jalur tesnya muter lewat proxy egress sandbox, memang flaky di setup penulis | Nilainya dari **koneksi langsung kamu**: di setup penulis, konek perdananya langsung tembus sekali coba. Jangan menilai dari tes balik sandbox saja |
| Port 2223 sudah dipakai di laptop | Ada program lain / tunnel lama belum mati | Matikan tunnel lama dari VM (`reverse-stop.sh`), atau ganti `REMOTE_PORT` di skrip supervisor dan sesuaikan perintah konekmu |
| Ditanya password terus | Kamu konek ke port yang salah (misalnya 22 laptop sendiri), atau sshd VM salah config | Pastikan port-nya `2223` dan sshd VM jalan dari `setup-sshd.sh` (password memang dimatikan di config itu) |

---

## Penutup

Kalau semua langkah di atas hijau, kamu punya pintu privat ke VM Muse
kamu: tanpa alamat publik, tanpa relay perusahaan, tanpa hitungan 60
menit. Yang menjaganya cuma dua kunci yang saling kenal — dan dua-duanya
kamu yang pegang talinya (cabut satu baris kunci = akses mati saat itu
juga).

Balik ke [README utama](../README.id.md).

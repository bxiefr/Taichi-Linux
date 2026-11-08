# Taichi Linux

Arch Linux tabanlı, KDE Plasma masaüstlü, Calamares kuruculu bir Linux dağıtımı.
ISO'lar [archiso](https://wiki.archlinux.org/title/Archiso) ile GitHub Actions üzerinde derlenir.
UEFI ve eski BIOS birlikte desteklenir.

## ISO nasıl derlenir?

1. Repoda **Actions** sekmesine gir.
2. Soldan **Build ISO** iş akışını seç.
3. **Run workflow** düğmesine bas (sürüm boş bırakılabilir, tarih kullanılır).
4. Bitince çalıştırmanın sayfasının altındaki **Artifacts** bölümünden ISO'yu indir.

Derleme yaklaşık 40-90 dakika sürer (Calamares'in derlenmesi + ISO sıkıştırma).

## Repo yapısı

| Yol | Ne işe yarar |
|---|---|
| `config.env` | Dağıtım adı, ISO adı, etiket |
| `.github/workflows/build-iso.yml` | Elle tetiklenen derleme |
| `scripts/ci-build.sh` | Arch container içindeki ana derleme akışı |
| `scripts/build-aur-repo.sh` | AUR paketlerini derleyip yerel depo yapar |
| `scripts/prepare-profile.sh` | Resmi `releng` profili + bizim `profile/` birleştirilir |
| `aur-packages/list.txt` | AUR'dan derlenecek paketler |
| `profile/packages.add` | ISO'ya eklenen paketler |
| `profile/packages.remove` | `releng`'den çıkarılan paketler |
| `docs/` | GitHub Pages sitesi (`index.html`, `release.json`, `assets/`). Sürüm bilgisi `release.json`'dan okunur |
| `branding/` | Logo ve duvar kağıdı kaynakları (SVG) |
| `profile/airootfs/` | Canlı sistemin köküne olduğu gibi kopyalanan dosyalar |

## Notlar

- Repoda sadece kendi değişikliklerimiz tutulur. `releng` profili derleme sırasında Arch'tan alınır.
- Symlink gerektiren servis etkinleştirmeleri `prepare-profile.sh` içinde yapılır (web arayüzünden symlink yüklenemediği için).
- Canlı oturum KDE Plasma **Wayland** oturumuyla otomatik açılır (Plasma 6.8 ile X11 oturumu kaldırıldı).
- Calamares yapılandırması `profile/airootfs/etc/calamares/` altında (ayarlar, modüller, `branding/taichi`).
- Kurulumda canlı ISO'nun dosya sistemi diske açılır; canlı oturum artıkları `modules/shellprocess_cleanup.conf` ile temizlenir.
- Masaüstündeki "Taichi Linux'u Kur" kısayolu `/usr/local/bin/taichi-installer` betiğini çalıştırır.
- CachyOS: derlemede genel `[cachyos]` deposu kullanılır (CachyOS'un `pacman`'ı, `linux-cachyos`). Kurulumda `taichi-setup-repos` işlemciye göre v3/v4 depolarını ekler.
- Canlı ISO Arch çekirdeğiyle açılır. Kurulu sistemde `linux-cachyos` varsayılan, `linux` yedek çekirdektir.
- `shellprocess_cleanup.conf` içinde dolar işareti kullanma, Calamares onu değişken sanıp kurulumu durdurur.
- Markalama: `taichi-brand` (os-release, her `filesystem` güncellemesinde pacman hook'uyla yeniden yazılır), duvar kağıdı (`/usr/share/wallpapers/Taichi`), SDDM arka planı, ilk girişte duvar kağıdını uygulayan `taichi-first-login`.
- Henüz yapılmadı: GRUB/Plymouth teması, Plasma renk şeması, GitHub Pages sitesi.

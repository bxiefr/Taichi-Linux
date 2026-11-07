#!/bin/bash
# Resmi archiso "releng" profilini kopyalar, bizim profile/ klasörümüzü üstüne bindirir.
# Kullanım: prepare-profile.sh <hedef_dizin> <yerel_depo_dizini> <sürüm>
set -euo pipefail

DEST="$1"
REPO_DIR="$2"
VERSION="$3"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "$ROOT/config.env"

A="$DEST/airootfs"

rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
cp -r /usr/share/archiso/configs/releng "$DEST"

# ---------------------------------------------------------------- 1) airootfs bindirmesi
if [ -d "$ROOT/profile/airootfs" ]; then
  cp -a "$ROOT/profile/airootfs/." "$A/"
fi

# ---------------------------------------------------------------- 2) paket listesi
clean() { grep -v '^[[:space:]]*#' "$1" | sed 's/[[:space:]]*$//' | grep -v '^$' || true; }

PKGS="$DEST/packages.x86_64"
if [ -f "$ROOT/profile/packages.remove" ]; then
  while read -r p; do
    sed -i "\|^${p}\$|d" "$PKGS"
  done < <(clean "$ROOT/profile/packages.remove")
fi
if [ -f "$ROOT/profile/packages.add" ]; then
  clean "$ROOT/profile/packages.add" >> "$PKGS"
fi
awk '!seen[$0]++' "$PKGS" > "$PKGS.tmp" && mv "$PKGS.tmp" "$PKGS"

# ---------------------------------------------------------------- 3) profiledef.sh
# bootmodes'a dokunmuyoruz: releng zaten BIOS (syslinux) + UEFI (systemd-boot) üretir.
LABEL="$(echo "${LABEL_PREFIX}_${VERSION}" | tr -c 'A-Za-z0-9_\n' '_' | tr 'a-z' 'A-Z' | cut -c1-32)"
sed -i \
  -e "s|^iso_name=.*|iso_name=\"${ISO_NAME}\"|" \
  -e "s|^iso_label=.*|iso_label=\"${LABEL}\"|" \
  -e "s|^iso_publisher=.*|iso_publisher=\"${ISO_PUBLISHER}\"|" \
  -e "s|^iso_application=.*|iso_application=\"${ISO_APPLICATION}\"|" \
  -e "s|^iso_version=.*|iso_version=\"${VERSION}\"|" \
  "$DEST/profiledef.sh"

cat >> "$DEST/profiledef.sh" <<'EOF'

# --- Taichi Linux eklemeleri ---
file_permissions+=(
  ["/usr/local/bin/taichi-live-setup"]="0:0:755"
  ["/usr/local/bin/taichi-installer"]="0:0:755"
  ["/etc/skel/Desktop/install-taichi.desktop"]="0:0:755"
)
EOF

# Kurucunun /run/archiso/bootmnt/arch/x86_64/airootfs.sfs yolunu bekler (squashfs + "arch" dizini).
grep -E '^(install_dir|airootfs_image_type)=' "$DEST/profiledef.sh" || true
if ! grep -q '^airootfs_image_type="squashfs"' "$DEST/profiledef.sh"; then
  echo "::warning::airootfs_image_type squashfs degil! Calamares unpackfs.conf yolunu guncelle."
fi

# ---------------------------------------------------------------- 4) açılış menüsü adları
shopt -s nullglob
for f in "$DEST"/syslinux/*.cfg "$DEST"/efiboot/loader/entries/*.conf "$DEST"/grub/*.cfg; do
  sed -i \
    -e "s/Arch Linux install medium/${DISTRO_NAME} Live/g" \
    -e "s/Arch Linux/${DISTRO_NAME}/g" "$f"
done
shopt -u nullglob

# ---------------------------------------------------------------- 5) pacman.conf: yerel depo
cat >> "$DEST/pacman.conf" <<EOF

[taichi-local]
SigLevel = Optional TrustAll
Server = file://${REPO_DIR}
EOF

# ---------------------------------------------------------------- 6) hostname
# NOT: os-release'i buraya KOYMA. Dosya "filesystem" paketine ait; airootfs paketlerden
# önce kopyalandığı için pacman "conflicting files" hatası verir. Markalama aşamasında
# ayrıca çözülecek.
mkdir -p "$A/etc"
echo "${HOSTNAME_LIVE}" > "$A/etc/hostname"

# ---------------------------------------------------------------- 7) servisler (symlink'ler)
# Web arayüzünden symlink yüklenemediği için burada oluşturuyoruz.
SD="$A/etc/systemd/system"
mkdir -p "$SD/multi-user.target.wants" "$SD/bluetooth.target.wants"

# releng'in ağ yığınını kaldır (NetworkManager ile çakışır)
rm -f "$SD/multi-user.target.wants/systemd-networkd.service" \
      "$SD/multi-user.target.wants/iwd.service" \
      "$SD/sockets.target.wants/systemd-networkd.socket" \
      "$SD/network-online.target.wants/systemd-networkd-wait-online.service" \
      "$SD/network-online.target.wants/systemd-networkd-wait-online@.service"

ln -sf /usr/lib/systemd/system/NetworkManager.service \
       "$SD/multi-user.target.wants/NetworkManager.service"
ln -sf /usr/lib/systemd/system/NetworkManager-dispatcher.service \
       "$SD/dbus-org.freedesktop.nm-dispatcher.service"
ln -sf /usr/lib/systemd/system/bluetooth.service \
       "$SD/bluetooth.target.wants/bluetooth.service"
ln -sf /usr/lib/systemd/system/sddm.service \
       "$SD/display-manager.service"
ln -sf /etc/systemd/system/taichi-live-setup.service \
       "$SD/multi-user.target.wants/taichi-live-setup.service"

# ---------------------------------------------------------------- özet
echo "---- profiledef.sh ----"
grep -E '^(iso_|bootmodes|arch=|install_dir)' "$DEST/profiledef.sh" || true
echo "---- paket sayısı: $(wc -l < "$PKGS") ----"

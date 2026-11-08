#!/bin/bash
# AUR paketlerini derleyip yerel bir pacman deposu (taichi-local) oluşturur.
# Kullanım: build-aur-repo.sh <depo_dizini> <liste_dosyası>
# root olarak çalışır; makepkg için geçici "builder" kullanıcısı açar.
set -euo pipefail

REPO_DIR="$1"
LIST="$2"
REPO_NAME="taichi-local"
WORK=/home/builder/aur

id builder >/dev/null 2>&1 || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder
chmod 440 /etc/sudoers.d/builder

mkdir -p "$REPO_DIR"
chown builder:builder "$REPO_DIR"
sudo -u builder mkdir -p "$WORK"

built=0
while read -r line; do
  entry="${line%%#*}"
  entry="$(echo "$entry" | xargs)"
  [ -z "$entry" ] && continue

  # Satır biçimi: "paket" ya da "paket skipchecksums"
  pkg="${entry%% *}"
  flag=""
  [ "$entry" != "$pkg" ] && flag="${entry#* }"

  EXTRA=""
  if [ "$flag" = "skipchecksums" ]; then
    EXTRA="--skipchecksums"
    echo "UYARI: $pkg için kaynak sağlama toplamı doğrulaması atlanıyor."
  fi

  echo "=== AUR: $pkg ==="
  # --skippgpcheck: derleme ortamında yazar anahtarları yok.
  # Kaynak sha256 toplamları PKGBUILD içinde doğrulanır (yalnızca "skipchecksums" işaretliler hariç).
  sudo -u builder bash -c "
    set -euo pipefail
    cd '$WORK'
    rm -rf '$pkg'
    git clone --depth 1 'https://aur.archlinux.org/$pkg.git'
    cd '$pkg'
    MAKEFLAGS=-j\$(nproc) makepkg -s --noconfirm --needed --skippgpcheck $EXTRA
    for f in *.pkg.tar.*; do
      case \"\$f\" in *-debug-*) continue ;; esac
      cp -v \"\$f\" '$REPO_DIR/'
    done
  "

  # Sonraki paketlerin bağımlılığı karşılansın diye bu ortama da kur.
  for f in "$REPO_DIR"/*.pkg.tar.*; do
    pacman -U --noconfirm --needed "$f" || true
  done
  built=$((built + 1))
done < "$LIST"

if [ "$built" -eq 0 ]; then
  echo "HATA: $LIST içinde derlenecek paket yok." >&2
  exit 1
fi

sudo -u builder bash -c "cd '$REPO_DIR' && repo-add '$REPO_NAME.db.tar.gz' *.pkg.tar.*"
echo "Yerel depo hazır:"
ls -lh "$REPO_DIR"

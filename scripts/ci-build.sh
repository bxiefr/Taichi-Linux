#!/bin/bash
# Arch Linux container'ı İÇİNDE çalışır (workflow tarafından çağrılır).
# Sırasıyla: araçları kur -> AUR paketlerini derle -> profili hazırla -> ISO üret.
set -euo pipefail

cd /work
# shellcheck disable=SC1091
source ./config.env

VERSION="${VERSION:-$(date +%Y.%m.%d)}"
REPO_DIR=/work/repo
BUILD_DIR=/work/build
OUT_DIR=/work/out

echo "::group::Araçları kur"
pacman -Syu --noconfirm --needed archiso base-devel git sudo
echo "::endgroup::"

echo "::group::AUR paketlerini derle (yerel depo)"
bash scripts/build-aur-repo.sh "$REPO_DIR" aur-packages/list.txt
echo "::endgroup::"

echo "::group::Profili hazırla"
bash scripts/prepare-profile.sh "$BUILD_DIR/profile" "$REPO_DIR" "$VERSION"
echo "::endgroup::"

echo "::group::mkarchiso"
df -h /work /work/build || true
free -h || true
mkdir -p "$OUT_DIR"
mkarchiso -v -w "$BUILD_DIR/work" -o "$OUT_DIR" "$BUILD_DIR/profile"
echo "::endgroup::"

cd "$OUT_DIR"
for f in *.iso; do
  sha256sum "$f" > "$f.sha256"
done
ls -lh "$OUT_DIR"

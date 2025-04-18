#!/bin/sh

set -ex

sed -i 's/DownloadUser/#DownloadUser/g' /etc/pacman.conf

if [ "$(uname -m)" = 'x86_64' ]; then
	PKG_TYPE='x86_64.pkg.tar.zst'
else
	PKG_TYPE='aarch64.pkg.tar.xz'
fi

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
FFMPEG_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/ffmpeg-mini-$PKG_TYPE"
#QT6_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/qt6-base-iculess-$PKG_TYPE" # Hopefulyl torzu updates to Qt6 someday
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"

pacman -Syu --noconfirm \
  aom \
  boost \
  boost-libs \
  catch2 \
  clang \
  cmake \
  dav1d \
  enet \
  ffmpeg \
  ffmpeg4.4 \
  fmt \
  gamemode \
  gcc13 \
  glslang \
  glu \
  haskell-gnutls \
  hidapi \
  libass \
  libfdk-aac \
  libopusenc \
  libva \
  libvpx \
  libxi \
  libxkbcommon-x11 \
  libxss \
  mbedtls2 \
  meson \
  nasm \
  ninja \
  nlohmann-json \
  numactl \
  qt5-base \
  qt5ct \
  qt5-multimedia \
  qt5-wayland \
  qt5-webengine \
  sdl2 \
  svt-av1 \
  unzip \
  vulkan-headers \
  x264 \
  x265 \
  xcb-util-image \
  xcb-util-renderutil \
  xcb-util-wm \
  xorg-server-xvfb \
  zip \
  zsync

if [ "$(uname -m)" = 'x86_64' ]; then
	pacman -Syu --noconfirm vulkan-intel haskell-gnutls gcc13 svt-av1
else
	pacman -Syu --noconfirm vulkan-freedreno vulkan-panfrost
fi

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$LLVM_URL" -O ./llvm-libs.pkg.tar.zst
#wget --retry-connrefused --tries=30 "$QT6_URL" -O ./qt6-base-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$FFMPEG_URL" -O ./ffmpeg-mini.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL" -O ./opus-nano.pkg.tar.zst

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"

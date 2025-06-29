#!/bin/sh

set -ex

ARCH="$(uname -m)"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"

if [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64-v3 build of torzu"
	ARCH="${ARCH}_v3"
fi
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD TORZU
git clone https://aur.archlinux.org/torzu-git.git torzu && (
	cd ./torzu
	if [ "$1" = 'v3' ]; then
		sed -i 's/-march=[^"]*/-march=x86-64-v3/' ./PKGBUILD
		sed -i 's/-march=x86-64 /-march=x86-64-v3 /' /etc/makepkg.conf # Do I need to do this as well?
		cat /etc/makepkg.conf
	else
		sed -i 's/-march=[^"]*/-march=x86-64/' ./PKGBUILD
	fi

	# Fix weird bug with vulkan
	sed -i 's/-DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=OFF/-DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=ON/' ./PKGBUILD

	# Force translatiosn to be built
	sed -i 's|TRANSLATION=OFF|TRANSLATION=ON|g' ./PKGBUILD

	if ! grep -q -- '-O3' ./PKGBUILD; then
		sed -i 's/-march=/-O3 -march=/' ./PKGBUILD
	fi
	
	cat ./PKGBUILD
	
	makepkg -f
	pacman --noconfirm -U ./*.pkg.tar.*
	ls .
	VERSION="$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)"
	echo "$VERSION" > ~/version
)

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

cp -v /usr/share/applications/*torzu*.desktop
cp -v /usr/share/icons/hicolor/scalable/apps/*torzu*.svg ./
cp -v /usr/share/icons/hicolor/scalable/apps/*torzu*.svg ./.DirIcon

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
chmod +x ./sharun-aio
xvfb-run -a ./sharun-aio l -p -v -e -s -k \
	/usr/bin/yuzu                           \
	/usr/lib/lib*GL*                        \
	/usr/lib/dri/*                          \
	/usr/lib/vdpau/*                        \
	/usr/lib/libvulkan*                     \
	/usr/lib/libXss.so*                     \
	/usr/lib/libxcb-cursor.so*              \
	/usr/lib/libXrandr.so*                  \
	/usr/lib/libXi.so*                      \
	/usr/lib/libdecor-0.so*                 \
	/usr/lib/libgamemode.so*                \
	/usr/lib/qt/plugins/audio/*             \
	/usr/lib/qt/plugins/bearer/*            \
	/usr/lib/qt/plugins/imageformats/*      \
	/usr/lib/qt/plugins/iconengines/*       \
	/usr/lib/qt/plugins/platform*/*         \
	/usr/lib/qt/plugins/styles/*            \
	/usr/lib/qt/plugins/xcbglintegrations/* \
	/usr/lib/qt/plugins/wayland-*/*         \
	/usr/lib/pulseaudio/*                   \
	/usr/lib/pipewire-0.3/*                 \
	/usr/lib/spa-0.2/*/*                    \
	/usr/lib/alsa-lib/*
rm -f ./sharun-aio

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget --retry-connrefused --tries=30 "$URUNTIME"      -O  ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O  ./uruntime-lite
chmod +x ./uruntime*

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime \
	-i ./AppDir                          \
	--appimage-mkdwarfs -f               \
	--set-owner 0 --set-group 0          \
	--no-history --no-create-timestamp   \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite               \
	-o ./Torzu-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake ./*.AppImage -u ./*.AppImage

echo "All Done!"

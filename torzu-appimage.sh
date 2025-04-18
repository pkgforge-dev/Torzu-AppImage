#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
ICON="https://notabug.org/litucks/torzu/raw/02cfee3f184e6fdcc3b483ef399fb5d2bb1e8ec7/dist/yuzu.png"
ICON_BACKUP="https://free-git.org/Emulator-Archive/torzu/raw/branch/master/dist/yuzu.png"

if [ "$1" = 'v3' ]; then
	echo "Making x86-64-v3 build of torzu"
	ARCH="${ARCH}_v3"
fi
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD TORZU
if [ ! -d ./torzu ]; then
	git clone https://aur.archlinux.org/torzu-git.git torzu
fi
cd ./torzu

if [ "$1" = 'v3' ]; then
	sed -i 's/-march=[^"]*/-march=x86-64-v3/' ./PKGBUILD
	sudo sed -i 's/-march=x86-64 /-march=x86-64-v3 /' /etc/makepkg.conf # Do I need to do this as well?
	cat /etc/makepkg.conf
else
	sed -i 's/-march=[^"]*/-march=x86-64/' ./PKGBUILD
fi
sed -i 's/-DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=OFF/-DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=ON/' ./PKGBUILD
if ! grep -q -- '-O3' ./PKGBUILD; then
	sed -i 's/-march=/-O3 -march=/' ./PKGBUILD
fi
cat ./PKGBUILD

makepkg -f
sudo pacman --noconfirm -U *.pkg.tar.*
ls .
export VERSION="$(awk -F'=' '/pkgver=/{print $2; exit}' ./PKGBUILD)"
echo "$VERSION" > ~/version
cd ..

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

echo '[Desktop Entry]
Version=1.0
Type=Application
Name=torzu
GenericName=Switch Emulator
Comment=Nintendo Switch video game console emulator
Icon=torzu
TryExec=yuzu
Exec=yuzu %f
Categories=Game;Emulator;Qt;
MimeType=application/x-nx-nro;application/x-nx-nso;application/x-nx-nsp;application/x-nx-xci;
Keywords=Nintendo;Switch;
StartupWMClass=yuzu' > ./torzu.desktop

if ! wget --retry-connrefused --tries=30 "$ICON" -O torzu.png; then
	if ! wget --retry-connrefused --tries=30 "$ICON_BACKUP" -O torzu.png; then
		echo "kek"
		touch ./torzu.png
	fi
fi
ln -s ./torzu.png ./.DirIcon

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/yuzu* \
	/usr/lib/libGLX* \
	/usr/lib/libGL.so* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/vdpau/* \
	/usr/lib/libvulkan* \
	/usr/lib/libXss.so* \
	/usr/lib/libxcb-cursor.so* \
	/usr/lib/libXrandr.so* \
	/usr/lib/libXi.so* \
	/usr/lib/libdecor-0.so* \
	/usr/lib/libgamemode.so* \
	/usr/lib/qt/plugins/audio/* \
	/usr/lib/qt/plugins/bearer/* \
	/usr/lib/qt/plugins/imageformats/* \
	/usr/lib/qt/plugins/iconengines/* \
	/usr/lib/qt/plugins/platforms/* \
	/usr/lib/qt/plugins/platformthemes/* \
	/usr/lib/qt/plugins/platforminputcontexts/* \
	/usr/lib/qt/plugins/styles/* \
	/usr/lib/qt/plugins/xcbglintegrations/* \
	/usr/lib/qt/plugins/wayland-*/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/pipewire-0.3/* \
	/usr/lib/spa-0.2/*/* \
	/usr/lib/alsa-lib/*

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime \
	-i ./AppDir -o Torzu-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"

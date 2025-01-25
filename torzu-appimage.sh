#!/bin/sh

set -e

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME=$(wget -q https://api.github.com/repos/VHSgunzo/uruntime/releases -O - \
	| sed 's/[()",{} ]/\n/g' | grep -oi "https.*appimage.*dwarfs.*$ARCH$" | head -1)
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
	sed 's/-march=[^"]*/-march=x86-64-v3/' ./PKGBUILD
else
	sed 's/-march=[^"]*/-march=x86-64/' ./PKGBUILD
fi
cat ./PKGBUILD

makepkg
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
StartupWMClass=torzu' > ./torzu.desktop

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
xvfb-run -a -- ./lib4bin -p -v -r -e -s -k \
	/usr/bin/yuzu* \
	/usr/lib/libGLX* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/libvulkan* \
	/usr/lib/qt5/plugins/audio/* \
	/usr/lib/qt5/plugins/bearer/* \
	/usr/lib/qt5/plugins/imageformats/* \
	/usr/lib/qt5/plugins/iconengines/* \
	/usr/lib/qt5/plugins/platforms/* \
	/usr/lib/qt5/plugins/platformthemes/* \
	/usr/lib/qt5/plugins/platforminputcontexts/* \
	/usr/lib/qt5/plugins/styles/* \
	/usr/lib/qt5/plugins/xcbglintegrations/* \
	/usr/lib/qt5/plugins/wayland-*/* \
	/usr/lib/pulseaudio/* \
	/usr/lib/alsa-lib/*


#########################################################################
# For some wierd reason the yuzu binary is ignoring the --library-path given to the interpreter by sharun
# IT SOMEHOW EVEN USES THE HOST INTERPRETER!

# This is crazy that this is needed
patchelf --set-interpreter './lib/ld-linux-x86-64.so.2' ./shared/bin/*
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}' > ./.env
echo 'LD_LIBRARY_PATH=${SHARUN_DIR}/lib:${SHARUN_DIR}/lib/pulseaudio:${SHARUN_DIR}/lib/libproxy:${SHARUN_DIR}/lib/alsa-lib:${SHARUN_DIR}/lib/dri' >> ./.env

#########################################################################

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# turn appdir into appimage
cd ..
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
printf "$UPINFO" > data.upd_info
llvm-objcopy --update-section=.upd_info=data.upd_info \
	--set-section-flags=.upd_info=noload,readonly ./uruntime
printf 'AI\x02' | dd of=./uruntime bs=1 count=3 seek=8 conv=notrunc

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S24 -B16 \
	--header uruntime \
	-i ./AppDir -o Torzu-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage
echo "All Done!"

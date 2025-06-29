#!/bin/sh

set -ex

ARCH="$(uname -m)"
SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-$ARCH-aio"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"

if [ "$1" = 'v3' ] && [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64-v3 optimized build of torzu..."
	ARCH="${ARCH}_v3"
	ARCH_FLAGS="-march=x86-64-v3 -O3 -flto=auto -DNDEBUG"
elif [ "$ARCH" = 'x86_64' ]; then
	echo "Making x86-64 generic build of torzu..."
	ARCH_FLAGS="-march=x86-64 -mtune=generic -O3 -flto=auto -DNDEBUG"
else
	echo "Making aarch64 build of torzu..."
	ARCH_FLAGS="-march=armv8-a -mtune=generic -O3 -flto=auto -DNDEBUG"
fi

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD TORZU
git clone --recursive --depth 1 https://notabug.org/litucks/torzu.git ./torzu && (
	cd ./torzu
	mkdir build
	cd build
	cmake .. -GNinja \
		-DYUZU_USE_BUNDLED_VCPKG=OFF               \
		-DENABLE_QT6=ON                            \
		-DENABLE_QT_TRANSLATION=ON                 \
		-DYUZU_USE_BUNDLED_QT=OFF                  \
		-DYUZU_USE_BUNDLED_FFMPEG=OFF              \
		-DYUZU_TESTS=OFF                           \
		-DYUZU_CMD=OFF                             \
		-DYUZU_CHECK_SUBMODULES=OFF                \
		-DYUZU_USE_LLVM_DEMANGLE=OFF               \
		-DYUZU_USE_BUNDLED_SDL2=ON                 \
		-DYUZU_USE_EXTERNAL_SDL2=OFF               \
		-DYUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS=ON  \
		-DYUZU_ENABLE_LTO=ON                       \
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5         \
		-DCMAKE_INSTALL_PREFIX=/usr                \
		-DCMAKE_CXX_FLAGS="$ARCH_FLAGS -Wno-error" \
		-DCMAKE_C_FLAGS="$ARCH_FLAGS"              \
		-DCMAKE_SYSTEM_PROCESSOR="$(uname -m)"     \
		-DCMAKE_BUILD_TYPE=Release
	ninja
	sudo ninja install
	VERSION="$(git rev-parse --short HEAD)"
	echo "$VERSION" > ~/version
)
VERSION="$(cat ~/version)"

# NOW MAKE APPIMAGE
mkdir ./AppDir
cd ./AppDir

cp -v /usr/share/applications/*torzu*.desktop            ./
cp -v /usr/share/icons/hicolor/scalable/apps/*torzu*.svg ./
cp -v /usr/share/icons/hicolor/scalable/apps/*torzu*.svg ./.DirIcon

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
chmod +x ./sharun-aio
xvfb-run -a ./sharun-aio l -p -v -e -s -k \
	/usr/bin/yuzu                            \
	/usr/lib/lib*GL*                         \
	/usr/lib/dri/*                           \
	/usr/lib/vdpau/*                         \
	/usr/lib/libvulkan*                      \
	/usr/lib/libXss.so*                      \
	/usr/lib/libxcb-cursor.so*               \
	/usr/lib/libXrandr.so*                   \
	/usr/lib/libXi.so*                       \
	/usr/lib/libdecor-0.so*                  \
	/usr/lib/libgamemode.so*                 \
	/usr/lib/qt6/plugins/audio/*             \
	/usr/lib/qt6/plugins/bearer/*            \
	/usr/lib/qt6/plugins/imageformats/*      \
	/usr/lib/qt6/plugins/iconengines/*       \
	/usr/lib/qt6/plugins/platform*/*         \
	/usr/lib/qt6/plugins/styles/*            \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/*         \
	/usr/lib/pulseaudio/*                    \
	/usr/lib/pipewire-0.3/*                  \
	/usr/lib/spa-0.2/*/*                     \
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
	--appimage-mkdwarfs -f               \
	--set-owner 0 --set-group 0          \
	--no-history --no-create-timestamp   \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite               \
	-i ./AppDir                          \
	-o ./Torzu-"$VERSION"-anylinux-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake ./*.AppImage -u ./*.AppImage

echo "All Done!"

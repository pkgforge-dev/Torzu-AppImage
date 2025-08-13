#!/bin/sh

set -ex

ARCH="$(uname -m)"

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
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"

export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export OUTNAME=Torzu-"$VERSION"-anylinux-"$ARCH".AppImage
export DESKTOP=/usr/share/applications/onion.torzu_emu.torzu.desktop
export ICON=/usr/share/icons/hicolor/scalable/apps/onion.torzu_emu.torzu.svg
export DEPLOY_OPENGL=1 
export DEPLOY_VULKAN=1 
export DEPLOY_PIPEWIRE=1

# ADD LIBRARIES
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/yuzu* /usr/lib/libgamemode.so*

# allow using host vk for aarch64 given the sad situation
if [ "$ARCH" = 'aarch64' ]; then 
	echo 'SHARUN_ALLOW_SYS_VKICD=1' >> ./AppDir/.env
fi

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

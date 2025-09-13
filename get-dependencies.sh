#!/bin/sh

set -eux
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

pacman -Syu --noconfirm \
	aom                 \
	base-devel          \
	boost               \
	boost-libs          \
	catch2              \
	clang               \
	cmake               \
	curl                \
	enet                \
	fmt                 \
	gamemode            \
	git                 \
	gcc                 \
	glslang             \
	glu                 \
	hidapi              \
	libass              \
	libxi               \
	libxkbcommon-x11    \
	libxss              \
	mbedtls2            \
	meson               \
	nasm                \
	ninja               \
	nlohmann-json       \
	numactl             \
	pipewire-audio      \
	pulseaudio          \
	pulseaudio-alsa     \
	qt6-base            \
	qt6ct               \
	qt6-multimedia      \
	qt6-tools           \
	qt6-wayland         \
	sdl2                \
	unzip               \
	vulkan-headers      \
	wget                \
	xcb-util-image      \
	xcb-util-renderutil \
	xcb-util-wm         \
	xorg-server-xvfb    \
	zip                 \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa qt6-base-mini llvm-libs-nano opus-mini libxml2-mini

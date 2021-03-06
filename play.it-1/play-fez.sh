#!/bin/sh
set -e

###
# Copyright (c) 2015-2017, Antoine Le Gonidec
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# This software is provided by the copyright holders and contributors "as is"
# and any express or implied warranties, including, but not limited to, the
# implied warranties of merchantability and fitness for a particular purpose
# are disclaimed. In no event shall the copyright holder or contributors be
# liable for any direct, indirect, incidental, special, exemplary, or
# consequential damages (including, but not limited to, procurement of
# substitute goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether in
# contract, strict liability, or tort (including negligence or otherwise)
# arising in any way out of the use of this software, even if advised of the
# possibility of such damage.
###

###
# conversion script for the Fez installer sold on HumbleBundle.com
# build a .deb package from the .sh MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170219.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'
SCRIPT_DEPS_SOFT='convert'

GAME_ID='fez'
GAME_NAME='Fez'

ARCHIVE_HUMBLE='fez-11282016-bin'
ARCHIVE_HUMBLE_MD5='333d2e5f55adbd251b09e01d4da213c6'
ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE='440000'
ARCHIVE_HUMBLE_VERSION='1.12-humble161128'
ARCHIVE_HUMBLE_TYPE='mojo'

INSTALLER_PATH='data/'
INSTALLER_DOC='./Linux.README'
INSTALLER_GAME_PKG1='./FEZ.bin.x86 ./lib'
INSTALLER_GAME_PKG2='./FEZ.bin.x86_64 ./lib64'
INSTALLER_GAME_PKG3='./*'

APP1_ID="${GAME_ID}"
APP1_EXE_PKG1='./FEZ.bin.x86'
APP1_EXE_PKG2='./FEZ.bin.x86_64'
APP1_ICON='./FEZ.bmp'
APP1_ICON_RES='256x256'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_ID="${GAME_ID}"
PKG_DEPS='libc6, libstdc++6, libopenal1, libsdl2-2.0-0'
PKG_DESC="${GAME_NAME}
 package built from HumbleBundle.com installer
 ./play.it script version ${script_version}"

PKG1_ID="${PKG_ID}"
PKG1_ARCH='i386'
PKG1_DEPS="${PKG_DEPS}"
PKG1_DESC="${PKG_DESC}"

PKG2_ID="${PKG_ID}"
PKG2_ARCH='amd64'
PKG2_DEPS="${PKG_DEPS}"
PKG2_DESC="${PKG_DESC}"

PKG3_ID="${GAME_ID}-common"
PKG3_ARCH='all'
PKG3_DEPS=''
PKG3_DESC="${GAME_NAME} - arch-independant data
 package built from HumbleBundle.com installer
 ./play.it script version ${script_version}"

PKG1_DEPS="$PKG3_ID, $PKG1_DEPS"
PKG2_DEPS="$PKG3_ID, $PKG2_DEPS"

# Load common functions

TARGET_LIB_VERSION='1.14'

if [ -z "${PLAYIT_LIB}" ]; then
	PLAYIT_LIB='./play-anything.sh'
fi

if ! [ -e "${PLAYIT_LIB}" ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'play-anything.sh not found.\n'
	printf 'It must be placed in the same directory than this script.\n\n'
	exit 1
fi

LIB_VERSION="$(grep '^# library version' "${PLAYIT_LIB}" | cut -d' ' -f4 | cut -d'.' -f1,2)"

if [ ${LIB_VERSION%.*} -ne ${TARGET_LIB_VERSION%.*} ] || [ ${LIB_VERSION#*.} -lt ${TARGET_LIB_VERSION#*.} ]; then
	printf '\n\033[1;31mError:\033[0m\n'
	printf 'Wrong version of play-anything.\n'
	printf 'It must be at least %s ' "${TARGET_LIB_VERSION}"
	printf 'but lower than %s.\n\n' "$((${TARGET_LIB_VERSION%.*}+1)).0"
	exit 1
fi

. "${PLAYIT_LIB}"

# Set extra variables

NO_ICON=0

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}
check_deps_soft ${SCRIPT_DEPS_SOFT}

printf '\n'
GAME_ARCHIVE1="$ARCHIVE_HUMBLE"
set_target '1' 'humblebundle.com'
ARCHIVE_MD5="$ARCHIVE_HUMBLE_MD5"
ARCHIVE_TYPE="$ARCHIVE_HUMBLE_TYPE"
ARCHIVE_UNCOMPRESSED_SIZE="$ARCHIVE_HUMBLE_UNCOMPRESSED_SIZE"
PKG_VERSION="$ARCHIVE_HUMBLE_VERSION"
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID}.XXXXX)"          "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG1_DIR'   "${PKG1_ID}_${PKG_VERSION}_${PKG1_ARCH}" "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG2_DIR'   "${PKG2_ID}_${PKG_VERSION}_${PKG2_ARCH}" "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"
game_mkdir 'PKG3_DIR'   "${PKG3_ID}_${PKG_VERSION}_${PKG3_ARCH}" "$(( $ARCHIVE_UNCOMPRESSED_SIZE * 2 ))"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "$GAME_ARCHIVE" 'defaults' "$ARCHIVE_MD5"
fi

# Extract game data

PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"
build_pkg_dirs '2' "${PATH_BIN}" "${PATH_DESK}" "${PATH_GAME}"
rm -rf "${PKG3_DIR}"
mkdir -p "${PKG3_DIR}/DEBIAN" "${PKG3_DIR}${PATH_DOC}" "${PKG3_DIR}${PATH_GAME}" "${PKG3_DIR}${PATH_ICON}"
print wait

extract_data "$ARCHIVE_TYPE" "$GAME_ARCHIVE" "$PKG_TMPDIR" 'fix_rights,quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG3_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mv "${file}" "${PKG2_DIR}${PATH_GAME}"
done

for file in ${INSTALLER_GAME_PKG3}; do
	mv "${file}" "${PKG3_DIR}${PATH_GAME}"
done
cd - > /dev/null

chmod 755 "${PKG1_DIR}${PATH_GAME}/${APP1_EXE_PKG1}"
chmod 755 "${PKG2_DIR}${PATH_GAME}/${APP1_EXE_PKG2}"

if [ "${NO_ICON}" = '0' ]; then
	PKG1_REAL="${PKG1_DIR}"
	PKG1_DIR="${PKG3_DIR}"
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}" 2>/dev/null
	PKG1_DIR="${PKG1_REAL}"
	mv "${PKG_TMPDIR}/${APP1_ID}.png" "${PKG3_DIR}${PATH_ICON}"
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_PKG1}" '' 'lib' '' "${APP1_NAME} (${PKG1_ARCH})"
write_bin_native "${PKG2_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_PKG2}" '' 'lib64' '' "${APP1_NAME} (${PKG2_ARCH})"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}"
cp -l "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${PKG2_DIR}${PATH_DESK}/${APP1_ID}.desktop"
printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "$PKG1_DIR" "$PKG1_ID" "$PKG_VERSION" "$PKG1_ARCH" '' "$PKG1_DEPS" '' "$PKG1_DESC" 'arch'
write_pkg_debian "$PKG2_DIR" "$PKG2_ID" "$PKG_VERSION" "$PKG2_ARCH" '' "$PKG2_DEPS" '' "$PKG2_DESC" 'arch'
write_pkg_debian "$PKG3_DIR" "$PKG3_ID" "$PKG_VERSION" "$PKG3_ARCH" '' "$PKG3_DEPS" '' "$PKG3_DESC"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG1_ARCH}"
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG2_ARCH}"
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "$(printf '%s' "${PKG1_DESC}" | head -n1) (${PKG1_ARCH})" "${PKG3_DIR}" "${PKG1_DIR}"
printf '\n'
print_instructions "$(printf '%s' "${PKG2_DESC}" | head -n1) (${PKG2_ARCH})" "${PKG3_DIR}" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0

#!/bin/sh -e

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
# conversion script for the Fallout Tactics installer sold on GOG.com
# build a .deb package from the Windows installer
# tested on Debian, should work on any .deb-based distribution
#
# send your bug reports to vv221@dotslashplay.it
# start the e-mail subject by "./play.it" to avoid it being flagged as spam
###

script_version=20160309.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='fallout-tactics'
GAME_ID_SHORT='bos'
GAME_NAME='Fallout Tactics'
GAME_NAME_SHORT='BoS'

GAME_ARCHIVE1='setup_fallout_tactics_2.1.0.12.exe'
GAME_ARCHIVE1_MD5='9cc1d9987d8a2fa6c1cc6cf9837758ad'
GAME_ARCHIVE2='setup_fallout_tactics_french_2.1.0.12.exe'
GAME_ARCHIVE2_MD5='520c29934290910cdeecbc7fcca68f2b'
GAME_ARCHIVE_FULLSIZE='1900000'
PKG_REVISION='gog2.1.0.12'

INSTALLER_JUNK='app/goggame* app/webcache.zip app/__support'
INSTALLER_DOC='app/*.pdf app/*.rtf app/*.txt tmp/gog_eula.txt'
INSTALLER_GAME='app/*'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS=''
GAME_CONFIG_FILES='./*.cfg ./core/*.cfg'
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./core/user'
GAME_DATA_FILES='./bos.exe ./ft?tools.exe'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

MENU1_ID="${GAME_ID}_games"
MENU1_NAME="${GAME_NAME}"
MENU1_NAME_FR="${GAME_NAME}"
MENU1_CAT='Games'

MENU2_ID="${GAME_ID}_settings"
MENU2_NAME="${GAME_NAME}"
MENU2_NAME_FR="${GAME_NAME}"
MENU2_CAT='Settings'

APP1_ID="${GAME_ID}"
APP1_EXE='./bos.exe'
APP1_ICON='./fallouttactics.ico'
APP1_ICON_RES='16x16 32x32'
APP1_NAME="${GAME_NAME_SHORT} - ${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME_SHORT} - ${GAME_NAME}"

APP2_ID="${GAME_ID}_tools"
APP2_EXE='./ft tools.exe'
APP2_NAME="${GAME_NAME_SHORT} - Toolbox"
APP2_NAME_FR="${GAME_NAME_SHORT} - Boîte à outils"

APP3_ID="${GAME_ID}_hd-patch"
APP3_EXE='./fot_hires_patch.exe'
APP3_NAME="${GAME_NAME_SHORT} - HD patch"
APP3_NAME_FR="${GAME_NAME_SHORT} - patch HD"

APP4_ID="${GAME_ID}_tools-hd-patch"
APP4_EXE='./fttools_hires_patch.exe'
APP4_NAME="${APP2_NAME} - HD patch"
APP4_NAME_FR="${APP2_NAME_FR} - patch HD"

PKG1_ID="${GAME_ID}"
PKG1_VERSION='1.27'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

# Load common functions

TARGET_LIB_VERSION='1.13'

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

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

printf '\n'

set_target '2' 'gog.com'

printf '\n'

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}" "${GAME_ARCHIVE2_MD5}"
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_GAME}"

print wait

extract_data 'inno' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'

for file in ${INSTALLER_JUNK}; do
	rm -rf "${PKG_TMPDIR}"/${file}
done

for file in ${INSTALLER_DOC}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${PKG_TMPDIR}"/${file} "${PKG1_DIR}${PATH_GAME}"
done

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
fi

rm -rf "${PKG_TMPDIR}"

print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP3_ID}" "${APP3_EXE}" '' '' "${APP3_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP4_ID}" "${APP4_EXE}" '' '' "${APP4_NAME}"

write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" '' 'wine'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" '' 'wine'
write_desktop "${APP3_ID}" "${APP3_NAME}" "${APP3_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP3_ID}.desktop" '' 'wine'
write_desktop "${APP4_ID}" "${APP4_NAME}" "${APP4_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP4_ID}.desktop" '' 'wine'
write_menu "${MENU1_ID}" "${MENU1_NAME}" "${MENU1_NAME_FR}" "${MENU1_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${MENU1_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${MENU1_ID}.menu" 'wine' "${APP1_ID}" "${APP2_ID}"
write_menu "${MENU2_ID}" "${MENU2_NAME}" "${MENU2_NAME_FR}" "${MENU2_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${MENU2_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${MENU2_ID}.menu" 'wine' "${APP3_ID}" "${APP4_ID}"

printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"

if [ "${NO_ICON}" = '0' ]; then
	file="${PKG1_DIR}/DEBIAN/postinst"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
	for id in "${APP2_ID}" "${APP3_ID}" "${APP4_ID}" "${MENU1_ID}" "${MENU2_ID}"; do
	  for res in ${APP1_ICON_RES}; do
	    path_icon="${PATH_ICON_BASE}/\${res}/apps"
	    ln -s "${APP1_ID}.png" "\${path_icon}/\${id}.png"
	  done
	done
	exit 0
	EOF
	chmod 755 "${file}"

	file="${PKG1_DIR}/DEBIAN/prerm"
	cat > "${file}" <<- EOF
	#!/bin/sh -e
	for id in "${APP2_ID}" "${APP3_ID}" "${APP4_ID}" "${MENU1_ID}" "${MENU2_ID}"; do
	  for res in ${APP1_ICON_RES}; do
	    path_icon="${PATH_ICON_BASE}/\${res}/apps"
	    rm "\${path_icon}/\${id}.png"
	  done
	done
	exit 0
	EOF
	chmod 755 "${file}"
fi

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}"

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"

printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0

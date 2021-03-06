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
# conversion script for the Heroes of Might and Magic 3 Complete installer sold on GOG.com
# build a .deb package from the Windows installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20160914.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath innoextract'
SCRIPT_DEPS_SOFT='icotool wrestool'

GAME_ID='heroes-of-might-and-magic-3'
GAME_ID_SHORT='homm3'
GAME_NAME='Heroes of Might and Magic III'
GAME_NAME_SHORT='HoMM3'

GAME_ARCHIVE1='setup_homm3_complete_french_2.1.0.20.exe'
GAME_ARCHIVE1_MD5='ca8e4726acd7b5bc13c782d59c5a459b'
GAME_ARCHIVE1_REVISION='gog2.1.0.20'
GAME_ARCHIVE2='setup_homm3_complete_2.0.0.16.exe'
GAME_ARCHIVE2_MD5='263d58f8cc026dd861e9bbcadecba318'
GAME_ARCHIVE2_PATCH='patch_heroes_of_might_and_magic_3_complete_2.0.1.17.exe'
GAME_ARCHIVE2_PATCH_MD5='815b9c097cd57d0e269beb4cc718dad3'
GAME_ARCHIVE2_REVISION='gog2.0.1.17'
GAME_ARCHIVE_FULLSIZE='1100000'
ARCHIVE_TYPE='inno'

INSTALLER_PATH='app'
INSTALLER_JUNK='./gameuxinstallhelper.dll ./gfw_high.ico ./goggame* ./*.sdb ./gog.ico ./support.ico ./webcache.zip ./random_maps ./config ./games'
INSTALLER_DOC='./eula ./*.cnt ./*.hlp ./*.pdf ./*.txt ../tmp/*eula.txt'
INSTALLER_GAME='./*'
INSTALLER_GAME_ARCHIVE2='../tmp/heroes3.exe'

GAME_CACHE_DIRS=''
GAME_CACHE_FILES=''
GAME_CACHE_FILES_POST=''
GAME_CONFIG_DIRS='./config'
GAME_CONFIG_FILES=''
GAME_CONFIG_FILES_POST=''
GAME_DATA_DIRS='./games ./maps ./random_maps'
GAME_DATA_FILES='data/*.lod games/savegames.txt'
GAME_DATA_FILES_POST=''

APP_COMMON_ID="${GAME_ID_SHORT}-common.sh"

MENU_NAME="${GAME_NAME}"
MENU_NAME_FR="${GAME_NAME}"
MENU_CAT='Games'

APP1_ID="${GAME_ID}"
APP1_EXE='./heroes3.exe'
APP1_ICON='./heroes3.exe'
APP1_ICON_RES='16x16 32x32 48x48 64x64'
APP1_NAME="${GAME_NAME_SHORT} - The Shadow of Death"
APP1_NAME_FR="${APP1_NAME}"

APP2_ID="${GAME_ID}_edit-map"
APP2_EXE='./h3maped.exe'
APP2_ICON='./h3maped.exe'
APP2_ICON_RES='16x16 32x32 48x48 64x64'
APP2_NAME="${GAME_NAME_SHORT} - map editor"
APP2_NAME_FR="${GAME_NAME_SHORT} - éditeur de cartes"

APP3_ID="${GAME_ID}_edit-cmp"
APP3_EXE='./h3ccmped.exe'
APP3_ICON='./h3ccmped.exe'
APP3_ICON_RES='16x16 32x32 48x48 64x64'
APP3_NAME="${GAME_NAME_SHORT} - campaign editor"
APP3_NAME_FR="${GAME_NAME_SHORT} - éditeur de campagnes"

APP4_ID="${GAME_ID}_blade"
APP4_EXE='./h3blade.exe'
APP4_ICON='./h3blade.exe'
APP4_ICON_RES='16x16 32x32 48x48 64x64'
APP4_NAME="${GAME_NAME_SHORT} - Armageddon’s Blade"
APP4_NAME_FR="${APP4_NAME}"

PKG1_ID="${GAME_ID}"
PKG1_VERSION='3.0'
PKG1_ARCH='i386'
PKG1_CONFLICTS=''
PKG1_DEPS='wine:amd64 | wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386 | wine-staging-i386'
PKG1_RECS=''
PKG1_DESC="${GAME_NAME}
 package built from GOG.com Windows installer
 ./play.it script version ${script_version}"

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
set_target '2' 'gog.com'
case "$(basename ${GAME_ARCHIVE})" in
	"${GAME_ARCHIVE1}")
		PKG_REVISION="${GAME_ARCHIVE1_REVISION}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE1_MD5}"
	;;
	"${GAME_ARCHIVE2}")
		PKG_REVISION="${GAME_ARCHIVE2_REVISION}"
		GAME_ARCHIVE_MD5="${GAME_ARCHIVE2_MD5}"
		INSTALLER_GAME="${INSTALLER_GAME} ${INSTALLER_GAME_ARCHIVE2}"
		set_target_extra 'GAME_ARCHIVE_PATCH' '' "${GAME_ARCHIVE2_PATCH}"
	;;
esac
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DESK_DIR='/usr/local/share/desktop-directories'
PATH_DESK_MERGED='/etc/xdg/menus/applications-merged'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

# Check target file integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	printf '%s…\n' "$(l10n 'checksum_multiple')"
	print wait
	checksum "${GAME_ARCHIVE}" 'quiet' "${GAME_ARCHIVE_MD5}"
	if [ -n "${GAME_ARCHIVE_PATCH}" ]; then
		checksum "${GAME_ARCHIVE_PATCH}" 'quiet' "${GAME_ARCHIVE2_PATCH_MD5}"
	fi
	print done
fi

# Extract game data

build_pkg_dirs '1' "${PATH_BIN}" "${PATH_DOC}" "${PATH_DESK}" "${PATH_DESK_DIR}" "${PATH_DESK_MERGED}" "${PATH_GAME}"
print wait

extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'quiet'
if [ -n "${GAME_ARCHIVE_PATCH}" ]; then
	extract_data "${ARCHIVE_TYPE}" "${GAME_ARCHIVE_PATCH}" "${PKG_TMPDIR}" 'quiet'
fi

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"
for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG1_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME}; do
	mv "${file}" "${PKG1_DIR}${PATH_GAME}"
done
cd - > /dev/null

if [ "${NO_ICON}" = '0' ]; then
	extract_icons "${APP1_ID}" "${APP1_ICON}" "${APP1_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP2_ID}" "${APP2_ICON}" "${APP2_ICON_RES}" "${PKG_TMPDIR}"
	extract_icons "${APP3_ID}" "${APP3_ICON}" "${APP3_ICON_RES}" "${PKG_TMPDIR}"
	if [ "$(basename ${GAME_ARCHIVE})" = "${GAME_ARCHIVE1}" ]; then
		extract_icons "${APP4_ID}" "${APP4_ICON}" "${APP4_ICON_RES}" "${PKG_TMPDIR}"
	fi
fi

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_wine_common "${PKG1_DIR}${PATH_BIN}/${APP_COMMON_ID}"
write_bin_wine_cfg "${PKG1_DIR}${PATH_BIN}/${GAME_ID_SHORT}-winecfg"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE}" '' '' "${APP1_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP2_ID}" "${APP2_EXE}" '' '' "${APP2_NAME}"
write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP3_ID}" "${APP3_EXE}" '' '' "${APP3_NAME}"
if [ "$(basename ${GAME_ARCHIVE})" = "${GAME_ARCHIVE1}" ]; then
	write_bin_wine "${PKG1_DIR}${PATH_BIN}/${APP4_ID}" "${APP4_EXE}" '' '' "${APP4_NAME}"
fi

if [ "$(basename ${GAME_ARCHIVE})" = "${GAME_ARCHIVE1}" ]; then
	write_menu "${GAME_ID}" "${MENU_NAME}" "${MENU_NAME_FR}" "${MENU_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" 'wine' "${APP1_ID}" "${APP2_ID}" "${APP3_ID}" "${APP4_ID}"
else
	write_menu "${GAME_ID}" "${MENU_NAME}" "${MENU_NAME_FR}" "${MENU_CAT}" "${PKG1_DIR}${PATH_DESK_DIR}/${GAME_ID}.directory" "${PKG1_DIR}${PATH_DESK_MERGED}/${GAME_ID}.menu" 'wine' "${APP1_ID}" "${APP2_ID}" "${APP3_ID}"
fi
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" '' 'wine'
write_desktop "${APP2_ID}" "${APP2_NAME}" "${APP2_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP2_ID}.desktop" '' 'wine'
write_desktop "${APP3_ID}" "${APP3_NAME}" "${APP3_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP3_ID}.desktop" '' 'wine'
if [ "$(basename ${GAME_ARCHIVE})" = "${GAME_ARCHIVE1}" ]; then
	write_desktop "${APP4_ID}" "${APP4_NAME}" "${APP4_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP4_ID}.desktop" '' 'wine'
fi
printf '\n'

# Build package

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}"
build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'defaults'

print_instructions "${PKG1_DESC}" "${PKG1_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0

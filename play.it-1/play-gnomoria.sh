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
# conversion script for the Gnomoria installer sold on GOG.com
# build a .deb package from the MojoSetup installer
#
# send your bug reports to vv221@dotslashplay.it
###

script_version=20161023.1

# Set game-specific variables

SCRIPT_DEPS_HARD='fakeroot realpath unzip'

GAME_ID='gnomoria'
GAME_ID_SHORT='gnomoria'
GAME_NAME='Gnomoria'

GAME_ARCHIVE1='gog_gnomoria_2.0.0.1.sh'
GAME_ARCHIVE1_MD5='3d0a9ed4fb45ff133b5a7410a2114455'
GAME_ARCHIVE_FULLSIZE='230000'
PKG_REVISION='gog2.0.0.1'

INSTALLER_PATH='data/noarch/game'
INSTALLER_JUNK='lib*/7za lib*/libjpeg.so.62 lib*/libogg.so.0 lib*/libopenal.so.1 lib*/libSDL2-2.0.so.0, lib*/libSDL2_image-2.0.so.0, lib*/libtheoradec.so.1 lib*/libvorbisfile.so.3 lib*/libvorbis.so.0'
INSTALLER_DOC='../docs/*'
INSTALLER_GAME_PKG1='./Gnomoria.bin.x86 ./lib'
INSTALLER_GAME_PKG2='./Gnomoria.bin.x86_64 ./lib64'
INSTALLER_GAME_PKG3='./*'

APP1_ID="${GAME_ID}"
APP1_EXE_PKG1='./Gnomoria.bin.x86'
APP1_EXE_PKG2='./Gnomoria.bin.x86_64'
APP1_ICON='Gnomoria.png'
APP1_ICON_RES='256x256'
APP1_NAME="${GAME_NAME}"
APP1_NAME_FR="${GAME_NAME}"
APP1_CAT='Game'

PKG_ID="${GAME_ID}"
PKG_VERSION='1.0'
PKG_DEPS='libc6, libstdc++6, p7zip-full, libjpeg62-turbo | libjpeg62, libopenal1, libsdl2-2.0-0, libsdl2-image-2.0-0, libtheora0, libvorbisfile3'
PKG_DESC="${GAME_NAME}
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_ID="${PKG_ID}"
PKG1_ARCH='i386'
PKG1_VERSION="${PKG_VERSION}"
PKG1_DEPS="${PKG_DEPS}"
PKG1_RECS=''
PKG1_DESC="${PKG_DESC}"

PKG2_ID="${PKG_ID}"
PKG2_ARCH='amd64'
PKG2_VERSION="${PKG_VERSION}"
PKG2_DEPS="${PKG_DEPS}"
PKG2_RECS=''
PKG2_DESC="${PKG_DESC}"

PKG3_ID="${GAME_ID}-common"
PKG3_ARCH='all'
PKG3_VERSION="${PKG_VERSION}"
PKG3_CONFLICTS=''
PKG3_DEPS=''
PKG3_RECS=''
PKG3_DESC="${GAME_NAME} - arch-independant data
 package built from GOG.com installer
 ./play.it script version ${script_version}"

PKG1_CONFLICTS="${PKG2_ID}:${PKG2_ARCH}"
PKG2_CONFLICTS="${PKG1_ID}:${PKG1_ARCH}"

PKG1_DEPS="${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG1_DEPS}"
PKG2_DEPS="${PKG3_ID} (= ${PKG_VERSION}-${PKG_REVISION}), ${PKG2_DEPS}"

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

GAME_ARCHIVE_CHECKSUM_DEFAULT='md5sum'
PKG_COMPRESSION_DEFAULT='none'
PKG_PREFIX_DEFAULT='/usr/local'

fetch_args "$@"

set_checksum
set_compression
set_prefix

check_deps_hard ${SCRIPT_DEPS_HARD}

printf '\n'
set_target '1' 'gog.com'
printf '\n'

PATH_BIN="${PKG_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${PKG_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${PKG_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'

game_mkdir 'PKG_TMPDIR' "$(mktemp -u ${GAME_ID_SHORT}.XXXXX)" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG1_DIR' "${PKG1_ID}_${PKG1_VERSION}-${PKG_REVISION}_${PKG1_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG2_DIR' "${PKG2_ID}_${PKG2_VERSION}-${PKG_REVISION}_${PKG2_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"
game_mkdir 'PKG3_DIR' "${PKG3_ID}_${PKG3_VERSION}-${PKG_REVISION}_${PKG3_ARCH}" "$((${GAME_ARCHIVE_FULLSIZE}*2))"

# Check target files integrity

if [ "${GAME_ARCHIVE_CHECKSUM}" = 'md5sum' ]; then
	checksum "${GAME_ARCHIVE}" 'defaults' "${GAME_ARCHIVE1_MD5}"
fi

# Extract game data

PATH_ICON="${PATH_ICON_BASE}/${APP1_ICON_RES}/apps"
build_pkg_dirs '2' "${PATH_BIN}" "${PATH_DESK}" "${PATH_GAME}"
rm -rf "${PKG3_DIR}"
mkdir -p "${PKG3_DIR}/DEBIAN" "${PKG3_DIR}${PATH_DOC}" "${PKG3_DIR}${PATH_GAME}" "${PKG3_DIR}${PATH_ICON}"
print wait

extract_data 'mojo' "${GAME_ARCHIVE}" "${PKG_TMPDIR}" 'fix_rights,quiet'

cd "${PKG_TMPDIR}/${INSTALLER_PATH}"

chmod 755 "${APP1_EXE_PKG1}" "${APP1_EXE_PKG2}"

for file in ${INSTALLER_JUNK}; do
	rm -rf "${file}"
done

for file in ${INSTALLER_DOC}; do
	mv "${file}" "${PKG3_DIR}${PATH_DOC}"
done

for file in ${INSTALLER_GAME_PKG1}; do
	mkdir -p "${PKG1_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG1_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_GAME_PKG2}; do
	mkdir -p "${PKG2_DIR}${PATH_GAME}/${file%/*}"
	mv "${file}" "${PKG2_DIR}${PATH_GAME}/${file}"
done

for file in ${INSTALLER_GAME_PKG3}; do
	mv "${file}" "${PKG3_DIR}${PATH_GAME}"
done

cd - > /dev/null

rm -rf "${PKG_TMPDIR}"
print done

# Write launchers

write_bin_native "${PKG1_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_PKG1}" '' '' '' "${APP1_NAME} (${PKG1_ARCH})"
write_bin_native "${PKG2_DIR}${PATH_BIN}/${APP1_ID}" "${APP1_EXE_PKG2}" '' '' '' "${APP1_NAME} (${PKG2_ARCH})"
write_desktop "${APP1_ID}" "${APP1_NAME}" "${APP1_NAME_FR}" "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${APP1_CAT}"
cp -l "${PKG1_DIR}${PATH_DESK}/${APP1_ID}.desktop" "${PKG2_DIR}${PATH_DESK}/${APP1_ID}.desktop"
printf '\n'

# Build packages

printf '%s…\n' "$(l10n 'build_pkgs')"
print wait

write_pkg_debian "${PKG1_DIR}" "${PKG1_ID}" "${PKG1_VERSION}-${PKG_REVISION}" "${PKG1_ARCH}" "${PKG1_CONFLICTS}" "${PKG1_DEPS}" "${PKG1_RECS}" "${PKG1_DESC}" 'arch'
write_pkg_debian "${PKG2_DIR}" "${PKG2_ID}" "${PKG2_VERSION}-${PKG_REVISION}" "${PKG2_ARCH}" "${PKG2_CONFLICTS}" "${PKG2_DEPS}" "${PKG2_RECS}" "${PKG2_DESC}" 'arch'
write_pkg_debian "${PKG3_DIR}" "${PKG3_ID}" "${PKG3_VERSION}-${PKG_REVISION}" "${PKG3_ARCH}" "${PKG3_CONFLICTS}" "${PKG3_DEPS}" "${PKG3_RECS}" "${PKG3_DESC}"

file="${PKG1_DIR}/DEBIAN/postinst"
cat > "${file}" <<- EOF
#!/bin/sh -e

ln --symbolic --verbose "\$(which 7za)" "${PATH_GAME}/lib/7za"

exit 0
EOF
chmod 755 "${file}"

file="${PKG1_DIR}/DEBIAN/prerm"
cat > "${file}" <<- EOF
#!/bin/sh -e

rm --verbose "${PATH_GAME}/lib/7za"

exit 0
EOF
chmod 755 "${file}"

file="${PKG2_DIR}/DEBIAN/postinst"
cat > "${file}" <<- EOF
#!/bin/sh -e

ln --symbolic --verbose "\$(which 7za)" "${PATH_GAME}/lib64/7za"

exit 0
EOF
chmod 755 "${file}"

file="${PKG2_DIR}/DEBIAN/prerm"
cat > "${file}" <<- EOF
#!/bin/sh -e

rm --verbose "${PATH_GAME}/lib64/7za"

exit 0
EOF
chmod 755 "${file}"

file="${PKG3_DIR}/DEBIAN/postinst"
cat > "${file}" << EOF
#!/bin/sh -e

mkdir --parents --verbose "${PATH_ICON}"
ln --symbolic --verbose "${PATH_GAME}/${APP1_ICON}" "${PATH_ICON}/${GAME_ID}.png"

exit 0
EOF
chmod 755 "${file}"

file="${PKG3_DIR}/DEBIAN/prerm"
cat > "${file}" << EOF
#!/bin/sh -e

rm --verbose "${PATH_ICON}/${GAME_ID}.png"
rmdir --parents --ignore-fail-on-non-empty --verbose "${PATH_ICON}"

exit 0
EOF
chmod 755 "${file}"

build_pkg "${PKG1_DIR}" "${PKG1_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG1_ARCH}"
build_pkg "${PKG2_DIR}" "${PKG2_DESC}" "${PKG_COMPRESSION}" 'quiet' "${PKG2_ARCH}"
build_pkg "${PKG3_DIR}" "${PKG3_DESC}" "${PKG_COMPRESSION}" 'quiet'
print done

print_instructions "$(printf '%s' "${PKG1_DESC}" | head -n1) (${PKG1_ARCH})" "${PKG3_DIR}" "${PKG1_DIR}"
printf '\n'
print_instructions "$(printf '%s' "${PKG2_DESC}" | head -n1) (${PKG2_ARCH})" "${PKG3_DIR}" "${PKG2_DIR}"
printf '\n%s ;)\n\n' "$(l10n 'have_fun')"

exit 0

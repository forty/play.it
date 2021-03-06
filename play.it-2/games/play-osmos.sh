#!/bin/sh -e
set -o errexit

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
# Osmos
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170717.2

# Set game-specific variables

GAME_ID='osmos'
GAME_NAME='Osmos'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='Osmos_1.6.1.tar.gz'
ARCHIVE_HUMBLE_MD5='ed2cb029c20c25de719c28062e6fc9cf'
ARCHIVE_HUMBLE_SIZE='32000'
ARCHIVE_HUMBLE_VERSION='1.6.1-humble1'

ARCHIVE_DOC_PATH='Osmos'
ARCHIVE_DOC_FILES='./*.txt ./*.html'

ARCHIVE_GAME_BIN32_PATH='Osmos'
ARCHIVE_GAME_BIN32_FILES='./Osmos.bin32'

ARCHIVE_GAME_BIN64_PATH='Osmos'
ARCHIVE_GAME_BIN64_FILES='./Osmos.bin64'

ARCHIVE_GAME_DATA_PATH='Osmos'
ARCHIVE_GAME_DATA_FILES='./*.cfg ./Fonts ./Icons ./*.loc ./Sounds ./Textures'

CONFIG_FILES='./*.cfg'
DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='Osmos.bin32'
APP_MAIN_EXE_BIN64='Osmos.bin64'
APP_MAIN_OPTIONS='1>./logs/$(date +%F-%R).log 2>&1'
APP_MAIN_ICON_PATH='Icons'
APP_MAIN_ICON_RES='16 22 32 36 48 64 72 96 128 192 256'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libopenal1, libglu1-mesa-glx | libglu1, libvorbisfile3"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-libopenal lib32-glu lib32-libvorbis"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID openal glu libvorbis"

# Load common functions

target_version='2.0'

if [ -z "$PLAYIT_LIB2" ]; then
	[ -n "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"
	if [ -e "$XDG_DATA_HOME/play.it/libplayit2.sh" ]; then
		PLAYIT_LIB2="$XDG_DATA_HOME/play.it/libplayit2.sh"
	elif [ -e './libplayit2.sh' ]; then
		PLAYIT_LIB2='./libplayit2.sh'
	else
		printf '\n\033[1;31mError:\033[0m\n'
		printf 'libplayit2.sh not found.\n'
		return 1
	fi
fi
. "$PLAYIT_LIB2"

# Extract game data

extract_data_from "$SOURCE_ARCHIVE"

PKG='PKG_BIN32'
organize_data 'GAME_BIN32' "$PATH_GAME"

PKG='PKG_BIN64'
organize_data 'GAME_BIN64' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Allow persistent logging via output redirection to work

sed --in-place 's|"\./$APP_EXE" $APP_OPTIONS $@|eval &|' "${PKG_BIN32_PATH}${PATH_BIN}/$GAME_ID"
sed --in-place 's|"\./$APP_EXE" $APP_OPTIONS $@|eval &|' "${PKG_BIN64_PATH}${PATH_BIN}/$GAME_ID"

# Build package

cat > "$postinst" << EOF
for res in $APP_MAIN_ICON_RES; do
	PATH_ICON=$PATH_ICON_BASE/\${res}x\${res}/apps
	mkdir --parents "\$PATH_ICON"
	ln --symbolic "$PATH_GAME/$APP_MAIN_ICON_PATH/\${res}x\${res}.png" "\$PATH_ICON/$GAME_ID.png"
done
EOF

cat > "$prerm" << EOF
for res in $APP_MAIN_ICON_RES; do
	PATH_ICON=$PATH_ICON_BASE/\${res}x\${res}/apps
	rm "\$PATH_ICON/$GAME_ID.png"
	rmdir --parents --ignore-fail-on-non-empty "\$PATH_ICON"
done
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN32' 'PKG_BIN64'
build_pkg

# Clean up

rm --recursive "${PLAYIT_WORKDIR}"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN32'
printf '64-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN64'

exit 0

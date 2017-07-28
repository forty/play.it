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
# Owlboy
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170728.1

# Set game-specific variables

GAME_ID='owlboy'
GAME_NAME='Owlboy'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='owlboy-05232017-bin'
ARCHIVE_HUMBLE_MD5='f35fba69fadffbf498ca8a38dbceeac1'
ARCHIVE_HUMBLE_SIZE='570000'
ARCHIVE_HUMBLE_VERSION='1.2.6382.15868-humble1'
ARCHIVE_HUMBLE_TYPE='mojosetup'

ARCHIVE_DOC_PATH='data'
ARCHIVE_DOC_FILES='./Linux.README'

ARCHIVE_GAME_BIN32_PATH='data'
ARCHIVE_GAME_BIN32_FILES='./Owlboy.bin.x86 ./lib'

ARCHIVE_GAME_BIN64_PATH='data'
ARCHIVE_GAME_BIN64_FILES='./Owlboy.bin.x86_64 ./lib64'

ARCHIVE_GAME_DATA_PATH='data'
ARCHIVE_GAME_DATA_FILES='./content ./*.dll ./*.config ./monoconfig ./monomachineconfig ./Owlboy.bmp ./Owlboy.exe'

CONFIG_FILES='content/localizations/*/speechbubbleconfig.ini'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='Owlboy.bin.x86'
APP_MAIN_EXE_BIN64='Owlboy.bin.x86_64'
APP_MAIN_ICON='Owlboy.bmp'
APP_MAIN_ICON_RES='512'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glibc"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glibc"

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
organize_data 'GAME_DOC'  "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
extract_icon_from "${PKG_DATA_PATH}${PATH_GAME}/$APP_MAIN_ICON"
mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
mv "$PLAYIT_WORKDIR/icons/${APP_MAIN_ICON%.bmp}.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Build package

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
if ! [ -e "$PATH_ICON/$GAME_ID.png" ]; then
	mkdir --parents "$PATH_ICON"
	ln --symbolic "$PATH_GAME"/$APP_MAIN_ICON "$PATH_ICON/$GAME_ID.png"
fi
EOF

cat > "$prerm" << EOF
if [ -e "$PATH_ICON/$GAME_ID.png" ]; then
	rm "$PATH_ICON/$GAME_ID.png"
	rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
fi
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

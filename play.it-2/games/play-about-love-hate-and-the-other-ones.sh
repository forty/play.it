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
# About Love, Hate and the Other Ones
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170720.1

# Set game-specific variables

GAME_ID='about-love-hate-and-the-other-ones'
GAME_NAME='About Love, Hate and the Other Ones'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='aboutloveandhate-1.3.1.deb'
ARCHIVE_HUMBLE_MD5='65c314a2a970b5c787d4e7e2a837e211'
ARCHIVE_HUMBLE_SIZE='570000'
ARCHIVE_HUMBLE_VERSION='1.3.1-humble150312'

ARCHIVE_DOC_PATH='usr/local/games/loveandhate'
ARCHIVE_DOC_FILES='./README'

ARCHIVE_GAME_BIN32_PATH='usr/local/games/loveandhate/bin32'
ARCHIVE_GAME_BIN32_FILES='./loveandhate'

ARCHIVE_GAME_BIN64_PATH='usr/local/games/loveandhate/bin64'
ARCHIVE_GAME_BIN64_FILES='./loveandhate'

ARCHIVE_GAME_DATA_PATH='usr/local/games/loveandhate'
ARCHIVE_GAME_DATA_FILES='./bin'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='loveandhate'
APP_MAIN_EXE_BIN64='loveandhate'
APP_MAIN_ICON_PATH='usr/share/icons/hicolor'
APP_MAIN_ICON_RES='16 24 32 48 64 128 256'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libgl1-mesa | libgl1, libxcursor1, libxrandr2"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-glibc lib32-libgl lib32-libxcursor lib32-libxrandr"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID glibc libgl libxcursor libxrandr"

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
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

for res in $APP_MAIN_ICON_RES; do
	PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
	mkdir --parents "${PKG_DATA_PATH}${PATH_ICON}"
	mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON_PATH/${res}x${res}/apps/loveandhate.png" "${PKG_DATA_PATH}${PATH_ICON}/$GAME_ID.png"
done

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Build package

write_metadata
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

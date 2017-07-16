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
# Melody’s Escape
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170619.1

# Set game-specific variables

GAME_ID='melodys-escape'
GAME_NAME='Melody’s Escape'

ARCHIVES_LIST='ARCHIVE_HUMBLE'

ARCHIVE_HUMBLE='Melodys_Escape_Linux.zip'
ARCHIVE_HUMBLE_MD5='4d463482418c2d9917c56df3bbde6eea'
ARCHIVE_HUMBLE_SIZE='60000'
ARCHIVE_HUMBLE_VERSION='1.0-humble160601'

ARCHIVE_DOC_PATH="Melody's Escape"
ARCHIVE_DOC_FILES='./Licenses ./README.txt'

ARCHIVE_GAME_BIN_PATH="Melody's Escape"
ARCHIVE_GAME_BIN_FILES='./MelodysEscape.bin.x86 ./lib ./*.dll ./FNA.dll.config ./*.so ./MelodysEscape.exe'

ARCHIVE_GAME_DATA_PATH="Melody's Escape"
ARCHIVE_GAME_DATA_FILES='./BassPlugins ./BundledMusic ./Calibration ./Content ./Mods ./mono'

APP_MAIN_TYPE='native'
APP_MAIN_EXE='MelodysEscape.bin.x86'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_DATA_ARCH='32'
PKG_DATA_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6"
PKG_DATA_DEPS_ARCH="$PKG_DATA_ID lib32-glibc"

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

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

write_metadata 'PKG_DATA'
write_metadata 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

#print instructions

print_instructions

exit 0

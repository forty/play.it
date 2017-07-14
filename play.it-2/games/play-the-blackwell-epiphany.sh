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
# The Blackwell Epiphany
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170714.1

# Set game-specific variables

GAME_ID='the-blackwell-epiphany'
GAME_NAME='The Blackwell Epiphany'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_blackwell_epiphany_2.0.0.2.sh'
ARCHIVE_GOG_MD5='058091975ee359d7bc0f9d9848052296'
ARCHIVE_GOG_SIZE='1500000'
ARCHIVE_GOG_VERSION='1.0-gog2.0.0.2'

ARCHIVE_DOC_PATH='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN32_PATH='data/noarch/game'
ARCHIVE_GAME_BIN32_FILES='./lib ./Epiphany.bin.x86'

ARCHIVE_GAME_BIN64_PATH='data/noarch/game'
ARCHIVE_GAME_BIN64_FILES='./lib64 ./Epiphany.bin.x86_64'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./*'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN32='Epiphany.bin.x86'
APP_MAIN_EXE_BIN64='Epiphany.bin.x86_64'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256'

PACKAGES_LIST='PKG_DATA PKG_BIN32 PKG_BIN64'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN32_ARCH='32'
PKG_BIN32_DEPS_DEB="$PKG_DATA_ID, libc6, libstdc++6, libgcc1, libsdl2-2.0-0, libtheora0, libpcre3, libglib2.0-0, libharfbuzz0b, libpng16-16, libbz2-1.0, zlib1g, libfreetype6, libvorbisfile3, libogg0"
PKG_BIN32_DEPS_ARCH="$PKG_DATA_ID lib32-gcc-libs lib32-sdl2 lib32-libtheora lib32-pcre lib32-glib2 lib32-harfbuzz lib32-libpng lib32-bzip2 lib32-zlib lib32-freetype2 lib32-libogg"

PKG_BIN64_ARCH='64'
PKG_BIN64_DEPS_DEB="$PKG_BIN32_DEPS_DEB"
PKG_BIN64_DEPS_ARCH="$PKG_DATA_ID gcc-libs sdl2 libtheora pcre glib2 harfbuzz libpng bzip2 zlib freetype2 libvorbis libogg"

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

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "$PKG_DATA_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_DATA_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

for PKG in 'PKG_BIN32' 'PKG_BIN64'; do
	write_launcher 'APP_MAIN'
done

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

printf '\n'
printf '32-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN32'
printf '64-bit:'
print_instructions 'PKG_DATA' 'PKG_BIN64'

exit 0

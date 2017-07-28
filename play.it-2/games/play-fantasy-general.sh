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
# Fantasy General
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170728.1

# Set game-specific variables

GAME_ID='fantasy-general'
GAME_NAME='Fantasy General'

ARCHIVES_LIST='ARCHIVE_GOG_EN ARCHIVE_GOG_FR'

ARCHIVE_GOG_EN='gog_fantasy_general_2.0.0.8.sh'
ARCHIVE_GOG_EN_MD5='59b86b9115ae013d2e23a8b4b7b771fd'
ARCHIVE_GOG_EN_VERSION='1.0-gog2.0.0.8'
ARCHIVE_GOG_EN_SIZE='260000'

ARCHIVE_GOG_FR='gog_fantasy_general_french_2.0.0.8.sh'
ARCHIVE_GOG_FR_MD5='1b188304b4cca838e6918ca6e2d9fe2b'
ARCHIVE_GOG_FR_VERSION='1.0-gog2.0.0.8'
ARCHIVE_GOG_FR_SIZE='240000'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/data'
ARCHIVE_DOC2_FILES='./*.txt'

ARCHIVE_GAME_PATH='data/noarch/data'
ARCHIVE_GAME_FILES='./*'

GAME_IMAGE='./game.ins'

DATA_DIRS='./saves'
CONFIG_FILES='dat/prefs.dat'

APP_MAIN_TYPE='dosbox'
APP_MAIN_EXE='exe/barena.exe'
APP_MAIN_ICON='data/noarch/support/icon.png'
APP_MAIN_ICON_RES='256'

PACKAGES_LIST='PKG_MAIN'

PKG_MAIN_ARCH='32'
PKG_MAIN_DEPS_DEB="$PKG_DATA_ID, dosbox"
PKG_MAIN_DEPS_ARCH="$PKG_DATA_ID dosbox"

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
tolower "$PLAYIT_WORKDIR/gamedata"

organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME' "$PATH_GAME"

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"
mkdir --parents "$PKG_MAIN_PATH/$PATH_ICON"
mv "$PLAYIT_WORKDIR/gamedata/$APP_MAIN_ICON" "$PKG_MAIN_PATH/$PATH_ICON/$GAME_ID.png"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

write_launcher 'APP_MAIN'

sed --in-place 's|$APP_EXE \($APP_OPTIONS $@\)|cd ${APP_EXE%/*}\n${APP_EXE##*/} \1|' "${PKG_MAIN_PATH}${PATH_BIN}/$GAME_ID"

# Build package

write_metadata
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0

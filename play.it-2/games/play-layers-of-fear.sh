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
# Layers of Fear
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170717.1

# Set game-specific variables

GAME_ID='layers-of-fear'
GAME_NAME='Layers of Fear'

ARCHIVES_LIST='ARCHIVE_GOG'

ARCHIVE_GOG='gog_layers_of_fear_2.3.0.4.sh'
ARCHIVE_GOG_MD5='4bc354869662ee68938c8955f08dd276'
ARCHIVE_GOG_SIZE='4000000'
ARCHIVE_GOG_VERSION='1.1.0-gog2.3.0.4'

ARCHIVE_DOC1_PATH='data/noarch/docs'
ARCHIVE_DOC1_FILES='./*'

ARCHIVE_DOC2_PATH='data/noarch/support'
ARCHIVE_DOC2_FILES='./*.txt'

ARCHIVE_GAME_BIN_PATH='data/noarch/game'
ARCHIVE_GAME_BIN_FILES='./LOF ./*_Data/*/x86_64'

ARCHIVE_GAME_DATA_PATH='data/noarch/game'
ARCHIVE_GAME_DATA_FILES='./*_Data'

DATA_DIRS='./logs'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_BIN='LOF'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%F-%R).log'
APP_MAIN_ICON='*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_DATA PKG_BIN'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='64'
PKG_BIN_DEPS_DEB="$PKG_DATA_ID, libc6, libxcursor1, libgl1-mesa | libgl1, libxrandr2"
PKG_BIN_DEPS_ARCH="$PKG_DATA_ID glibc libxcursor libgl gcc-libs libxrandr"

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
set_standard_permissions "$PLAYIT_WORKDIR/gamedata"

PKG='PKG_BIN'
organize_data 'GAME_BIN' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC1'      "$PATH_DOC"
organize_data 'DOC2'      "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

# Build package

res="$APP_MAIN_ICON_RES"
PATH_ICON="$PATH_ICON_BASE/${res}x${res}/apps"

cat > "$postinst" << EOF
if [ ! -e "${PATH_ICON}/${GAME_ID}.png" ]; then
	mkdir --parents "$PATH_ICON"
	ln --symbolic "$PATH_GAME"/$APP_MAIN_ICON "$PATH_ICON/$GAME_ID.png"
fi
EOF

cat > "$prerm" << EOF
if [ -e "${PATH_ICON}/${GAME_ID}.png" ]; then
	rm "$PATH_ICON/$GAME_ID.png"
	rmdir --parents --ignore-fail-on-non-empty "$PATH_ICON"
fi
EOF

write_metadata 'PKG_DATA'
rm "$postinst" "$prerm"
write_metadata 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0

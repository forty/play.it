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
# Windward
# build native Linux packages from the original installers
# send your bug reports to vv221@dotslashplay.it
###

script_version=20170703.2

# Set game-specific variables

GAME_ID='war-for-the-overworld'
GAME_NAME='War for the Overworld'

ARCHIVES_LIST='ARCHIVE_GOG ARCHIVE_HUMBLE'

ARCHIVE_GOG='gog_war_for_the_overworld_2.2.0.3.sh'
ARCHIVE_GOG_MD5='45522631c0feef1e115d01a638156171'
ARCHIVE_GOG_SIZE='2500000'
ARCHIVE_GOG_VERSION='1.6.2f3-gog2.2.0.3'

ARCHIVE_HUMBLE='War_for_the_Overworld_v1.5.2_-_Linux_x64.zip'
ARCHIVE_HUMBLE_MD5='bedee8b966767cf42c55c6b883e3127c'
ARCHIVE_HUMBLE_SIZE='2500000'
ARCHIVE_HUMBLE_VERSION='1.5.2-humble170202'

ARCHIVE_DOC_PATH_GOG='data/noarch/docs'
ARCHIVE_DOC_FILES='./*'

ARCHIVE_GAME_BIN_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_BIN_PATH_HUMBLE='Linux'
ARCHIVE_GAME_BIN_FILES='./WFTO*.x86_64 ./WFTO*_Data/Plugins ./WFTO*_Data/Mono ./WFTO*_Data/CoherentUI_Host'

ARCHIVE_GAME_ASSETS_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_ASSETS_PATH_HUMBLE='Linux'
ARCHIVE_GAME_ASSETS_FILES='./WFTO*_Data/*.assets*'

ARCHIVE_GAME_DATA_PATH_GOG='data/noarch/game'
ARCHIVE_GAME_DATA_PATH_HUMBLE='Linux'
ARCHIVE_GAME_DATA_FILES='./WFTO*_Data'

DATA_DIRS='./logs ./WFTO*_Data/GameData'

APP_MAIN_TYPE='native'
APP_MAIN_EXE_GOG='WFTOGame.x86_64'
APP_MAIN_EXE_HUMBLE='WFTO.x86_64'
APP_MAIN_OPTIONS='-logFile ./logs/$(date +%F-%R).log'
APP_MAIN_ICON='WFTO*_Data/Resources/UnityPlayer.png'
APP_MAIN_ICON_RES='128'

PACKAGES_LIST='PKG_ASSETS PKG_DATA PKG_BIN'

PKG_ASSETS_ID="${GAME_ID}-assets"
PKG_ASSETS_DESCRIPTION='assets'

PKG_DATA_ID="${GAME_ID}-data"
PKG_DATA_DESCRIPTION='data'

PKG_BIN_ARCH='64'
PKG_BIN_DEPS_DEB="$PKG_ASSETS_ID, $PKG_DATA_ID, libc6, libstdc++6, libgl1-mesa-glx | libgl1, libxcursor1"
PKG_BIN_DEPS_ARCH="$PKG_ASSETS_ID $PKG_DATA_ID glibc gcc-libs libgl libxcursor"

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

chmod +x "${PKG_BIN_PATH}${PATH_GAME}"/WFTO*_Data/CoherentUI_Host/linux/CoherentUI_Host
chmod +x "${PKG_BIN_PATH}${PATH_GAME}"/WFTO*_Data/CoherentUI_Host/linux/CoherentUI_Host.bin

PKG='PKG_ASSETS'
organize_data 'GAME_ASSETS' "$PATH_GAME"

PKG='PKG_DATA'
organize_data 'DOC'       "$PATH_DOC"
organize_data 'GAME_DATA' "$PATH_GAME"

(
	cd "${PKG_DATA_PATH}${PATH_GAME}"/WFTO*_Data/uiresources/maps
	mv 'Stonegate.unity.png' 'stonegate.unity.png'
)

rm --recursive "$PLAYIT_WORKDIR/gamedata"

# Write launchers

case "$ARCHIVE" in
	('ARCHIVE_GOG')
		APP_MAIN_EXE="$APP_MAIN_EXE_GOG"
	;;
	('ARCHIVE_HUMBLE')
		APP_MAIN_EXE="$APP_MAIN_EXE_HUMBLE"
	;;
esac

PKG='PKG_BIN'
write_launcher 'APP_MAIN'

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
write_metadata 'PKG_ASSETS' 'PKG_BIN'
build_pkg

# Clean up

rm --recursive "$PLAYIT_WORKDIR"

# Print instructions

print_instructions

exit 0

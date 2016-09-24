#!/bin/sh

###
# Copyright (c) 2015-2016, Antoine Le Gonidec
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
# common functions for ./play.it scripts
# send your bug reports to vv221@dotslashplay.it
###

library_version=2.0
library_revision=20160715.1

string_error_en="\n\033[1;31mError:\033[0m"
string_error_fr="\n\033[1;31mErreur :\033[0m"

build_pkg() {
local pkg=$1
testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
local pkg_path="$(eval echo \$${pkg}_PATH)"
case $PACKAGE_TYPE in
	deb) build_pkg_deb ;;
	tar) build_pkg_tar ;;
	*) liberror 'PACKAGE_TYPE' 'build_pkg'
esac
}

build_pkg_deb() {
local pkg_filename="${PWD}/${pkg_path##*/}.deb"
build_pkg_print
TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb -Z$COMPRESSION_METHOD -b "$pkg_path" "$pkg_filename" 1>/dev/null
}

build_pkg_tar() {
local pkg_filename="${PWD}/${pkg_path##*/}.tar"
build_pkg_print
cd "$pkg_path"
tar --create --file "$pkg_filename" .
cd -
}

build_pkg_print() {
case ${LANG%_*} in
	fr) echo "Construction de $pkg_filename" ;;
	en|*) echo "Building $pkg_filename" ;;
esac
}

check_deps() {
[ "$ARCHIVE_TYPE" = 'innosetup' ] && SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
[ "$ARCHIVE_TYPE" = 'mojosetup' ] && SCRIPT_DEPS="$SCRIPT_DEPS unzip"
[ "$ARCHIVE_TYPE" = 'zip' ] && SCRIPT_DEPS="$SCRIPT_DEPS unzip"
[ "$ARCHIVE_TYPE" = 'rar' ] && SCRIPT_DEPS="$SCRIPT_DEPS unar"
[ "$CHECKSUM_METHOD" = 'md5sum' ] && SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
[ "$PACKAGE_TYPE" = 'deb' ] && SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
for dep in $SCRIPT_DEPS; do
case $dep in
	7z) check_deps_7z ;;
	convert|icotool|wrestool) check_deps_icon "$dep" ;;
	*) [ -n "$(which $dep)" ] || check_deps_failed "$dep" ;;
esac
done
}

check_deps_7z() {
if [ -n "$(which 7zr)" ]; then
	extract_7z() { 7zr x -o"$PLAYIT_WORKDIR" -y "$file"; }
elif [ -n "$(which 7za)" ]; then
	extract_7z() { 7za x -o"$PLAYIT_WORKDIR" -y "$file"; }
elif [ -n "$(which unar)" ]; then
	extract_7z() { unar -output-directory "$PLAYIT_WORKDIR" -force-overwrite -no-directory "$file"; }
else
	check_deps_failed 'p7zip'
fi
}

check_deps_icon() {
if [ -z "$(which $1)" ] && [ "$NO_ICON" != '1' ]; then
	NO_ICON='1'
	case ${LANG%_*} in
		fr) echo "$1 est introuvable. Les icônes ne seront pas extraites." ;;
		en|*) echo "$1 not found. Skipping icons extraction." ;;
	esac
fi
}

check_deps_failed() {
case ${LANG%_*} in
	fr) echo "$string_error_fr\n$1 est introuvable. Installez-le avant de lancer ce script." ;;
	en|*) echo "$string_error_en\n$1 not found. Install it before running this script." ;;
esac
return 1
}

extract_data_from() {
case ${LANG%_*} in
	fr) echo "Extraction des données de ${1##*/}" ;;
	en|*) echo "Extracting data from ${1##*/}" ;;
esac
local destination="${PLAYIT_WORKDIR}/gamedata"
mkdir --parents "$destination"
archive_type=$(eval echo \$${ARCHIVE}_TYPE)
case $archive_type in
	7z) extract_7z "$1" "$destination" ;;
	innosetup) innoextract --extract --lowercase --output-dir "$destination" --progress=1 --silent "$1" ;;
	mojosetup) unzip -d "$destination" "$1" 1>/dev/null 2>/dev/null || true ;;
	tar) tar xf "$1" -C "$destination" ;;
	rar) UNAR_OPTIONS="-output-directory \"$destination\" -no-directory"
		[ -n "$ARCHIVE_PASSWD" ] && UNAR_OPTIONS="$UNAR_OPTIONS -password \"$ARCHIVE_PASSWD\""
		unar $UNAR_OPTIONS "$1"	;;
	zip) unzip -d "$destination" "$1" 1>/dev/null ;;
	*) liberror 'ARCHIVE_TYPE' 'extract_data_from' ;;
esac
}

extract_icon_from() {
mkdir "${PLAYIT_WORKDIR}/icons"
local file_ext=${1##*.}
case $file_ext in
	exe) wrestool --extract --type=14 --output="${PLAYIT_WORKDIR}/icons" "$1" ;;
	ico) icotool --extract --output="${PLAYIT_WORKDIR}/icons" "$1" 2>/dev/null ;;
	bmp) convert "$1" "${PLAYIT_WORKDIR}/icons/${1%.bmp}.png" ;;
	*) liberror 'file_ext' 'extract_icon_from' ;;
esac
}

fetch_args() {
unset CHECKSUM_METHOD
unset COMPRESSION_METHOD
unset GAME_LANG
unset GAME_LANG_AUDIO
unset GAME_LANG_TXT
unset ICON_CHOICE
unset INSTALL_PREFIX
unset MOVIES_SUPPORT
unset PACKAGE_TYPE
unset SOURCE_ARCHIVE
for arg in "$@"; do
case "$arg" in
	'--checksum='*) export CHECKSUM_METHOD="${arg#*=}" ;;
	'--compression='*) export COMPRESSION_METHOD="${arg#*=}" ;;
	'--icon='*) export ICON_CHOICE="${arg#*=}" ;;
	'--prefix='*) export INSTALL_PREFIX="${arg#*=}" ;;
	'--lang='*) export GAME_LANG="${arg#*=}" ;;
	'--lang-audio='*) export GAME_LANG_AUDIO="${arg#*=}" ;;
	'--lang-txt='*) export GAME_LANG_TXT="${arg#*=}" ;;
	'--package='*) export PACKAGE_TYPE="${arg#*=}" ;;
	'--movies=') export MOVIES_SUPPORT="${arg#*=}" ;;
	'--'*) return 1 ;;
	*) export SOURCE_ARCHIVE="$arg" ;;
esac
done
fetch_args_set_var 'CHECKSUM_METHOD'
fetch_args_set_var 'COMPRESSION_METHOD'
fetch_args_set_var 'GAME_LANG'
fetch_args_set_var 'GAME_LANG_AUDIO'
fetch_args_set_var 'GAME_LANG_TXT'
fetch_args_set_var 'INSTALL_PREFIX'
fetch_args_set_var 'MOVIES_SUPPORT'
fetch_args_set_var 'PACKAGE_TYPE'
}

fetch_args_set_var() {
local value="$(eval echo \$$1)"
local value_default="$(eval echo \$DEFAULT_$1)"
if [ -z "$value" ] && [ -n "$value_default" ]; then
	export $1="$value_default"
fi
}

# check integrity of source archive

file_checksum() {
local source_file="$1"
shift 1
case $CHECKSUM_METHOD in
	md5) file_checksum_md5 $@ ;;
	none) file_checksum_none ;;
	*) liberror 'CHECKSUM_METHOD' 'file_checksum' ;;
esac
}

file_checksum_md5() {
case ${LANG%_*} in
	fr) echo "Contrôle de l’intégrité de ${source_file##*/}" ;;
	en|*) echo "Checking ${source_file##*/} integrity" ;;
esac
FILE_MD5="$(md5sum "$source_file" | cut --delimiter=' ' --fields=1)"
for archive in $@; do
	local archive_md5=$(eval echo \$${archive}_MD5)
	if [ "$FILE_MD5" = "$archive_md5" ]; then
		if [ -z "$ARCHIVE" ]; then
			ARCHIVE="$archive"
			set_source_archive_vars
		fi
		return 0
	fi
done
case ${LANG%_*} in
	fr) echo "$string_error_fr\nSomme de contrôle incohérente. $source_file n’est pas le fichier attendu.\nUtilisez --checksum=none pour forcer son utilisation." ;;
	en|*) echo "$string_error_en\nHasum mismatch. $source_file is not the expected file.\nUse --checksum=none to force its use." ;;
esac
return 1
}

file_checksum_none() {
if [ -z "$ARCHIVE" ]; then
	ARCHIVE="$ARCHIVE_DEFAULT"
	set_source_archive_vars
fi
}

find_source_archive() {
set_source_archive "$@"
check_deps
set_common_paths
if [ -n "$ARCHIVE" ]; then
	file_checksum "$SOURCE_ARCHIVE" "$ARCHIVE"
else
	file_checksum "$SOURCE_ARCHIVE" "$@"
fi
check_deps
}

fix_rights() {
[ -d "$1" ] || return 1
find "$1" -type d -exec chmod -c 755 '{}' +
find "$1" -type f -exec chmod -c 644 '{}' +
}

liberror() {
case ${LANG%_*} in
	fr) echo "$string_error_fr\nvaleur incorrecte pour $1 appelée par $2 : $(eval echo \$$1)" ;;
	en|*) echo "$string_error_en\ninvalid value for $1 called by $2: $(eval echo \$$1)" ;;
esac
return 1
}

organize_data() {
[ -n "$PKG_PATH" ] || PKG_PATH="$(eval echo \$${PKG}_PATH)"
if [ -n "${ARCHIVE_DOC_PATH}" ]; then
	organize_data_doc
fi
if [ -n "${ARCHIVE_GAME_PATH}" ]; then
	organize_data_game
fi
}

organize_data_doc() {
mkdir --parents "${PKG_PATH}${PATH_DOC}"
cd "${PLAYIT_WORKDIR}/gamedata/${ARCHIVE_DOC_PATH}"
for file in $ARCHIVE_DOC_FILES; do
	mv "$file" "${PKG_PATH}${PATH_DOC}"
done
cd - 1>/dev/null
}

organize_data_game() {
mkdir --parents "${PKG_PATH}${PATH_GAME}"
cd "${PLAYIT_WORKDIR}/gamedata/${ARCHIVE_GAME_PATH}"
for file in $ARCHIVE_GAME_FILES; do
	mv "$file" "${PKG_PATH}${PATH_GAME}"
done
cd - 1>/dev/null
}

set_common_defaults() {
DEFAULT_CHECKSUM_METHOD='md5'
DEFAULT_COMPRESSION_METHOD='none'
DEFAULT_GAME_LANG='en'
DEFAULT_GAME_LANG_AUDIO='en'
DEFAULT_GAME_LANG_TXT='en'
DEFAULT_INSTALL_PREFIX='/usr/local'
DEFAULT_ICON_CHOICE='original'
DEFAULT_MOVIES_SUPPORT='0'
DEFAULT_PACKAGE_TYPE='deb'
}

set_common_paths() {
NO_ICON=0
case $PACKAGE_TYPE in
	deb) set_common_paths_deb ;;
	tar) set_common_paths_tar ;;
	*) liberror 'PACKAGE_TYPE' 'set_common_paths'
esac
}

set_common_paths_deb() {
PATH_BIN="${INSTALL_PREFIX}/games"
PATH_DESK='/usr/local/share/applications'
PATH_DOC="${INSTALL_PREFIX}/share/doc/${GAME_ID}"
PATH_GAME="${INSTALL_PREFIX}/share/games/${GAME_ID}"
PATH_ICON_BASE='/usr/local/share/icons/hicolor'
}

set_common_paths_tar() {
PATH_BIN="${INSTALL_PREFIX}/bin"
PATH_DESK="$INSTALL_PREFIX"
PATH_DOC="${INSTALL_PREFIX}/doc"
PATH_GAME="${INSTALL_PREFIX}/data"
PATH_ICON_BASE="${INSTALL_PREFIX}/icons"
}

set_source_archive() {
for archive in "$@"; do
	file="$(eval echo \$$archive)"
	if [ -n "$SOURCE_ARCHIVE" ] && [ "${SOURCE_ARCHIVE##*/}" = "$file" ]; then
		ARCHIVE="$archive"
		set_source_archive_vars
		return 0
	elif [ -z "$SOURCE_ARCHIVE" ] && [ -f "$file" ]; then
		SOURCE_ARCHIVE="$file"
		ARCHIVE="$archive"
		set_source_archive_vars
		return 0
	fi
done
if [ -z "$SOURCE_ARCHIVE" ]; then
	set_source_archive_error
fi
}

set_source_archive_vars() {
case ${LANG%_*} in
	fr) echo "Utilisation de ${SOURCE_ARCHIVE}" ;;
	en|*) echo "Using ${SOURCE_ARCHIVE}" ;;
esac
ARCHIVE_MD5="$(eval echo \$${archive}_MD5)"
ARCHIVE_TYPE="$(eval echo \$${archive}_TYPE)"
ARCHIVE_UNCOMPRESSED_SIZE="$(eval echo \$${archive}_UNCOMPRESSED_SIZE)"
}

set_source_archive_error () {
case ${LANG%_*} in
	fr) echo "$string_error_fr\nTODO set_source_archive_error (fr)" ;;
	en|*) echo "$string_error_en\nTODO set_source_archive_error (en)" ;;
esac
return 1
}

set_workdir() {
[ $# = 1 ] && PKG="$1"
set_workdir_workdir
while [ $# -ge 1 ]; do
	local pkg=$1
	testvar "$pkg" 'PKG'
	set_workdir_pkg $pkg
	shift 1
done
}

set_workdir_workdir() {
local workdir_name=$(mktemp --dry-run ${GAME_ID_SHORT}.XXXXX)
local archive_size=$(eval echo \$${ARCHIVE}_UNCOMPRESSED_SIZE)
local needed_space=$(($archive_size * 2))
local free_space_tmp=$(df --output=avail /tmp | tail --lines=1)
if [ $free_space_tmp -ge $needed_space ]; then
	export PLAYIT_WORKDIR="/tmp/play.it/${workdir_name}"
else
	[ -w "$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="${HOME}/.cache"
	local free_space_cache="$(df --output=avail "$XDG_CACHE_HOME" | tail --lines=1)"
	if [ $free_space_cache -ge $needed_space ]; then
		export PLAYIT_WORKDIR="${$XDG_CACHE_HOME}/play.it/${workdir_name}"
	else
		export PLAYIT_WORKDIR="${PWD}/play.it/${workdir_name}"
	fi
fi
}

set_workdir_pkg() {
local pkg_id=$(eval echo \$${pkg}_ID)
local pkg_version=$(eval echo \$${pkg}_VERSION)
local pkg_arch=$(eval echo \$${pkg}_ARCH)
local pkg_path="${PLAYIT_WORKDIR}/${pkg_id}_${pkg_version}_${pkg_arch}"
export ${pkg}_PATH="$pkg_path"
}

sort_icons() {
local app="$1"
testvar "$app" 'APP' || liberror 'app' 'sort_icons'
local app_id="$(eval echo \$${app}_ID)"
local icon_res="$(eval echo \$${app}_ICON_RES)"
local pkg_path="$(eval echo \$${PKG}_PATH)"
case $PACKAGE_TYPE in
	deb) sort_icons_deb ;;
	tar) sort_icons_tar ;;
	*) liberror 'PACKAGE_TYPE' 'sort_icons'
esac
}

sort_icons_deb() {
for res in $icon_res; do
	path_icon="${PATH_ICON_BASE}/${res}/apps"
	mkdir -p "${pkg_path}${path_icon}"
	for file in "${PLAYIT_WORKDIR}"/icons/*${res}x*.png; do
		mv "${file}" "${pkg_path}${path_icon}/${app_id}.png"
	done
done
}

sort_icons_tar() {
for res in $icon_res; do
	for file in "${PLAYIT_WORKDIR}"/icons/*${res}x*.png; do
		mv "${file}" "${pkg_path}${PATH_ICON_BASE}/${app_id}_${res}.png"
	done
done
}

# test the validity of the argument given to parent function
# only used for debugging purposes
testvar() {
if [ -z "$(echo "$1" | grep ^${2})" ]; then
	return 1
fi
}

tolower() {
[ -d "$1" ] || return 1
find "$1" -depth | while read file; do
	newfile="${file%/*}/$(echo "${file##*/}" | tr [:upper:] [:lower:])"
	if [ "$newfile" != "$file" ] && [ "$file" != "$1" ]; then
		mv --verbose "$file" "$newfile"
	fi
done
}

write_app() {
for app in "$@"; do
	write_bin "$app"
	write_desktop "$app"
done
}

write_bin() {
local app="$1"
testvar "$app" 'APP' || liberror 'app' 'write_bin'
local app_id=$(eval echo \$${app}_ID)
local app_type=$(eval echo \$${app}_TYPE)
local file="${PKG_PATH}${PATH_BIN}/${app_id}"
mkdir --parents "${file%/*}"
write_bin_header
write_bin_set_vars
if [ "$app_type" != 'scummvm' ]; then
	local app_exe="$(eval echo \$${app}_EXE)"
	write_bin_set_exe
	write_bin_set_prefix
	write_bin_build_userdirs
	write_bin_build_prefix
fi
write_bin_run
chmod 755 "$file"
}

write_bin_header() {
cat > "$file" << EOF
#!/bin/sh
set -o errexit

EOF
}

write_bin_build_userdirs() {
cat >> "$file" << EOF
# Build user-writable directories

if [ ! -e "\$PATH_CACHE" ]; then
	mkdir -p "\$PATH_CACHE"
	init_userdir_dirs "\$PATH_CACHE" \$GAME_CACHE_DIRS
	init_userdir_files "\$PATH_CACHE" \$GAME_CACHE_FILES
fi
if [ ! -e "\$PATH_CONFIG" ]; then
	mkdir -p "\$PATH_CONFIG"
	init_userdir_dirs "\$PATH_CONFIG" \$GAME_CONFIG_DIRS
	init_userdir_files "\$PATH_CONFIG" \$GAME_CONFIG_FILES
fi
if [ ! -e "\$PATH_DATA" ]; then
	mkdir -p "\$PATH_DATA"
	init_userdir_dirs "\$PATH_DATA" \$GAME_DATA_DIRS
	init_userdir_files "\$PATH_DATA" \$GAME_DATA_FILES
fi

EOF
}

write_bin_build_userdirs_wine() {
cat >> "$file" << EOF
export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
if ! [ -e "\$WINEPREFIX" ]; then
	mkdir -p "\${WINEPREFIX%/*}"
	wineboot -i 2>/dev/null
	rm "\${WINEPREFIX}/dosdevices/z:"
fi
EOF
}

write_bin_build_prefix() {
cat >> "$file" << EOF
# Build prefix

EOF
[ "$app_type" = 'wine' ] && write_bin_build_userdirs_wine
cat >> "$file" << EOF
if [ ! -e "\$PATH_PREFIX" ]; then
	mkdir -p "\$PATH_PREFIX"
	cp -surf "\${PATH_GAME}"/* "\${PATH_PREFIX}"
fi
init_prefix_files "\$PATH_CACHE"
init_prefix_files "\$PATH_CONFIG"
init_prefix_files "\$PATH_DATA"
init_prefix_dirs "\$PATH_CACHE" \$GAME_CACHE_DIRS
init_prefix_dirs "\$PATH_CONFIG" \$GAME_CONFIG_DIRS
init_prefix_dirs "\$PATH_DATA" \$GAME_DATA_DIRS

EOF
}

write_bin_run() {
cat >> "$file" << EOF
# Run the game

EOF
case $app_type in
	dosbox) write_bin_run_dosbox ;;
	native) write_bin_run_native ;;
	scummvm) write_bin_run_scummvm ;;
	wine) write_bin_run_wine ;;
esac
if ! [ $app_type = 'scummvm' ]; then
	cat >> "$file" <<- EOF
	
	sleep 5
	clean_userdir "\$PATH_CACHE" \$CACHE_FILES
	clean_userdir "\$PATH_CONFIG" \$CONFIG_FILES
	clean_userdir "\$PATH_DATA" \$DATA_FILES
	EOF
fi
cat >> "$file" <<- EOF

exit 0
EOF
}

write_bin_run_dosbox() {
cat >> "$file" << EOF
cd "\${PATH_PREFIX}/\${APP_EXE%/*}"
dosbox -c "mount c .
c:
imgmount d \$GAME_IMAGE -t iso -fs iso
\${APP_EXE##*/} \$@
exit"
EOF
}

write_bin_run_native() {
cat >> "$file" << EOF
cd "\${PATH_PREFIX}/\${APP_EXE%/*}"
./\${APP_EXE##*/} \$@
EOF
}

write_bin_run_scummvm() {
cat >> "$file" << EOF
scummvm -p "\${PATH_GAME}" \$@ \$SCUMMVM_ID
EOF
}

write_bin_run_wine() {
cat >> "$file" << EOF
cd "\${PATH_PREFIX}/\${APP_EXE%/*}"
wine "\${APP_EXE##*/}" \$@
EOF
}

write_bin_set_vars() {
cat >> "$file" << EOF
# Set game-specific variables

GAME_ID="$GAME_ID"
PATH_GAME="$PATH_GAME"

EOF
if [ "$app_type" != 'scummvm' ]; then
	cat >> "$file" <<- EOF
	CACHE_DIRS='$CACHE_DIRS'
	CACHE_FILES='$CACHE_FILES'
	
	CONFIG_DIRS='$CONFIG_DIRS'
	CONFIG_FILES='$CONFIG_FILES'
	
	DATA_DIRS='$DATA_DIRS'
	DATA_FILES='$DATA_FILES'
	
	EOF
else
	cat >> "$file" <<- EOF
	SCUMMVM_ID='$(eval echo \$${app}_SCUMMID)'
	
	EOF
fi
}

write_bin_set_exe() {
cat >> "$file" << EOF
# Set executable file

unset APP_EXE
case "\${0##*/}" in
	$app_id) APP_EXE="$app_exe" ;;
	*) [ -n "\$1" ] && APP_EXE="\$1" && shift 1 ;;
esac

EOF
[ "$app_type" = 'wine' ] && echo "[ -z \"\$APP_EXE\" ] && APP_EXE='winecfg'\n" >> "$file"
}

write_bin_set_prefix() {
cat >> "$file" << EOF
# Set prefix name

[ -n "\$PREFIX_ID" ] || PREFIX_ID="$GAME_ID"

EOF
write_bin_set_prefix_vars
write_bin_set_prefix_funcs
}

write_bin_set_prefix_vars() {
cat >> "$file" << EOF
# Set prefix-specific variables

[ -w "\$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="\${HOME}/.cache"
[ -w "\$XDG_CONFIG_HOME" ] || XDG_CONFIG_HOME="\${HOME}/.config"
[ -w "\$XDG_DATA_HOME" ] || XDG_DATA_HOME="\${HOME}/.local/share"

PATH_CACHE="\${XDG_CACHE_HOME}/\${PREFIX_ID}"
PATH_CONFIG="\${XDG_CONFIG_HOME}/\${PREFIX_ID}"
PATH_DATA="\${XDG_DATA_HOME}/games/\${PREFIX_ID}"
EOF
if [ "$app_type" = 'wine' ] ; then
	write_bin_set_prefix_vars_wine
else
	cat >> "$file" <<- EOF
	PATH_PREFIX="\${XDG_DATA_HOME}/play.it/prefixes/\${PREFIX_ID}"
	EOF
fi
}

write_bin_set_prefix_vars_wine() {
cat >> "$file" << EOF
WINEPREFIX="\${XDG_DATA_HOME}/play.it/prefixes/\${PREFIX_ID}"
PATH_PREFIX="\${WINEPREFIX}/drive_c/\${GAME_ID}"
WINEARCH='win32'
WINEDEBUG='-all'
WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

EOF
}

write_bin_set_prefix_funcs() {
cat >> "$file" << EOF
clean_userdir() {
local target="\$1"
shift 1
for file in "\$@"; do
if [ -f "\${file}" ] && [ ! -f "\${target}/\${file}" ]; then
	mkdir -p "\${target}/\${file%/*}"
	mv "\${file}" "\${target}/\${file}"
	ln -s "\${target}/\${file}" "\${file}"
fi
done
}

init_prefix_dirs() {
cd "\$1"
shift 1
for dir in "\$@"; do
	rm -rf "\${PATH_PREFIX}/\${dir}"
	mkdir -p "\${PATH_PREFIX}/\${dir%/*}"
	ln -s "\$(readlink -e "\${dir}")" "\${PATH_PREFIX}/\${dir}"
done
cd - 1>/dev/null
}

init_prefix_files() {
cd "\$1"
find . -type f | while read file; do
	rm -f "\${PATH_PREFIX}/\${file}"
	mkdir -p "\${PATH_PREFIX}/\${file%/*}"
	ln -s "\$(readlink -e "\${file}")" "\${PATH_PREFIX}/\${file}"
done
cd - 1>/dev/null
}

init_userdir_dirs() {
cd "\$1"
shift 1
for dir in "\$@"; do
if ! [ -e "\$dir" ]; then
	if [ -e "\${PATH_GAME}/\${dir}" ]; then
		mkdir -p "\${dir%/*}"
		cp -r "\${PATH_GAME}/\${dir}" "\$dir"
	else
		mkdir -p "\$dir"
	fi
fi
done
cd - 1>/dev/null
}

init_userdir_files() {
cd "\$1"
shift 1
for file in "\$@"; do
if ! [ -e "\$file" ] && [ -e "\${PATH_GAME}/\${file}" ]; then
	mkfile -p "\${file%/*}"
	cp "\${PATH_GAME}/\${file}" "\$file"
fi
done
cd - 1>/dev/null
}

EOF
}

write_desktop() {
local app="$1"
testvar "$app" 'APP' || liberror 'app' 'write_desktop'
local app_id=$(eval echo \$${app}_ID)
local app_name="$(eval echo \$${app}_NAME)"
local app_cat="$(eval echo \$${app}_CAT)"
local target="${PKG_PATH}${PATH_DESK}/${app_id}.desktop"
mkdir --parents "${target%/*}"
cat > "${target}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Icon=$app_id
Exec=$app_id
Categories=$app_cat
EOF
}

write_metadata() {
local pkg="$1"
testvar "$pkg" 'PKG'
local pkg_arch=$(eval echo \$${pkg}_ARCH)
local pkg_conflicts="$(eval echo \$${pkg}_CONFLICTS)"
local pkg_deps="$(eval echo \$${pkg}_DEPS)"
local pkg_desc="$(eval echo \$${pkg}_DESC)"
local pkg_id=$(eval echo \$${pkg}_ID)
local pkg_maint="$(whoami)@$(hostname)"
local pkg_path="$(eval echo \$${pkg}_PATH)"
local pkg_version=$(eval echo \$${pkg}_VERSION)
local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
case $PACKAGE_TYPE in
	deb) write_metadata_deb ;;
	tar) return 0 ;;
esac
}

write_metadata_deb() {
local target="${pkg_path}/DEBIAN/control"
mkdir --parents "${target%/*}"
cat > "${target}" << EOF
Package: $pkg_id
Version: $pkg_version
Architecture: $pkg_arch
Maintainer: $pkg_maint
Installed-Size: $pkg_size
Conflicts: $pkg_conflicts
Depends: $pkg_deps
Section: non-free/games
Description: $pkg_desc
EOF
if [ "$pkg_arch" = 'all' ]; then
	sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "${target}"
fi
}

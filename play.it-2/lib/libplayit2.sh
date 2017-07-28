#!/bin/sh

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
# common functions for ./play.it scripts
# send your bug reports to vv221@dotslashplay.it
###

library_version=2.0.1
library_revision=20170708.1

# set package distribution-specific architecture
# USAGE: set_architecture $pkg
# CALLS: liberror set_architecture_arch set_architecture_deb
# NEEDED VARS: (ARCHIVE) (OPTION_PACKAGE) (PKG_ARCH)
# CALLED BY: set_temp_directories write_metadata
set_architecture() {
	local architecture
	if [ "$ARCHIVE" ] && [ -n "$(eval printf -- '%b' \"\$${1}_ARCH_${ARCHIVE#ARCHIVE_}\")" ]; then
		architecture="$(eval printf -- '%b' \"\$${1}_ARCH_${ARCHIVE#ARCHIVE_}\")"
		export ${1}_ARCH="$architecture"
	else
		architecture="$(eval printf -- '%b' \"\$${1}_ARCH\")"
	fi
	case $OPTION_PACKAGE in
		('arch')
			set_architecture_arch "$architecture"
		;;
		('deb')
			set_architecture_deb "$architecture"
		;;
		(*)
			liberror 'OPTION_PACKAGE' 'set_architecture'
		;;
	esac
}

# test the validity of the argument given to parent function
# USAGE: testvar $var_name $pattern
testvar() {
	test "${1%%_*}" = "$2"
}

# set defaults rights on files (755 for dirs & 644 for regular files)
# USAGE: set_standard_permissions $dir[…]
set_standard_permissions() {
	for dir in "$@"; do
		[  -d "$dir" ] || return 1
		find "$dir" -type d -exec chmod 755 '{}' +
		find "$dir" -type f -exec chmod 644 '{}' +
	done
}

# print OK
# USAGE: print_ok
print_ok() {
	printf '\t\033[1;32mOK\033[0m\n'
}

# print a localized error message
# USAGE: print_error
# NEEDED VARS: (LANG)
print_error() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Erreur :'
		;;
		('en'|*)
			string='Error:'
		;;
	esac
	printf '\n\033[1;31m%s\033[0m\n' "$string"
	exec 1>&2
}

# print a localized warning message
# USAGE: print_warning
# NEEDED VARS: (LANG)
print_warning() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Avertissement :'
		;;
		('en'|*)
			string='Warning:'
		;;
	esac
	printf '\n\033[1;33m%s\033[0m\n' "$string"
}

# convert files name to lower case
# USAGE: tolower $dir[…]
tolower() {
	for dir in "$@"; do
		[ -d "$dir" ] || return 1
		find "$dir" -depth -mindepth 1 | while read file; do
			newfile="${file%/*}/$(printf '%s' "${file##*/}" | tr [:upper:] [:lower:])"
			[ -e "$newfile" ] || mv "$file" "$newfile"
		done
	done
}

# display an error if a function has been called with invalid arguments
# USAGE: liberror $var_name $calling_function
# NEEDED VARS: (LANG)
liberror() {
	local var="$1"
	local value="$(eval printf -- '%b' \"\$$var\")"
	local func="$2"
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Valeur incorrecte pour %s appelée par %s : %s\n'
		;;
		('en'|*)
			string='Invalid value for %s called by %s: %s\n'
		;;
	esac
	printf "$string" "$var" "$func" "$value"
	return 1
}

# set distribution-specific package architecture for Arch Linux target
# USAGE: set_architecture_arch $architecture
# CALLED BY: set_architecture
set_architecture_arch() {
	case "$1" in
		('32'|'64')
			pkg_architecture='x86_64'
		;;
		(*)
			pkg_architecture='any'
		;;
	esac
}

# set distribution-specific package architecture for Debian target
# USAGE: set_architecture_deb $architecture
# CALLED BY: set_architecture
set_architecture_deb() {
	case "$1" in
		('32')
			pkg_architecture='i386'
		;;
		('64')
			pkg_architecture='amd64'
		;;
		(*)
			pkg_architecture='all'
		;;
	esac
}

# set source archive for data extraction
# USAGE: set_source_archive $archive[…]
# NEEDED VARS: (LANG)
# CALLS: set_archive_error_not_found
set_source_archive() {
	set_archive 'SOURCE_ARCHIVE' "$@"
	if [ "$SOURCE_ARCHIVE" ]; then
		return 0
	else
		set_archive_error_not_found "$@"
	fi
}

# display an error message if a mandatory archive is not found
# USAGE: set_archive_error_not_found $archive[…]
# NEEDED VARS: (LANG)
# CALLED BY: set_source_archive
set_archive_error_not_found() {
	print_error
	local string
	if [ "$#" = 1 ]; then
		case "${LANG%_*}" in
			('fr')
				string='Le fichier suivant est introuvable :\n'
			;;
			('en'|*)
				string='The following file could not be found:\n'
			;;
		esac
	else
		case "${LANG%_*}" in
			('fr')
				string='Aucun des fichiers suivants n’est présent :\n'
			;;
			('en'|*)
				string='None of the following files could be found:\n'
			;;
		esac
	fi
	printf "$string"
	for archive in "$@"; do
		printf '%s\n' "$(eval printf -- '%b' \"\$$archive\")"
	done
	return 1
}

# set archive for data extraction
# USAGE: set_archive $name $archive[…]
# NEEDED_VARS: (LANG) (SOURCE_ARCHIVE)
# CALLS: set_archive_vars
set_archive() {
	local name=$1
	shift 1
	if [ -n "$(eval printf -- '%b' \"\$$name\")" ]; then
		for archive in "$@"; do
			local file="$(eval printf -- '%b' \"\$$archive\")"
			if [ "$(basename "$(eval printf -- '%b' \"\$$name\")")" = "$file" ]; then
				set_archive_vars "$archive" "$name" "$(eval printf -- '%b' \"\$$name\")"
				return 0
			fi
		done
	else
		for archive in "$@"; do
			local file="$(eval printf -- '%b' \"\$$archive\")"
			if [ -f "$file" ]; then
				set_archive_vars "$archive" "$name" "$file"
				return 0
			elif [ "$SOURCE_ARCHIVE" ] && [ -f "${SOURCE_ARCHIVE%/*}/$file" ]; then
				file="${SOURCE_ARCHIVE%/*}/$file"
				set_archive_vars "$archive" "$name" "$file"
				return 0
			fi
		done
	fi
	unset $name
}

# set archive-specific variables
# USAGE: set_archive_vars $archive $name $file
# CALLS: archive_guess_type check_deps set_archive_print
# NEEDED_VARS: (LANG)
# CALLED BY: set_archive
set_archive_vars() {
	export ARCHIVE="$1"

	local name="$2"
	local file="$3"

	set_archive_print "$file"

	# set target file
	export $name="$file"

	# set archive type + check dependencies
	if [ -z "$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")" ]; then
		archive_guess_type "$file"
	fi
	export ${name}_TYPE="$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")"
	check_deps

	# compute total size of all archives
	if [ -n "$(eval printf -- '%b' \"\$${ARCHIVE}_SIZE\")" ]; then
		[ "$ARCHIVE_SIZE" ] || export ARCHIVE_SIZE='0'
		export ARCHIVE_SIZE="$(($ARCHIVE_SIZE + $(eval printf -- '%b' \"\$${ARCHIVE}_SIZE\")))"
	fi

	# set package version
	if [ -n "$(eval printf -- '%b' \"\$${ARCHIVE}_VERSION\")" ]; then
		PKG_VERSION="$(eval printf -- '%b' \"\$${ARCHIVE}_VERSION\")+${script_version}"
	fi

	# check file integrity
	if [ -n "$(eval printf -- '%b' \"\$${ARCHIVE}_MD5\")" ]; then
		file_checksum "$file"
	fi
}

# try to guess archive type from file name
# USAGE: archive_guess_type $file
# CALLS: archive_guess_type_error
# NEEDED VARS: ARCHIVE (LANG)
# CALLED BY: set_archive_vars
archive_guess_type() {
	case "${1##*/}" in
		(*.deb)
			export ${ARCHIVE}_TYPE='debian'
		;;
		(setup_*.exe|patch_*.exe)
			export ${ARCHIVE}_TYPE='innosetup'
		;;
		(gog_*.sh)
			export ${ARCHIVE}_TYPE='mojosetup'
		;;
		(*.tar)
			export ${ARCHIVE}_TYPE='tar'
		;;
		(*.tar.gz|*.tgz)
			export ${ARCHIVE}_TYPE='tar.gz'
		;;
		(*.zip)
			export ${ARCHIVE}_TYPE='zip'
		;;
		(*)
			archive_guess_type_error
		;;
	esac
}

# display an error message telling the type of the target archive is not set
# USAGE: archive_guess_type_error
# NEEDED VARS: ARCHIVE (LANG)
# CALLED BY: archive_guess_type
archive_guess_type_error() {
	print_error
	local string
	case "${LANG%_*}" in
		('fr')
			string='ARCHIVE_TYPE n’est pas défini pour %s\n'
		;;
		('en'|*)
			string='ARCHIVE_TYPE is not set for %s\n'
		;;
	esac
	printf "$string" "$ARCHIVE"
	return 1
}

# print archive use message
# USAGE: set_archive_print $file
# NEEDED VARS: (LANG)
# CALLED BY: set_archive_vars
set_archive_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Utilisation de %s\n'
		;;
		('en'|*)
			string='Using %s\n'
		;;
	esac
	printf "$string" "$1"
}

# check integrity of target file
# USAGE: file_checksum $file
# NEEDED VARS: ARCHIVE OPTION_CHECKSUM (LANG)
# CALLS: file_checksum_md5 liberror
file_checksum() {
	case "$OPTION_CHECKSUM" in
		('md5')
			file_checksum_md5 "$1"
			print_ok
		;;
		('none')
			return 0
		;;
		(*)
			liberror 'OPTION_CHECKSUM' 'file_checksum'
		;;
	esac
}

# check integrity of target file against MD5 control sum
# USAGE: file_checksum_md5 $file
# NEEDED VARS: ARCHIVE
# CALLS: file_checksum_print file_checksum_error
# CALLED BY: file_checksum
file_checksum_md5() {
	file_checksum_print "$1"
	FILE_MD5="$(md5sum "$1" | awk '{print $1}')"
	if [ "$FILE_MD5" = "$(eval printf -- '%b' \"\$${ARCHIVE}_MD5\")" ]; then
		return 0
	else
		file_checksum_error "$1"
		return 1
	fi
}

# print integrity check message
# USAGE: file_checksum_print $file
# NEEDED VARS: (LANG)
# CALLED BY: file_checksum_md5
file_checksum_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Contrôle de l’intégrité de %s'
		;;
		('en'|*)
			string='Checking integrity of %s'
		;;
	esac
	printf "$string" "$(basename "$1")"
}

# print integrity check error message
# USAGE: file_checksum_error $file
# NEEDED VARS: (LANG)
# CALLED BY: file_checksum_md5
file_checksum_error() {
	print_error
	local string1
	local string2
	case "${LANG%_*}" in
		('fr')
			string1='Somme de contrôle incohérente. %s n’est pas le fichier attendu.\n'
			string2='Utilisez --checksum=none pour forcer son utilisation.\n'
		;;
		('en'|*)
			string1='Hashsum mismatch. %s is not the expected file.\n'
			string2='Use --checksum=none to force its use.\n'
		;;
	esac
	printf "$string1" "$(basename "$1")"
	printf "$string2"
}

# check script dependencies
# USAGE: check_deps
# NEEDED VARS: (ARCHIVE) (ARCHIVE_TYPE) (OPTION_CHECKSUM) (LANG) (OPTION_PACKAGE) (SCRIPT_DEPS)
# CALLS: check_deps_7z check_deps_error_not_found
check_deps() {
	if [ "$ARCHIVE" ]; then
		case "$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")" in
			('debian')
				SCRIPT_DEPS="$SCRIPT_DEPS dpkg"
			;;
			('innosetup')
				SCRIPT_DEPS="$SCRIPT_DEPS innoextract"
			;;
			('nixstaller')
				SCRIPT_DEPS="$SCRIPT_DEPS gzip tar unxz"
			;;
			('mojosetup')
				SCRIPT_DEPS="$SCRIPT_DEPS bsdtar"
			;;
			('zip')
				SCRIPT_DEPS="$SCRIPT_DEPS unzip"
			;;
			('rar')
				SCRIPT_DEPS="$SCRIPT_DEPS unar"
			;;
			('tar.gz')
				SCRIPT_DEPS="$SCRIPT_DEPS gzip tar"
			;;
		esac
	fi
	if [ "$OPTION_CHECKSUM" = 'md5sum' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS md5sum"
	fi
	if [ "$OPTION_PACKAGE" = 'deb' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS fakeroot dpkg"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'bmp' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS convert"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'exe' ] ||\
	   [ "${APP_MAIN_ICON##*.}" = 'ico' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS icotool"
	fi
	if [ "${APP_MAIN_ICON##*.}" = 'exe' ]; then
		SCRIPT_DEPS="$SCRIPT_DEPS wrestool"
	fi
	for dep in $SCRIPT_DEPS; do
		case $dep in
			('7z')
				check_deps_7z
			;;
			(*)
				if ! which $dep >/dev/null 2>&1; then
					check_deps_error_not_found "$dep"
				fi
			;;
		esac
	done
}

# check presence of a software to handle .7z archives
# USAGE: check_deps_7z
# NEEDED VARS: (LANG)
# CALLS: check_deps_error_not_found
# CALLED BY: check_deps
check_deps_7z() {
	if which 7zr >/dev/null 2>&1; then
		extract_7z() { 7zr x -o"$2" -y "$1"; }
	elif which 7za >/dev/null 2>&1; then
		extract_7z() { 7za x -o"$2" -y "$1"; }
	elif which unar >/dev/null 2>&1; then
		extract_7z() { unar -output-directory "$2" -force-overwrite -no-directory "$1"; }
	else
		check_deps_error_not_found 'p7zip'
	fi
}

# display a message if a required dependency is missing
# USAGE: check_deps_error_not_found $command_name
# NEEDED VARS: (LANG)
# CALLED BY: check_deps check_deps_7z
check_deps_error_not_found() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='%s est introuvable. Installez-le avant de lancer ce script.\n'
		;;
		('en'|*)
			string='%s not found. Install it before running this script.\n'
		;;
	esac
	printf "$string" "$1"
	return 1
}

# display script usage
# USAGE: help
# NEEDED VARS: (LANG)
# CALLS: help_checksum help_compression help_prefix help_package
help() {
	local string
	local string_archive
	case "${LANG%_*}" in
		('fr')
			string='Utilisation :'
			string_archive='Ce script reconnaît l’archive suivante :'
			string_archives='Ce script reconnaît les archives suivantes :'
		;;
		('en'|*)
			string='Usage:'
			string_archive='This script can work on the following archive:'
			string_archives='This script can work on the following archives:'
		;;
	esac
	printf '\n'
	printf '%s %s [OPTION]… [ARCHIVE]\n\n' "$string" "${0##*/}"
	
	printf 'OPTIONS\n\n'
	help_checksum
	printf '\n'
	help_compression
	printf '\n'
	help_prefix
	printf '\n'
	help_package
	printf '\n'

	printf 'ARCHIVE\n\n'
	if [ ${ARCHIVE_LISTS##* *} ]; then
		printf '%s\n' "$string_archive"
	else
		printf '%s\n' "$string_archives"
	fi
	for archive in $ARCHIVES_LIST; do
		printf '%s\n' "$(eval printf -- '%b' \"\$$archive\")"
	done
	printf '\n'
}

# display --checksum option usage
# USAGE: help_checksum
# NEEDED VARS: (LANG)
# CALLED BY: help
help_checksum() {
	local string
	local string_md5
	local string_none
	case "${LANG%_*}" in
		('fr')
			string='Choix de la méthode de vérification d’intégrité de l’archive'
			string_md5='vérification via md5sum (méthode par défaut)'
			string_none='pas de vérification'
		;;
		('en'|*)
			string='Archive integrity verification method choice'
			string_md5='md5sum verification (default method)'
			string_none='no verification'
		;;
	esac
	printf -- '--checksum=md5|none\n'
	printf -- '--checksum md5|none\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tmd5\t%s\n' "$string_md5"
	printf '\tnone\t%s\n' "$string_none"
}

# display --compression option usage
# USAGE: help_compression
# NEEDED VARS: (LANG)
# CALLED BY: help
help_compression() {
	local string
	local string_none
	local string_gzip
	local string_xz
	case "${LANG%_*}" in
		('fr')
			string='Choix de la méthode de compression des paquets générés'
			string_none='pas de compression (méthode par défaut)'
			string_gzip='compression gzip (rapide)'
			string_xz='compression xz (plus lent mais plus efficace que gzip)'
		;;
		('en'|*)
			string='Generated packages compression method choice'
			string_none='no compression (default method)'
			string_gzip='gzip compression (fast)'
			string_xz='xz compression (slower but more efficient than gzip)'
		;;
	esac
	printf -- '--compression=none|gzip|xz\n'
	printf -- '--compression none|gzip|xz\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tnone\t%s\n' "$string_none"
	printf '\tgzip\t%s\n' "$string_gzip"
	printf '\txz\t%s\n' "$string_xz"
}

# display --prefix option usage
# USAGE: help_prefix
# NEEDED VARS: (LANG)
# CALLED BY: help
help_prefix() {
	local string
	local string_absolute
	local string_default
	case "${LANG%_*}" in
		('fr')
			string='Choix du chemin d’installation du jeu'
			string_absolute='Cette option accepte uniquement un chemin absolu.'
			string_default='chemin par défaut :'
		;;
		('en'|*)
			string='Game installation path choice'
			string_absolute='This option accepts an absolute path only.'
			string_default='default path:'
		;;
	esac
	printf -- '--prefix=$path\n'
	printf -- '--prefix $path\n\n'
	printf '\t%s\n\n' "$string"
	printf '\t%s\n' "$string_absolute"
	printf '\t%s /usr/local\n' "$string_default"
}

# display --package option usage
# USAGE: help_package
# NEEDED VARS: (LANG)
# CALLED BY: help
help_package() {
	local string
	local string_default
	local string_arch
	local string_deb
	case "${LANG%_*}" in
		('fr')
			string='Choix du type de paquet à construire'
			string_default='(type par défaut)'
			string_arch='paquet .pkg.tar (Arch Linux)'
			string_deb='paquet .deb (Debian, Ubuntu)'
		;;
		('en'|*)
			string='Generated package Type choice'
			string_default='(default type)'
			string_arch='.pkg.tar package (Arch Linux)'
			string_deb='.deb package (Debian, Ubuntu)'
		;;
	esac
	printf -- '--package=arch|deb\n'
	printf -- '--package arch|deb\n\n'
	printf '\t%s\n\n' "$string"
	printf '\tarch\t%s' "$string_arch"
	[ "$DEFAULT_OPTION_PACKAGE" = 'arch' ] && printf ' %s\n' "$string_default" || printf '\n'
	printf '\tdeb\t%s' "$string_deb"
	[ "$DEFAULT_OPTION_PACKAGE" = 'deb' ] && printf ' %s\n' "$string_default" || printf '\n'
}

# set temporary directories
# USAGE: set_temp_directories $pkg[…]
# NEEDED VARS: (ARCHIVE_SIZE) GAME_ID (LANG) (PWD) (XDG_CACHE_HOME) (XDG_RUNTIME_DIR)
# CALLS: set_temp_directories_error_no_size set_temp_directories_error_not_enough_space set_temp_directories_pkg testvar
set_temp_directories() {

	# If $PLAYIT_WORKDIR is already set, delete it before setting a new one
	[ "$PLAYIT_WORKDIR" ] && rm --force --recursive "$PLAYIT_WORKDIR"

	# If there is only a single package, make it the default one for the current instance
	[ $# = 1 ] && PKG="$1"

	# Generate an unique name for the current instance
	local name="play.it/$(mktemp --dry-run ${GAME_ID}.XXXXX)"

	# Look for a directory with enough free space to work in
	if [ "$ARCHIVE_SIZE" ]; then
		local needed_space=$(($ARCHIVE_SIZE * 2))
	else
		set_temp_directories_error_no_size
	fi
	[ "$XDG_RUNTIME_DIR" ] || XDG_RUNTIME_DIR="/run/user/$(id -u)"
	[ "$XDG_CACHE_HOME" ]  || XDG_CACHE_HOME="$HOME/.cache"
	local free_space_run=$(df --output=avail "$XDG_RUNTIME_DIR" 2>/dev/null | tail --lines=1)
	local free_space_tmp=$(df --output=avail /tmp 2>/dev/null | tail --lines=1)
	local free_space_cache=$(df --output=avail "$XDG_CACHE_HOME" 2>/dev/null | tail --lines=1)
	local free_space_pwd=$(df --output=avail "$PWD" 2>/dev/null | tail --lines=1)
	if [ -w "$XDG_RUNTIME_DIR" ] && [ $free_space_run -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_RUNTIME_DIR/$name"
	elif [ -w '/tmp' ] && [ $free_space_tmp -ge $needed_space ]; then
		export PLAYIT_WORKDIR="/tmp/$name"
	elif [ -w "$XDG_CACHE_HOME" ] && [ $free_space_cache -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$XDG_CACHE_HOME/$name"
	elif [ -w "$PWD" ] && [ $free_space_pwd -ge $needed_space ]; then
		export PLAYIT_WORKDIR="$PWD/$name"
	else
		set_temp_directories_error_not_enough_space
	fi

	# If $PLAYIT_WORKDIR is an already existing directory, set a new one
	if [ -e "$PLAYIT_WORKDIR" ]; then
		set_temp_directories
		return 0
	fi

	# Set $postinst and $prerm
	mkdir --parents "$PLAYIT_WORKDIR/scripts"
	export postinst="$PLAYIT_WORKDIR/scripts/postinst"
	export prerm="$PLAYIT_WORKDIR/scripts/prerm"

	# Set temporary directories for each package to build
	for pkg in "$@"; do
		testvar "$pkg" 'PKG'
		set_temp_directories_pkg $pkg
	done
}

# set package-secific temporary directory
# USAGE: set_temp_directories_pkg $pkg
# NEEDED VARS: (ARCHIVE) (OPTION_PACKAGE) PLAYIT_WORKDIR (PKG_ARCH) PKG_ID|GAME_ID PKG_VERSION|script_version
# CALLED BY: set_temp_directories
set_temp_directories_pkg() {

	# Get package ID
	local pkg_id
	if [ "$(eval printf -- '%b' \"\$${1}_ID_${ARCHIVE#ARCHIVE_}\")" ]; then
		pkg_id="$(eval printf -- '%b' \"\$${1}_ID_${ARCHIVE#ARCHIVE_}\")"
	elif [ "$(eval printf -- '%b' \"\$${1}_ID\")" ]; then
		pkg_id="$(eval printf -- '%b' \"\$${1}_ID\")"
	else
		pkg_id="$GAME_ID"
	fi
	export ${1}_ID="$pkg_id"

	# Get package version
	local pkg_version
	if [ -n "$(eval printf -- '%b' \"\$${1}_VERSION\")" ]; then
		pkg_version="$(eval printf -- '%b' \"\$${1}_VERSION\")+$script_version"
	elif [ "$PKG_VERSION" ]; then
		pkg_version="$PKG_VERSION"
	else
		pkg_version='1.0-1+$script_version'
	fi

	# Get package architecture
	local pkg_architecture
	set_architecture "$1"

	# Set $PKG_PATH
	if [ "$OPTION_PACKAGE" = 'arch' ] && [ "$(eval printf -- '%b' \"\$${1}_ARCH\")" = '32' ]; then
		pkg_id="lib32-$pkg_id"
	fi
	export ${1}_PATH="$PLAYIT_WORKDIR/${pkg_id}_${pkg_version}_${pkg_architecture}"
}

# display an error if set_temp_directories() is called before setting $ARCHIVE_SIZE
# USAGE: set_temp_directories_error_no_size
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_no_size() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='$ARCHIVE_SIZE doit être défini avant tout appel à set_temp_directories().\n'
		;;
		('en'|*)
			string='$ARCHIVE_SIZE must be set before any call to set_temp_directories().\n'
		;;
	esac
	printf "$string"
	return 1
}

# display an error if there is not enough free space to work in any of the tested directories
# USAGE: set_temp_directories_error_not_enough_space
# NEEDED VARS: (LANG)
# CALLS: print_error
# CALLED BY: set_temp_directories
set_temp_directories_error_not_enough_space() {
	print_error
	case "${LANG%_*}" in
		('fr')
			string='Il n’y a pas assez d’espace libre dans les différents répertoires testés :\n'
		;;
		('en'|*)
			string='There is not enough free space in the tested directories:\n'
		;;
	esac
	printf "$string"
	for path in "$XDG_RUNTIME_DIR" '/tmp' "$XDG_CACHE_HOME" "$PWD"; do
		printf '%s\n' "$path"
	done
	return 1
}

# Check library version against script target version

version_major_library=${library_version%%.*}
version_major_target=${target_version%%.*}

version_minor_library=$(printf '%s' $library_version | cut --delimiter='.' --fields=2)
version_minor_target=$(printf '%s' $target_version | cut --delimiter='.' --fields=2)

if [ $version_major_library -ne $version_major_target ] || [ $version_minor_library -lt $version_minor_target ]; then
	print_error
	case "${LANG%_*}" in
		('fr')
			string1='Mauvaise version de libplayit2.sh\n'
			string2='La version cible est : %s\n'
		;;
		('en'|*)
			string1='Wrong version of libplayit2.sh\n'
			string2='Target version is: %s\n'
		;;
	esac
	printf "$string1"
	printf "$string2" "$target_version"
	exit 1
fi

# Set allowed values for common options

ALLOWED_VALUES_CHECKSUM='none md5'
ALLOWED_VALUES_COMPRESSION='none gzip xz'
ALLOWED_VALUES_PACKAGE='arch deb'

# Set default values for common options

DEFAULT_OPTION_CHECKSUM='md5'
DEFAULT_OPTION_COMPRESSION='none'
DEFAULT_OPTION_PREFIX='/usr/local'
DEFAULT_OPTION_PACKAGE='deb'
unset winecfg_desktop
unset winecfg_launcher

# Parse arguments given to the script

unset OPTION_CHECKSUM
unset OPTION_COMPRESSION
unset OPTION_PREFIX
unset OPTION_PACKAGE
unset SOURCE_ARCHIVE

while [ $# -gt 0 ]; do
	case "$1" in
		('--help')
			help
			exit 0
		;;
		('--checksum='*|\
		 '--checksum'|\
		 '--compression='*|\
		 '--compression'|\
		 '--prefix='*|\
		 '--prefix'|\
		 '--package='*|\
		 '--package')
			if [ "${1%=*}" != "${1#*=}" ]; then
				option="$(printf '%s' "${1%=*}" | sed 's/^--//')"
				value="${1#*=}"
			else
				option="$(printf '%s' "$1" | sed 's/^--//')"
				value="$2"
				shift 1
			fi
			if [ "$value" = 'help' ]; then
				eval help_$option
				exit 0
			else
				export OPTION_$(printf '%s' $option | tr [:lower:] [:upper:])="$value"
			fi
			unset option
			unset value
		;;
		('--'*)
			return 1
		;;
		(*)
			export SOURCE_ARCHIVE="$1"
		;;
	esac
	shift 1
done

# Try to detect the host distribution through lsb_release

if [ ! "$OPTION_PACKAGE" ]; then
	unset GUESSED_HOST_OS
	if [ -e '/etc/os-release' ]; then
		GUESSED_HOST_OS="$(grep '^ID=' '/etc/os-release' | cut --delimiter='=' --fields=2)"
	elif which lsb_release >/dev/null 2>&1; then
		GUESSED_HOST_OS="$(lsb_release --id --short | tr [:upper:] [:lower:])"
	fi
	case "$GUESSED_HOST_OS" in
		('debian'|\
		 'ubuntu'|\
		 'linuxmint'|\
		 'handylinux')
			DEFAULT_OPTION_PACKAGE='deb'
		;;
		('arch'|\
		 'manjaro'|'manjarolinux')
			DEFAULT_OPTION_PACKAGE='arch'
		;;
		(*)
			print_warning
			case "${LANG%_*}" in
				('fr')
					string1='L’auto-détection du format de paquet le plus adapté a échoué.\n'
					string2='Le format de paquet %s sera utilisé par défaut.\n'
				;;
				('en'|*)
					string1='Most pertinent package format auto-detection failed.\n'
					string2='%s package format will be used by default.\n'
				;;
			esac
			printf "$string1"
			printf "$string2" "$DEFAULT_OPTION_PACKAGE"
			printf '\n'
		;;
	esac
fi

# Set options not already set by script arguments to default values

for option in 'CHECKSUM' 'COMPRESSION' 'PREFIX' 'PACKAGE'; do
	if [ -z "$(eval printf -- '%b' \"\$OPTION_$option\")" ] && [ -n "$(eval printf -- \"\$DEFAULT_OPTION_$option\")" ]; then
		export OPTION_$option="$(eval printf -- '%b' \"\$DEFAULT_OPTION_$option\")"
	fi
done

# Check options values validity

check_option_validity() {
	local name="$1"
	local value="$(eval printf -- '%b' \"\$OPTION_$option\")"
	local allowed_values="$(eval printf -- '%b' \"\$ALLOWED_VALUES_$option\")"
	for allowed_value in $allowed_values; do
		if [ "$value" = "$allowed_value" ]; then
			return 0
		fi
	done
	print_error
	local string1
	local string2
	case "${LANG%_*}" in
		('fr')
			string1='%s n’est pas une valeur valide pour --%s.\n'
			string2='Lancez le script avec l’option --%s=help pour une liste des valeurs acceptés.\n'
		;;
		('en'|*)
			string1='%s is not a valid value for --%s.\n'
			string2='Run the script with the option --%s=help to get a list of supported values.\n'
		;;
	esac
	printf "$string1" "$value" "$(printf '%s' $option | tr [:upper:] [:lower:])"
	printf "$string2" "$(printf '%s' $option | tr [:upper:] [:lower:])"
	printf '\n'
	exit 1
}

for option in 'CHECKSUM' 'COMPRESSION' 'PACKAGE'; do
	check_option_validity "$option"
done

# Check script dependencies

check_deps

# Set package paths

case $OPTION_PACKAGE in
	('arch')
		PATH_BIN="$OPTION_PREFIX/bin"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$OPTION_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$OPTION_PREFIX/share/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	('deb')
		PATH_BIN="$OPTION_PREFIX/games"
		PATH_DESK='/usr/local/share/applications'
		PATH_DOC="$OPTION_PREFIX/share/doc/$GAME_ID"
		PATH_GAME="$OPTION_PREFIX/share/games/$GAME_ID"
		PATH_ICON_BASE='/usr/local/share/icons/hicolor'
	;;
	(*)
		liberror 'OPTION_PACKAGE' "$0"
	;;
esac

if [ -z "$LIB_ONLY" ]; then
	# Set source archive

	set_source_archive $ARCHIVES_LIST

	# Set working directories

	set_temp_directories $PACKAGES_LIST
fi

# extract data from given archive
# USAGE: extract_data_from $archive[…]
# NEEDED_VARS: (ARCHIVE) (ARCHIVE_PASSWD) (ARCHIVE_TYPE) (LANG) (PLAYIT_WORKDIR)
# CALLS: liberror extract_7z extract_data_from_print
extract_data_from() {
	[ "$PLAYIT_WORKDIR" ] || return 1
	[ "$ARCHIVE" ] || return 1

	for file in "$@"; do
		extract_data_from_print "$(basename "$file")"

		local destination="$PLAYIT_WORKDIR/gamedata"
		mkdir --parents "$destination"
		local archive_type="$(eval printf -- '%b' \"\$${ARCHIVE}_TYPE\")"
		case "$archive_type" in
			('7z')
				extract_7z "$file" "$destination"
			;;
			('debian')
				dpkg-deb --extract "$file" "$destination"
			;;
			('innosetup')
				printf '\n'
				innoextract --extract --lowercase --output-dir "$destination" --progress=1 --silent "$file"
			;;
			('mojosetup')
				bsdtar --directory "$destination" --extract --file "$file"
				set_standard_permissions "$destination"
			;;
			('mojosetup_unzip')
				unzip -o -d "$destination" "$file" 1>/dev/null 2>&1 || true
				set_standard_permissions "$destination"
			;;
			('nix_stage1')
				local input_blocksize=$(head --lines=514 "$file" | wc --bytes | tr --delete ' ')
				dd if="$file" ibs=$input_blocksize skip=1 obs=1024 conv=sync 2>/dev/null | gunzip --stdout | tar --extract --file - --directory "$destination"
			;;
			('nix_stage2')
				tar --extract --xz --file "$file" --directory "$destination"
			;;
			('rar')
				# compute archive password from GOG id
				if [ -z "$ARCHIVE_PASSWD" ] && [ -n "$(eval printf -- '%b' \"\$${ARCHIVE}_GOGID\")" ]; then
					ARCHIVE_PASSWD="$(printf '%s' "$(eval printf -- '%b' \"\$${ARCHIVE}_GOGID\")" | md5sum | cut -d' ' -f1)"
				fi
				if [ -n "$ARCHIVE_PASSWD" ]; then
					UNAR_OPTIONS="-password $ARCHIVE_PASSWD"
				fi
				unar -no-directory -output-directory "$destination" $UNAR_OPTIONS "$file" 1>/dev/null
			;;
			('tar'|'tar.gz')
				tar --extract --file "$file" --directory "$destination"
			;;
			('zip')
				unzip -d "$destination" "$file" 1>/dev/null
			;;
			(*)
				liberror 'ARCHIVE_TYPE' 'extract_data_from'
			;;
		esac

		if [ "$archive_type" != 'innosetup' ]; then
			print_ok
		fi
	done
}

# print data extraction message
# USAGE: extract_data_from_print $file
# NEEDED VARS: (LANG)
# CALLED BY: extract_data_from
extract_data_from_print() {
	case "${LANG%_*}" in
		('fr')
			string='Extraction des données de %s'
		;;
		('en'|*)
			string='Extracting data from %s'
		;;
	esac
	printf "$string" "$1"
}

# put files from archive in the right package directories
# USAGE: organize_data $id $path
# NEEDED VARS: PLAYIT_WORKDIR PKG PKG_PATH
organize_data() {
	local archive_path
	if [ -n "$(eval printf -- '%b' \"\$ARCHIVE_${1}_PATH_${ARCHIVE#ARCHIVE_}\")" ]; then
		archive_path="$(eval printf -- '%b' \"\$ARCHIVE_${1}_PATH_${ARCHIVE#ARCHIVE_}\")"
	elif [ -n "$(eval printf -- '%b' \"\$ARCHIVE_${1}_PATH\")" ]; then
		archive_path="$(eval printf -- '%b' \"\$ARCHIVE_${1}_PATH\")"
	else
		unset archive_path
	fi

	local archive_files
	if [ -n "$(eval printf -- '%b' \"\$ARCHIVE_${1}_FILES_${ARCHIVE#ARCHIVE_}\")" ]; then
		archive_files="$(eval printf -- '%b' \"\$ARCHIVE_${1}_FILES_${ARCHIVE#ARCHIVE_}\")"
	elif [ -n "$(eval printf -- '%b' \"\$ARCHIVE_${1}_FILES\")" ]; then
		archive_files="$(eval printf -- '%b' \"\$ARCHIVE_${1}_FILES\")"
	else
		unset archive_files
	fi

	if [ "$archive_path" ] && [ "$archive_files" ] && [ -d "$PLAYIT_WORKDIR/gamedata/$archive_path" ]; then
		local pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")${2}"
		mkdir --parents "$pkg_path"
		(
			cd "$PLAYIT_WORKDIR/gamedata/$archive_path"
			for file in $archive_files; do
				if [ -e "$file" ]; then
					cp --recursive --force --link --parents "$file" "$pkg_path"
					rm --recursive "$file"
				fi
			done
		)
	fi
}

# extract .png or .ico files from given file
# USAGE: extract_icon_from $file[…]
# NEEDED VARS: PLAYIT_WORKDIR
# CALLS: liberror
extract_icon_from() {
	for file in "$@"; do
		local destination="$PLAYIT_WORKDIR/icons"
		mkdir --parents "$destination"
		case "${file##*.}" in
			('exe')
				if [ "$WRESTOOL_NAME" ]; then
					WRESTOOL_OPTIONS="--name=$WRESTOOL_NAME"
				fi
				wrestool --extract --type=14 $WRESTOOL_OPTIONS --output="$destination" "$file"
			;;
			('ico')
				icotool --extract --output="$destination" "$file" 2>/dev/null
			;;
			('bmp')
				local filename="${file##*/}"
				convert "$file" "$destination/${filename%.bmp}.png"
			;;
			(*)
				liberror 'file extension' 'extract_icon_from'
			;;
		esac
	done
}

# create icons layout
# USAGE: sort_icons $app[…]
# NEEDED VARS: APP_ICON_RES (APP_ID) GAME_ID PKG PKG_PATH
sort_icons() {
for app in $@; do
	testvar "$app" 'APP' || liberror 'app' 'sort_icons'

	local app_id
	if [ -n "$(eval printf -- '%b' \"\$${app}_ID\")" ]; then
		app_id="$(eval printf -- '%b' \"\$${app}_ID\")"
	else
		app_id="$GAME_ID"
	fi

	local icon_res="$(eval printf -- '%b' \"\$${app}_ICON_RES\")"
	local pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	for res in $icon_res; do
		path_icon="$PATH_ICON_BASE/${res}x${res}/apps"
		mkdir --parents "${pkg_path}${path_icon}"
		for file in "$PLAYIT_WORKDIR"/icons/*${res}x${res}x*.png; do
			mv "$file" "${pkg_path}${path_icon}/${app_id}.png"
		done
	done
done
}

# extract and sort icons from given .ico or .exe file
# USAGE: extract_and_sort_icons_from $app[…]
# NEEDED VARS: APP_ICON APP_ICON_RES (APP_ID) GAME_ID PKG PKG_PATH PLAYIT_WORKDIR
# CALLS: extract_icon_from liberror sort_icons
extract_and_sort_icons_from() {
	local app_icon
	local pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'sort_icons'

		if [ "$ARCHIVE" ] && [ -n "$(eval printf -- '%b' \"\$${app}_ICON_${ARCHIVE#ARCHIVE_}\")" ]; then
			app_icon="$(eval printf -- '%b' \"\$${app}_ICON_${ARCHIVE#ARCHIVE_}\")"
			export ${app}_ICON="$app_icon"
		else
			app_icon="$(eval printf -- '%b' \"\$${app}_ICON\")"
		fi

		if [ ! "$WRESTOOL_NAME" ] && [ -n "$(eval printf -- '%b' \"\$${app}_ICON_ID\")" ]; then
			WRESTOOL_NAME="$(eval printf -- '%b' \"\$${app}_ICON_ID\")"
		fi

		extract_icon_from "${pkg_path}${PATH_GAME}/$app_icon"
		unset WRESTOOL_NAME

		if [ "${app_icon##*.}" = 'exe' ]; then
			extract_icon_from "$PLAYIT_WORKDIR/icons"/*.ico
		fi

		sort_icons "$app"
		rm --recursive "$PLAYIT_WORKDIR/icons"
	done
}

# move icons to the target package
# USAGE: move_icons_to $pkg
# NEEDED VARS: PATH_ICON_BASE PKG
move_icons_to() {
	local source_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	local destination_path="$(eval printf -- '%b' \"\$${1}_PATH\")"
	(
		cd "$source_path"
		cp --link --parents --recursive "./$PATH_ICON_BASE" "$destination_path"
		rm --recursive "./$PATH_ICON_BASE"
		rmdir --ignore-fail-on-non-empty --parents "./${PATH_ICON_BASE%/*}"
	)
}

# print installation instructions
# USAGE: print_instructions $pkg[…]
# NEEDED VARS: (GAME_NAME) (OPTION_PACKAGE) (PACKAGES_LIST)
print_instructions() {
	[ "$GAME_NAME" ] || return 1
	if [ $# = 0 ]; then
		print_instructions $PACKAGES_LIST
		return 0
	fi
	case "${LANG%_*}" in
		('fr')
			string='\nInstallez %s en lançant la série de commandes suivantes en root :\n'
		;;
		('en'|*)
			string='\nInstall %s by running the following commands as root:\n'
		;;
	esac
	printf "$string" "$GAME_NAME"
	case $OPTION_PACKAGE in
		('arch')
			print_instructions_arch "$@"
		;;
		('deb')
			print_instructions_deb "$@"
		;;
		(*)
			liberror 'OPTION_PACKAGE' 'print_instructions'
		;;
	esac
	printf '\n'
}

# print installation instructions for Arch Linux
# USAGE: print_instructions_arch $pkg[…]
print_instructions_arch() {
	printf 'pacman -U'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
}

# print installation instructions for Debian
# USAGE: print_instructions_deb $pkg[…]
# CALLS: print_instructions_deb_apt print_instructions_deb_dpkg
print_instructions_deb() {
	if which apt >/dev/null 2>&1; then
		debian_version="$(apt --version | cut --delimiter=' ' --fields=2)"
		debian_version_major="$(printf '%s' "$debian_version" | cut --delimiter='.' --fields='1')"
		debian_version_minor="$(printf '%s' "$debian_version" | cut --delimiter='.' --fields='2')"
	fi
	if [ $debian_version_major -ge 2 ] ||\
	   [ $debian_version_major = 1 ] &&\
	   [ ${debian_version_minor%~*} -ge 1 ]; then
		print_instructions_deb_apt "$@"
	else
		print_instructions_deb_dpkg "$@"
	fi
}

# print installation instructions for Debian with apt
# USAGE: print_instructions_deb_apt $pkg[…]
# CALLED BY: print_instructions_deb
print_instructions_deb_apt() {
	printf 'apt install'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
}

# print installation instructions for Debian with dpkg + apt-get
# USAGE: print_instructions_deb_dpkg $pkg[…]
# CALLED BY: print_instructions_deb
print_instructions_deb_dpkg() {
	printf 'dpkg -i'
	for pkg in $@; do
		printf ' %s' "$(eval printf -- '%b' \"\$${pkg}_PKG\")"
	done
	printf '\n'
	printf 'apt-get install -f\n'
}

# alias calling write_bin() and write_desktop()
# USAGE: write_launcher $app[…]
# NEEDED VARS: (APP_CAT) APP_ID|GAME_ID APP_EXE APP_LIBS APP_NAME|GAME_NAME APP_OPTIONS APP_POSTRUN APP_PRERUN APP_TYPE CACHE_DIRS CACHE_FILES CONFIG_DIRS CONFIG_FILES DATA_DIRS DATA_FILES GAME_ID (LANG) PATH_BIN PATH_DESK PATH_GAME PKG PKG_PATH
# CALLS: write_bin write_dekstop
write_launcher() {
	write_bin $@
	write_desktop $@
}

# write launcher script
# USAGE: write_bin $app[…]
# NEEDED VARS: APP_ID|GAME_ID APP_EXE APP_LIBS APP_OPTIONS APP_POSTRUN APP_PRERUN APP_TYPE CACHE_DIRS CACHE_FILES CONFIG_DIRS CONFIG_FILES DATA_DIRS DATA_FILES GAME_ID (LANG) PATH_BIN PATH_GAME PKG PKG_PATH
# CALLS: liberror testvar write_bin_build_wine write_bin_run_dosbox write_bin_run_native write_bin_run_scummvm write_bin_run_wine write_bin_set_scummvm write_bin_set_wine write_bin_winecfg
# CALLED BY: write_launcher
write_bin() {
	local pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	local app
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_bin'

		# Get app-specific variables
		local app_id
		if [ -n "$(eval printf -- '%b' \"\$${app}_ID\")" ]; then
			app_id="$(eval printf -- '%b' \"\$${app}_ID\")"
		else
			app_id="$GAME_ID"
		fi

		local app_type="$(eval printf -- '%b' \"\$${app}_TYPE\")"
		if [ "$app_type" != 'scummvm' ]; then
			local app_options="$(eval printf -- '%b' \"\$${app}_OPTIONS\")"
			local app_prerun="$(eval printf -- '%b' \"\$${app}_PRERUN\")"
			local app_postrun="$(eval printf -- '%b' \"\$${app}_POSTRUN\")"

			local app_exe
			if [ -n "$(eval printf -- '%b' \"\$${app}_EXE_${PKG#PKG_}\")" ]; then
				app_exe="$(eval printf -- '%b' \"\$${app}_EXE_${PKG#PKG_}\")"
			else
				app_exe="$(eval printf -- '%b' \"\$${app}_EXE\")"
			fi

			local app_libs
			if [ -n "$(eval printf -- '%b' \"\$${app}_LIBS_${PKG#PKG_}\")" ]; then
				app_libs="$(eval printf -- '%b' \"\$${app}_LIBS_${PKG#PKG_}\")"
			else
				app_libs="$(eval printf -- '%b' \"\$${app}_LIBS\")"
			fi

			if [ "$app_type" = 'native' ]; then
				chmod +x "${pkg_path}${PATH_GAME}/$app_exe"
			fi
		fi

		# Write winecfg launcher for WINE games
		if [ "$app_type" = 'wine' ]; then
			write_bin_winecfg
		fi

		local file="${pkg_path}${PATH_BIN}/$app_id"
		mkdir --parents "${file%/*}"

		# Write launcher headers
		cat > "$file" <<- EOF
		#!/bin/sh
		# script generated by ./play.it $library_version - http://wiki.dotslashplay.it/
		set -o errexit

		EOF

		# Write launcher
		if [ "$app_type" = 'scummvm' ]; then
			write_bin_set_scummvm
		else
			# Set executable, options and libraries
			if [ "$app_id" != "${GAME_ID}_winecfg" ]; then
				cat >> "$file" <<- EOF
				# Set executable file

				APP_EXE='$app_exe'
				APP_OPTIONS="$app_options"
				export LD_LIBRARY_PATH="$app_libs:\$LD_LIBRARY_PATH"

				EOF
			fi

			# Set game path and user-writable files
			cat >> "$file" <<- EOF
			# Set game-specific variables

			GAME_ID='$GAME_ID'
			PATH_GAME='$PATH_GAME'

			CACHE_DIRS='$CACHE_DIRS'
			CACHE_FILES='$CACHE_FILES'

			CONFIG_DIRS='$CONFIG_DIRS'
			CONFIG_FILES='$CONFIG_FILES'

			DATA_DIRS='$DATA_DIRS'
			DATA_FILES='$DATA_FILES'

			EOF

			# Set user-specific directories names and paths
			cat >> "$file" <<- 'EOF'
			# Set prefix name

			[ "$PREFIX_ID" ] || PREFIX_ID="$GAME_ID"

			# Set prefix-specific variables

			[ "$XDG_CACHE_HOME" ] || XDG_CACHE_HOME="$HOME/.cache"
			[ "$XDG_CONFIG_HOME" ] || XDG_CONFIG_HOME="$HOME/.config"
			[ "$XDG_DATA_HOME" ] || XDG_DATA_HOME="$HOME/.local/share"

			PATH_CACHE="$XDG_CACHE_HOME/$PREFIX_ID"
			PATH_CONFIG="$XDG_CONFIG_HOME/$PREFIX_ID"
			PATH_DATA="$XDG_DATA_HOME/games/$PREFIX_ID"
			EOF
			if [ "$app_type" = 'wine' ]; then
				write_bin_set_wine
			else
				cat >> "$file" <<- 'EOF'
				PATH_PREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"

				EOF
			fi

			# Set generic functions
			cat >> "$file" <<- 'EOF'
			# Set ./play.it functions

			clean_userdir() {
			  cd "$PATH_PREFIX"
			  for file in $2; do
			    if [ -f "$file" ] && [ ! -f "$1/$file" ]; then
			      cp --parents "$file" "$1"
			      rm "$file"
			      ln --symbolic "$(readlink -e "$1/$file")" "$file"
			    fi
			  done
			}

			init_prefix_dirs() {
			  (
			    cd "$1"
			    for dir in $2; do
			      rm --force --recursive "$PATH_PREFIX/$dir"
			      mkdir --parents "$PATH_PREFIX/${dir%/*}"
			      if [ ! -e "$dir" ]; then
			        (
			          cd "$PATH_GAME"
			          cp --parents --recursive "$dir" "$1"
			        )
			      fi
			      ln --symbolic "$(readlink -e "$dir")" "$PATH_PREFIX/$dir"
			    done
			  )
			}

			init_prefix_files() {
			  (
			    cd "$1"
			    find . -type f | while read file; do
			      local file_prefix="$(readlink -e "$PATH_PREFIX/$file")"
			      local file_real="$(readlink -e "$file")"
			      if [ "$file_real" != "$file_prefix" ]; then
			        rm --force "$PATH_PREFIX/$file"
			        mkdir --parents "$PATH_PREFIX/${file%/*}"
			        ln --symbolic "$file_real" "$PATH_PREFIX/$file"
			      fi
			    done
			  )
			}

			init_userdir_dirs() {
			  (
			    cd "$PATH_GAME"
			    for dir in $2; do
			      if [ ! -e "$1/$dir" ] && [ -e "$dir" ]; then
			        cp --parents --recursive "$dir" "$1"
			      else
			        mkdir --parents "$1/$dir"
			      fi
			    done
			  )
			}

			init_userdir_files() {
			  (
			    cd "$PATH_GAME"
			    for file in $2; do
			      if [ ! -e "$1/$file" ] && [ -e "$file" ]; then
			        cp --parents "$file" "$1"
			      fi
			    done
			  )
			}
			EOF

			# Build user-specific directories
			cat >> "$file" <<- 'EOF'

			# Build user-writable directories

			if [ ! -e "$PATH_CACHE" ]; then
			  mkdir --parents "$PATH_CACHE"
			  init_userdir_dirs "$PATH_CACHE" "$CACHE_DIRS"
			  init_userdir_files "$PATH_CACHE" "$CACHE_FILES"
			fi

			if [ ! -e "$PATH_CONFIG" ]; then
			  mkdir --parents "$PATH_CONFIG"
			  init_userdir_dirs "$PATH_CONFIG" "$CONFIG_DIRS"
			  init_userdir_files "$PATH_CONFIG" "$CONFIG_FILES"
			fi

			if [ ! -e "$PATH_DATA" ]; then
			  mkdir --parents "$PATH_DATA"
			  init_userdir_dirs "$PATH_DATA" "$DATA_DIRS"
			  init_userdir_files "$PATH_DATA" "$DATA_FILES"
			fi

			# Build prefix

			EOF

			# Build game prefix
			if [ "$app_type" = 'wine' ]; then
				write_bin_build_wine
			fi
			cat >> "$file" <<- 'EOF'
			if [ ! -e "$PATH_PREFIX" ]; then
			  mkdir --parents "$PATH_PREFIX"
			  cp --force --recursive --symbolic-link --update "$PATH_GAME"/* "$PATH_PREFIX"
			fi
			init_prefix_files "$PATH_CACHE"
			init_prefix_files "$PATH_CONFIG"
			init_prefix_files "$PATH_DATA"
			init_prefix_dirs "$PATH_CACHE" "$CACHE_DIRS"
			init_prefix_dirs "$PATH_CONFIG" "$CONFIG_DIRS"
			init_prefix_dirs "$PATH_DATA" "$DATA_DIRS"

			EOF
		fi

		case $app_type in
			('dosbox')
				write_bin_run_dosbox
			;;
			('native')
				write_bin_run_native
			;;
			('scummvm')
				write_bin_run_scummvm
			;;
			('wine')
				write_bin_run_wine
			;;
		esac

		if [ $app_type != 'scummvm' ]; then
			cat >> "$file" <<- 'EOF'
			clean_userdir "$PATH_CACHE" "$CACHE_FILES"
			clean_userdir "$PATH_CONFIG" "$CONFIG_FILES"
			clean_userdir "$PATH_DATA" "$DATA_FILES"

			exit 0
			EOF
		fi

		sed -i 's/  /\t/g' "$file"
		chmod 755 "$file"
	done
}

# write menu entry
# USAGE: write_desktop $app[…]
# NEEDED VARS: (APP_CAT) APP_ID|GAME_ID APP_NAME|GAME_NAME APP_TYPE (LANG) PATH_DESK PKG PKG_PATH
# CALLS: liberror testvar write_desktop_winecfg
# CALLED BY: write_launcher
write_desktop() {
	local app
	for app in $@; do
		testvar "$app" 'APP' || liberror 'app' 'write_desktop'

		local app_type="$(eval printf -- '%b' \"\$${app}_TYPE\")"
		if [ "$winecfg_desktop" != 'done' ] && [ "$app_type" = 'wine' ]; then
			winecfg_desktop='done'
			write_desktop_winecfg
		fi

		local app_id
		if [ -n "$(eval printf -- '%b' \"\$${app}_ID\")" ]; then
			app_id="$(eval printf -- '%b' \"\$${app}_ID\")"
		else
			app_id="$GAME_ID"
		fi

		local app_name
		if [ -n "$(eval printf -- '%b' \"\$${app}_NAME\")" ]; then
			app_name="$(eval printf -- '%b' \"\$${app}_NAME\")"
		else
			app_name="$GAME_NAME"
		fi

		local app_cat
		if [ -n "$(eval printf -- '%b' \"\$${app}_CAT\")" ]; then
			app_cat="$(eval printf -- '%b' \"\$${app}_CAT\")"
		else
			app_cat='Game'
		fi

		local pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
		local target="${pkg_path}${PATH_DESK}/${app_id}.desktop"
		mkdir --parents "${target%/*}"
		cat > "$target" <<- EOF
		[Desktop Entry]
		Version=1.0
		Type=Application
		Name=$app_name
		Icon=$app_id
		Exec=$app_id
		Categories=$app_cat
		EOF
	done
}

# write launcher script - run the DOSBox game
# USAGE: write_bin_run_dosbox
# CALLED BY: write_bin_run
write_bin_run_dosbox() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	cd "$PATH_PREFIX"
	dosbox -c "mount c .
	c:
	EOF

	if [ "$GAME_IMAGE" ]; then
		case "$GAME_IMAGE_TYPE" in
			('cdrom')
				cat >> "$file" <<- EOF
				mount d $GAME_IMAGE -t cdrom
				EOF
			;;
			('iso'|*)
				cat >> "$file" <<- EOF
				imgmount d $GAME_IMAGE -t iso -fs iso
				EOF
			;;
		esac
	fi

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	$APP_EXE $APP_OPTIONS $@
	EOF

	if [ "$app_postrun" ]; then
		cat >> "$file" <<- EOF
		$app_postrun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	exit"

	EOF
}

# write launcher script - run the native game
# USAGE: write_bin_run_native
# CALLED BY: write_bin_run
write_bin_run_native() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	cd "$PATH_PREFIX"
	rm --force "$APP_EXE"
	if [ -e "$PATH_DATA/$APP_EXE" ]; then
	  source_dir="$PATH_DATA"
	else
	  source_dir="$PATH_GAME"
	fi
	mkdir --parents "$(dirname $APP_EXE)"
	cp "$source_dir/$APP_EXE" "$APP_EXE"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	"./$APP_EXE" $APP_OPTIONS $@

	EOF
}

# write launcher script - set ScummVM-specific common vars
# USAGE: write_bin_set_scummvm
write_bin_set_scummvm() {
	cat >> "$file" <<- EOF
	# Set game-specific variables

	GAME_ID='$GAME_ID'
	PATH_GAME='$PATH_GAME'
	SCUMMVM_ID='$(eval printf -- '%b' \"\$${app}_SCUMMID\")'

	EOF
}

# write launcher script - run the ScummVM game
# USAGE: write_bin_run_scummvm
# CALLED BY: write_bin_run
write_bin_run_scummvm() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	scummvm -p "$PATH_GAME" $APP_OPTIONS $@ $SCUMMVM_ID

	exit 0
	EOF
}

# write winecfg launcher script
# USAGE: write_bin_winecfg
# NEEDED VARS: APP_POSTRUN APP_PRERUN CACHE_DIRS CACHE_FILES CONFIG_DIRS CONFIG_FILES DATA_DIRS DATA_FILES GAME_ID (LANG) PATH_BIN PATH_GAME PKG PKG_PATH
# CALLS: write_bin
# CALLED BY: write_bin
write_bin_winecfg() {
	if [ "$winecfg_launcher" != '1' ]; then
		winecfg_launcher='1'
		APP_WINECFG_ID="${GAME_ID}_winecfg"
		APP_WINECFG_TYPE='wine'
		APP_WINECFG_EXE='winecfg'
		write_bin 'APP_WINECFG'
		local target="${pkg_path}${PATH_BIN}/$APP_WINECFG_ID"
		sed --in-place 's/# Run the game/# Run WINE configuration/' "$target"
		sed --in-place 's/cd "$PATH_PREFIX"//'                      "$target"
		sed --in-place 's/wine "$APP_EXE" $APP_OPTIONS $@/winecfg/' "$target"
	fi
}

# write launcher script - set WINE-specific prefix-specific vars
# USAGE: write_bin_set_wine
# CALLED BY: write_bin
write_bin_set_wine() {
	cat >> "$file" <<- 'EOF'
	WINEPREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
	PATH_PREFIX="$WINEPREFIX/drive_c/$GAME_ID"
	WINEARCH='win32'
	WINEDEBUG='-all'
	WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'

	EOF
}

# write launcher script - set WINE-specific user-writable directories
# USAGE: write_bin_build_wine
# NEEDED VARS: APP_WINETRICKS
# CALLED BY: write_bin
write_bin_build_wine() {
	cat >> "$file" <<- 'EOF'
	export WINEPREFIX WINEARCH WINEDEBUG WINEDLLOVERRIDES
	if ! [ -e "$WINEPREFIX" ]; then
	  mkdir --parents "$WINEPREFIX"
	  wineboot --init 2>/dev/null
	  rm "$WINEPREFIX/dosdevices/z:"
	EOF

	if [ "$APP_WINETRICKS" ]; then
		cat >> "$file" <<- EOF
		  winetricks $APP_WINETRICKS
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	fi
	EOF
}

# write launcher script - run the WINE game
# USAGE: write_bin_run_wine
# CALLED BY: write_bin
write_bin_run_wine() {
	cat >> "$file" <<- 'EOF'
	# Run the game

	cd "$PATH_PREFIX"
	EOF

	if [ "$app_prerun" ]; then
		cat >> "$file" <<- EOF
		$app_prerun
		EOF
	fi

	cat >> "$file" <<- 'EOF'
	wine "$APP_EXE" $APP_OPTIONS $@

	EOF
}

# write winecfg menu entry
# USAGE: write_desktop_winecfg
# NEEDED VARS: (LANG) PATH_DESK PKG PKG_PATH
# CALLS: write_desktop
# CALLED BY: write_desktop
write_desktop_winecfg() {
	local pkg_path="$(eval printf -- '%b' \"\$${PKG}_PATH\")"
	APP_WINECFG_ID="${GAME_ID}_winecfg"
	APP_WINECFG_NAME="$GAME_NAME - WINE configuration"
	APP_WINECFG_CAT='Settings'
	write_desktop 'APP_WINECFG'
	sed --in-place 's/Icon=.\+/Icon=winecfg/' "${pkg_path}${PATH_DESK}/${APP_WINECFG_ID}.desktop"
}

# write package meta-data
# USAGE: write_metadata [$pkg…]
# NEEDED VARS: (ARCHIVE) GAME_NAME (OPTION_PACKAGE) PACKAGES_LIST (PKG_ARCH) PKG_DEPS_ARCH PKG_DEPS_DEB PKG_DESCRIPTION PKG_ID PKG_PATH PKG_PROVIDE PKG_VERSION
# CALLS: liberror pkg_write_arch pkg_write_deb set_architecture testvar
write_metadata() {
	if [ $# = 0 ]; then
		write_metadata $PACKAGES_LIST
		return 0
	fi
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'write_metadata'

		# Set package-specific variables
		local pkg_architecture
		set_architecture "$pkg"
		local pkg_id="$(eval printf -- '%b' \"\$${pkg}_ID\")"
		local pkg_maint="$(whoami)@$(hostname)"
		local pkg_path="$(eval printf -- '%b' \"\$${pkg}_PATH\")"
		local pkg_provide="$(eval printf -- '%b' \"\$${pkg}_PROVIDE\")"

		if [ "$(eval printf -- '%b' \"\$${pkg}_DESCRIPTION_${ARCHIVE#ARCHIVE_}\")" ]; then
			pkg_description="$(eval printf -- '%b' \"\$${pkg}_DESCRIPTION_${ARCHIVE#ARCHIVE_}\")"
		else
			pkg_description="$(eval printf -- '%b' \"\$${pkg}_DESCRIPTION\")"
		fi

		if [ "$(eval printf -- '%b' \"\$${pkg}_VERSION\")" ]; then
			pkg_version="$(eval printf -- '%b' \"\$${pkg}_VERSION\")"
		else
			pkg_version="$PKG_VERSION"
		fi

		case $OPTION_PACKAGE in
			('arch')
				pkg_write_arch
			;;
			('deb')
				pkg_write_deb
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'write_metadata'
			;;
		esac
	done
}

# build .pkg.tar or .deb package
# USAGE: build_pkg [$pkg…]
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) (OPTION_PACKAGE) PACKAGES_LIST PKG_PATH PLAYIT_WORKDIR
# CALLS: liberror pkg_build_arch pkg_build_deb testvar
build_pkg() {
	if [ $# = 0 ]; then
		build_pkg $PACKAGES_LIST
		return 0
	fi
	for pkg in $@; do
		testvar "$pkg" 'PKG' || liberror 'pkg' 'build_pkg'
		local pkg_path="$(eval printf -- '%b' \"\$${pkg}_PATH\")"
		case $OPTION_PACKAGE in
			('arch')
				pkg_build_arch "$pkg_path"
			;;
			('deb')
				pkg_build_deb "$pkg_path"
			;;
			(*)
				liberror 'OPTION_PACKAGE' 'build_pkg'
			;;
		esac

		print_ok
	done
}

# print package building message
# USAGE: pkg_print $file
# NEEDED VARS: (LANG)
# CALLED BY: pkg_build_arch pkg_build_deb
pkg_print() {
	local string
	case "${LANG%_*}" in
		('fr')
			string='Construction de %s'
		;;
		('en'|*)
			string='Building %s'
		;;
	esac
	printf "$string" "$1"
}

# write .pkg.tar package meta-data
# USAGE: pkg_write_arch
# NEEDED VARS: GAME_NAME PKG_DEPS_ARCH
# CALLED BY: write_metadata
pkg_write_arch() {
	local pkg_deps
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS_ARCH_${ARCHIVE#ARCHIVE_}\")" ]; then
		pkg_deps="$(eval printf -- '%b' \"\$${pkg}_DEPS_ARCH_${ARCHIVE#ARCHIVE_}\")"
	else
		pkg_deps="$(eval printf -- '%b' \"\$${pkg}_DEPS_ARCH\")"
	fi
	local pkg_size=$(du --total --block-size=1 --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target="$pkg_path/.PKGINFO"

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	pkgname = $pkg_id
	pkgver = $pkg_version
	packager = $pkg_maint
	builddate = $(date +"%m%d%Y")
	size = $pkg_size
	arch = $pkg_architecture
	EOF

	if [ "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		pkgdesc = $GAME_NAME - $pkg_description - ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		pkgdesc = $GAME_NAME - ./play.it script version $script_version
		EOF
	fi

	for dep in $pkg_deps; do
		cat >> "$target" <<- EOF
		depend = $dep
		EOF
	done

	if [ $pkg_provide ]; then
		cat >> "$target" <<- EOF
		conflict = $pkg_provide
		provides = $pkg_provide
		EOF
	fi

	target="$pkg_path/.INSTALL"

	if [ -e "$postinst" ]; then
		cat >> "$target" <<- EOF
		post_install() {
		$(cat "$postinst")
		}

		post_upgrade() {
		post_install
		}
		EOF
	fi

	if [ -e "$prerm" ]; then
		cat >> "$target" <<- EOF
		pre_remove() {
		$(cat "$prerm")
		}

		pre_upgrade() {
		pre_remove
		}
		EOF
	fi
}

# build .pkg.tar package
# USAGE: pkg_build_arch $pkg_path
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) PLAYIT_WORKDIR
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_arch() {
	local pkg_filename="$PWD/${1##*/}.pkg.tar"
	local tar_options='--create --group=root --owner=root'

	case $OPTION_COMPRESSION in
		('gzip')
			tar_options="$tar_options --gzip"
			pkg_filename="${pkg_filename}.gz"
		;;
		('xz')
			tar_options="$tar_options --xz"
			pkg_filename="${pkg_filename}.xz"
		;;
		('none') ;;
		(*)
			liberror 'OPTION_COMPRESSION' 'pkg_build_arch'
		;;
	esac

	pkg_print "${pkg_filename##*/}"

	(
		cd "$1"
		local files='.PKGINFO *'
		if [ -e '.INSTALL' ]; then
			files=".INSTALL $files"
		fi
		tar $tar_options --file "$pkg_filename" $files
	)

	export ${pkg}_PKG="$pkg_filename"
}

# write .deb package meta-data
# USAGE: pkg_write_deb
# NEEDED VARS: GAME_NAME PKG_DEPS_DEB
# CALLED BY: write_metadata
pkg_write_deb() {
	local pkg_deps
	if [ "$(eval printf -- '%b' \"\$${pkg}_DEPS_DEB_${ARCHIVE#ARCHIVE_}\")" ]; then
		pkg_deps="$(eval printf -- '%b' \"\$${pkg}_DEPS_DEB_${ARCHIVE#ARCHIVE_}\")"
	else
		pkg_deps="$(eval printf -- '%b' \"\$${pkg}_DEPS_DEB\")"
	fi
	local pkg_size=$(du --total --block-size=1K --summarize "$pkg_path" | tail --lines=1 | cut --fields=1)
	local target="$pkg_path/DEBIAN/control"

	mkdir --parents "${target%/*}"

	cat > "$target" <<- EOF
	Package: $pkg_id
	Version: $pkg_version
	Architecture: $pkg_architecture
	Maintainer: $pkg_maint
	Installed-Size: $pkg_size
	Section: non-free/games
	EOF

	if [ "$pkg_provide" ]; then
		cat >> "$target" <<- EOF
		Conflicts: $pkg_provide
		Provides: $pkg_provide
		Replaces: $pkg_provide
		EOF
	fi

	if [ "$pkg_deps" ]; then
		cat >> "$target" <<- EOF
		Depends: $pkg_deps
		EOF
	fi

	if [ "$pkg_description" ]; then
		cat >> "$target" <<- EOF
		Description: $GAME_NAME - $pkg_description
		 ./play.it script version $script_version
		EOF
	else
		cat >> "$target" <<- EOF
		Description: $GAME_NAME
		 ./play.it script version $script_version
		EOF
	fi

	if [ "$pkg_architecture" = 'all' ]; then
		sed -i 's/Architecture: all/&\nMulti-Arch: foreign/' "$target"
	fi

	if [ -e "$postinst" ]; then
		target="$pkg_path/DEBIAN/postinst"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$postinst")

		exit 0
		EOF
		chmod 755 "$target"
	fi

	if [ -e "$prerm" ]; then
		target="$pkg_path/DEBIAN/prerm"
		cat > "$target" <<- EOF
		#!/bin/sh -e

		$(cat "$prerm")

		exit 0
		EOF
		chmod 755 "$target"
	fi
}

# build .deb package
# USAGE: pkg_build_deb $pkg_path
# NEEDED VARS: (OPTION_COMPRESSION) (LANG) PLAYIT_WORKDIR
# CALLS: pkg_print
# CALLED BY: build_pkg
pkg_build_deb() {
	local pkg_filename="$PWD/${1##*/}.deb"

	local dpkg_options
	case $OPTION_COMPRESSION in
		('gzip'|'none'|'xz')
			dpkg_options="-Z$OPTION_COMPRESSION"
		;;
		(*)
			liberror 'OPTION_COMPRESSION' 'pkg_build_deb'
		;;
	esac

	pkg_print "${pkg_filename##*/}"
	TMPDIR="$PLAYIT_WORKDIR" fakeroot -- dpkg-deb $dpkg_options --build "$1" "$pkg_filename" 1>/dev/null
	export ${pkg}_PKG="$pkg_filename"
}


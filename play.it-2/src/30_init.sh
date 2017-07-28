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


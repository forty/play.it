# print installation instructions
# USAGE: print_instructions $pkg[…]
# NEEDED VARS: PKG
print_instructions() {
	local description="$(eval echo \$${PKG}_DESC | head --lines=1)"
	case ${LANG%_*} in
		('fr')
			printf '\nInstallez %s en lançant la série de commandes suivantes en root :\n' "$description"
		;;
		('en'|*)
			printf '\nInstall %s by running the following commands as root:\n' "$description"
		;;
	esac
	case $PACKAGE_TYPE in
		('arch')
			printf 'pacman -U'
			for pkg in $@; do
				printf ' %s' "$pkg"
			done
			printf '\n'
		;;
		('deb')
			printf 'dpkg -i'
			for pkg in $@; do
				printf ' %s' "$pkg"
			done
			printf '\n'
			printf 'apt-get install -f\n'
		;;
		('tar')
			command='tar -C / -xvf'
			for pkg in $@; do
				printf 'tar -C / -xvf %s\n' "$pkg"
			done
		;;
		(*)
			liberror 'PACKAGE_TYPE' 'build_pkg'
		;;
	esac
}
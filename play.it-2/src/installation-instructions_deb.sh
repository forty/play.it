# print installation instructions for Debian
# USAGE: print_instructions_deb $pkg[…]
# CALLS: print_instructions_deb_apt print_instructions_deb_dpkg
print_instructions_deb() {
	if which apt >/dev/null 2>&1; then
		debian_version="$(apt --version | cut --delimiter=' ' --fields=2)"
		debian_version_major="$(printf '%s' "$debian_version" | cut --delimiter='.' --fields='1')"
		debian_version_minor="$(printf '%s' "$debian_version" | cut --delimiter='.' --fields='2')"
		if [ $debian_version_major -ge 2 ] ||\
		   [ $debian_version_major = 1 ] &&\
		   [ ${debian_version_minor%~*} -ge 1 ]; then
			print_instructions_deb_apt "$@"
		else
			print_instructions_deb_dpkg "$@"
		fi
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


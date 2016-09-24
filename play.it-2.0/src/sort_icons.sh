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
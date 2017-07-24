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
	export WINEARCH='win32'
	export WINEDEBUG='-all'
	export WINEDLLOVERRIDES='winemenubuilder.exe,mscoree,mshtml=d'
	export WINEPREFIX="$XDG_DATA_HOME/play.it/prefixes/$PREFIX_ID"
	# Work around WINE bug 41639
	export FREETYPE_PROPERTIES="truetype:interpreter-version=35"

	PATH_PREFIX="$WINEPREFIX/drive_c/$GAME_ID"

	EOF
}

# write launcher script - set WINE-specific user-writable directories
# USAGE: write_bin_build_wine
# NEEDED VARS: APP_WINETRICKS
# CALLED BY: write_bin
write_bin_build_wine() {
	cat >> "$file" <<- 'EOF'
	if ! [ -e "$WINEPREFIX" ]; then
	  mkdir --parents "${WINEPREFIX%/*}"
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


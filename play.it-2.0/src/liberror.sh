# display an error if a function hs been called with invalid arguments
# USAGE: liberror $var_name $calling_function
liberror() {
case ${LANG%_*} in
	fr) echo "$string_error_fr\nvaleur incorrecte pour $1 appelée par $2 : $(eval echo \$$1)" ;;
	en|*) echo "$string_error_en\ninvalid value for $1 called by $2: $(eval echo \$$1)" ;;
esac
return 1
}


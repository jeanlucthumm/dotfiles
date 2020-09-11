# Credit: Tim Friske on StackOverflow
function importIfExists() {
	if [[ ! -e "$1" ]]; then
		return 1
	fi
	local -r file="$1"
	shift
	source "$file" "$@"
}

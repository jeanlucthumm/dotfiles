case "$1" in
	"unclutter")
		if pgrep -x unclutter > /dev/null; then
			pkill unclutter
		else
			unclutter -b --timeout 0
		fi
		;;
esac

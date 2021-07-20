killall -q polybar

LOG=/tmp/polybar.log

echo "---" | tee -a $LOG
polybar default 2>&1 | tee -a $LOG & disown
echo "polybar launched"

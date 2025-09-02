# This is function for EnCorinVest
# Not much, but I need it

tweak() {
    if [ -e "$2" ]; then
        chmod 644 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
        chmod 444 "$2" >/dev/null 2>&1
    fi
}

kill_all() {
	for pkg in $(pm list packages -3 | cut -f 2 -d ":"); do
    if [ "$pkg" != "com.google.android.inputmethod.latin" ]; then
        am force-stop $pkg
    fi
done

echo 3 > /proc/sys/vm/drop_caches
am kill-all
}

bypass_on() {
    BYPASS=$(grep "^ENABLE_BYPASS=" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
    if [ "$BYPASS" = "Yes" ]; then
        sh $SCRIPT_PATH/encorin_bypass_controller.sh enable
    fi
}

bypass_off() {
    BYPASS=$(grep "^ENABLE_BYPASS=" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
    if [ "$BYPASS" = "Yes" ]; then
        sh $SCRIPT_PATH/encorin_bypass_controller.sh disable
    fi
}

notification() {
    local TITLE="EnCorinVest"
    local MESSAGE="$1"
    local LOGO="/data/local/tmp/logo.png"
    
    su -lp 2000 -c "cmd notification post -S bigtext -t '$TITLE' -i file://$LOGO -I file://$LOGO TagEncorin '$MESSAGE'"
}

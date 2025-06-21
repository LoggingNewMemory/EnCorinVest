tweak() {
    if [ -e "$2" ]; then
        chmod 644 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
        chmod 444 "$2" >/dev/null 2>&1
    fi
}

# Transsision Bypass Charging

dnd_off() {
	DND=$(grep "^DND" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
	if [ "$DND" = "Yes" ]; then
		cmd notification set_dnd off
	fi
}

dnd_on() {
	DND=$(grep "^DND" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
	if [ "$DND" = "Yes" ]; then
		cmd notification set_dnd priority
	fi
}

/sys/devices/platform/charger/bypass_charger
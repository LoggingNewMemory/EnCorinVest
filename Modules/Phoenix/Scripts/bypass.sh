tweak() {
    if [ -e "$2" ]; then
        chmod 644 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
        chmod 444 "$2" >/dev/null 2>&1
    fi
}

# Transsision Bypass Charging

# Check if bypass is supported
BYPASS_SUPPORTED=$(grep "^BYPASS_SUPPORTED" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')

if [ "$BYPASS_SUPPORTED" = "Yes" ]; then
    BYPASS_PATH=$(grep "^BYPASS_PATH" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')

    if [ -e "$BYPASS_PATH" ]; then
        BYPASS=$(grep "^BYPASS" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
        if [ "$BYPASS" = "No" ]; then
            tweak 0 "$BYPASS_PATH"
        elif [ "$BYPASS" = "Yes" ]; then
            tweak 1 "$BYPASS_PATH"
        fi
    fi
fi
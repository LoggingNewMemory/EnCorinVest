#!/system/bin/sh

# HamadaAI Next Gen Algorithm
# Target: Android 64/32 bit
# Function: Auto switch performance profiles based on detected package name

MODULE_PATH="/data/adb/modules/EnCorinVest"
GAME_LIST="$MODULE_PATH/game.txt"
SCRIPTS_PATH="$MODULE_PATH/Scripts"
PERFORMANCE_SCRIPT="$SCRIPTS_PATH/performance.sh"
BALANCED_SCRIPT="$SCRIPTS_PATH/balanced.sh"

# Initialize variables
current_package=""
previous_package=""
screen_state="on"
delay=2

# Function to get current package name
get_current_package() {
    dumpsys window | grep -E 'mCurrentFocus|mFocusedApp' | grep -o 'com\.[^/]*' | head -n 1
}

# Function to check if package is in game list
is_game_package() {
    if [ -f "$GAME_LIST" ]; then
        grep -q "$1" "$GAME_LIST"
        return $?
    fi
    return 1
}

# Function to check screen state
check_screen_state() {
    if [ "$(dumpsys power | grep 'mDisplayPowerState' | cut -d '=' -f 2 | tr -d ' ')" = "OFF" ]; then
        echo "off"
    else
        echo "on"
    fi
}

# Main loop
while true; do
    # Check screen state
    new_screen_state=$(check_screen_state)

    # If screen state changed, update delay
    if [ "$new_screen_state" != "$screen_state" ]; then
        screen_state="$new_screen_state"
        if [ "$screen_state" = "off" ]; then
            delay=5
        else
            delay=2
        fi
    fi

    # Get current package
    current_package=$(get_current_package)

    # Only process if package name changed
    if [ "$current_package" != "$previous_package" ] && [ -n "$current_package" ]; then
        # Check if the package is in game list
        if is_game_package "$current_package"; then
            # Execute performance script if exists
            if [ -f "$PERFORMANCE_SCRIPT" ]; then
                sh "$PERFORMANCE_SCRIPT"
                echo "Applied performance profile for $current_package"
            fi
        else
            # Execute balanced script if exists
            if [ -f "$BALANCED_SCRIPT" ]; then
                sh "$BALANCED_SCRIPT"
                echo "Applied balanced profile for $current_package"
            fi
        fi

        # Update previous package
        previous_package="$current_package"
    fi

    # Sleep based on current delay
    sleep $delay
done

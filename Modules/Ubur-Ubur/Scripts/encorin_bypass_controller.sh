#!/system/bin/sh

# EnCorin Bypass Controller
# Integrates rem01_bypass.sh with config management

MODULE_PATH="/data/adb/modules/EnCorinVest"
CONFIG_FILE="$MODULE_PATH/encorin.txt"
BYPASS_SCRIPT="$MODULE_PATH/Scripts/rem01_bypass.sh"

# Function to update config value
update_config() {
    local key="$1"
    local value="$2"
    
    if [ -f "$CONFIG_FILE" ]; then
        # Use sed to replace the value
        sed -i "s/^$key=.*/$key=$value/" "$CONFIG_FILE"
    else
        echo "Config file not found: $CONFIG_FILE"
        return 1
    fi
}

# Function to get config value
get_config() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        grep "^$key=" "$CONFIG_FILE" | cut -d'=' -f2
    fi
}

# Function to test bypass support
test_bypass_support() {
    echo "Testing bypass charging support..."
    
    # Run auto-detect from rem01_bypass.sh
    if [ -f "$BYPASS_SCRIPT" ]; then
        # Run the auto-detect function
        "$BYPASS_SCRIPT" auto >/dev/null 2>&1
        local result=$?
        
        if [ $result -eq 0 ]; then
            echo "Bypass charging supported"
            update_config "BYPASS_SUPPORTED" "Yes"
            return 0
        else
            echo "Bypass charging not supported"
            update_config "BYPASS_SUPPORTED" "No"
            return 1
        fi
    else
        echo "rem01_bypass.sh not found: $BYPASS_SCRIPT"
        update_config "BYPASS_SUPPORTED" "No"
        return 1
    fi
}

# Function to enable bypass charging
enable_bypass() {
    echo "Enabling bypass charging..."
    
    # Check if bypass is supported first
    local supported=$(get_config "BYPASS_SUPPORTED")
    if [ "$supported" != "Yes" ]; then
        echo "Bypass charging not supported on this device"
        return 1
    fi
    
    # Try different bypass methods until one works
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON TRANSISSION_BYPASSCHG OPLUS_EXPERIMENTAL OPLUS_COOLDOWN QCOM_SUSPEND QCOM_ENABLE_CHG GOOGLE_PIXEL HUAWEI_COMMON SAMSUNG_STORE_MODE"
    
    for method in $methods; do
        echo "Trying method: $method"
        if "$BYPASS_SCRIPT" bypass "$method" >/dev/null 2>&1; then
            echo "Bypass enabled using method: $method"
            update_config "BYPASS" "Yes"
            update_config "BYPASS_METHOD" "$method"
            return 0
        fi
    done
    
    echo "Failed to enable bypass charging"
    update_config "BYPASS" "No"
    return 1
}

# Function to disable bypass charging
disable_bypass() {
    echo "Disabling bypass charging..."
    
    local method=$(get_config "BYPASS_METHOD")
    if [ -n "$method" ]; then
        echo "Restoring normal charging using method: $method"
        "$BYPASS_SCRIPT" restore "$method" >/dev/null 2>&1
    fi
    
    update_config "BYPASS" "No"
    echo "Bypass charging disabled"
}

# Function to check current bypass status
check_status() {
    echo "=== EnCorin Bypass Status ==="
    echo "Bypass Supported: $(get_config "BYPASS_SUPPORTED")"
    echo "Bypass Enabled: $(get_config "BYPASS")"
    echo "Bypass Method: $(get_config "BYPASS_METHOD")"
    echo "=========================="
}

# Show usage
show_usage() {
    echo "Usage: $0 [test|enable|disable|status]"
    echo ""
    echo "Commands:"
    echo "  test    - Test bypass support and update config"
    echo "  enable  - Enable bypass charging"
    echo "  disable - Disable bypass charging"
    echo "  status  - Show current bypass status"
    echo ""
    echo "Examples:"
    echo "  $0 test"
    echo "  $0 enable"
    echo "  $0 disable"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Main execution
case "$1" in
    "test")
        test_bypass_support
        ;;
    "enable")
        enable_bypass
        ;;
    "disable")
        disable_bypass
        ;;
    "status")
        check_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
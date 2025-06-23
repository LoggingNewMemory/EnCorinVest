#!/system/bin/sh

# EnCorin Bypass Controller
# Enhanced version that adapts to rem01_bypass.sh structure

MODULE_PATH="/data/adb/modules/EnCorinVest"
CONFIG_FILE="$MODULE_PATH/encorin.txt"
BYPASS_SCRIPT="$MODULE_PATH/Scripts/rem01_bypass.sh"

# Source the bypass script to get all the constants
if [ -f "$BYPASS_SCRIPT" ]; then
    . "$BYPASS_SCRIPT"
else
    echo "Error: rem01_bypass.sh not found at $BYPASS_SCRIPT"
    exit 1
fi

# Function to update config value
update_config() {
    local key="$1"
    local value="$2"
    
    if [ -f "$CONFIG_FILE" ]; then
        # Create backup
        cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
        # Use sed to replace the value, or add if doesn't exist
        if grep -q "^$key=" "$CONFIG_FILE"; then
            sed -i "s/^$key=.*/$key=$value/" "$CONFIG_FILE"
        else
            echo "$key=$value" >> "$CONFIG_FILE"
        fi
    else
        # Create config file if it doesn't exist
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "$key=$value" > "$CONFIG_FILE"
    fi
}

# Function to get config value
get_config() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        grep "^$key=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | head -1
    fi
}

# Function to write to node with error handling
write_node() {
    local node="$1"
    local value="$2"
    
    if [ -w "$node" ]; then
        echo "$value" > "$node" 2>/dev/null
        return $?
    fi
    return 1
}

# Function to read from node
read_node() {
    local node="$1"
    
    if [ -r "$node" ]; then
        cat "$node" 2>/dev/null
    fi
}

# Function to test a specific bypass method
test_bypass_method() {
    local method="$1"
    local found_nodes=0
    local working_nodes=0
    
    case "$method" in
        "OPLUS_MMI")
            for node in "${OPLUS_MMI_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "TRANSISSION_BYPASSCHG")
            for node in "${TRANSISSION_BYPASSCHG_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "SUSPEND_COMMON")
            for node in "${SUSPEND_COMMON_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "CONTROL_COMMON")
            for node in "${CONTROL_COMMON_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "DISABLE_COMMON")
            for node in "${DISABLE_COMMON_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "GOOGLE_PIXEL")
            for node in "${GOOGLE_PIXEL_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "SAMSUNG_STORE_MODE")
            for node in "${SAMSUNG_STORE_MODE_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "QCOM_SUSPEND")
            for node in "${QCOM_SUSPEND_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
        "HUAWEI_COMMON")
            for node in "${HUAWEI_COMMON_NODES[@]}"; do
                if [ -e "$node" ]; then
                    found_nodes=$((found_nodes + 1))
                    if [ -w "$node" ]; then
                        working_nodes=$((working_nodes + 1))
                    fi
                fi
            done
            ;;
    esac
    
    if [ $working_nodes -gt 0 ]; then
        return 0  # Method supported
    else
        return 1  # Method not supported
    fi
}

# Function to apply bypass for a specific method
apply_bypass_method() {
    local method="$1"
    local action="$2"  # "bypass" or "restore"
    local success=0
    
    case "$method" in
        "OPLUS_MMI")
            for node in "${OPLUS_MMI_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$OPLUS_MMI_BYPASS" && success=1
                    else
                        write_node "$node" "$OPLUS_MMI_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "TRANSISSION_BYPASSCHG")
            for node in "${TRANSISSION_BYPASSCHG_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$TRANSISSION_BYPASSCHG_BYPASS" && success=1
                    else
                        write_node "$node" "$TRANSISSION_BYPASSCHG_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "SUSPEND_COMMON")
            for node in "${SUSPEND_COMMON_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$SUSPEND_COMMON_BYPASS" && success=1
                    else
                        write_node "$node" "$SUSPEND_COMMON_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "CONTROL_COMMON")
            for node in "${CONTROL_COMMON_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$CONTROL_COMMON_BYPASS" && success=1
                    else
                        write_node "$node" "$CONTROL_COMMON_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "DISABLE_COMMON")
            local i=0
            for node in "${DISABLE_COMMON_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "${DISABLE_COMMON_BYPASS_VALS[$i]}" && success=1
                    else
                        write_node "$node" "${DISABLE_COMMON_NORMAL_VALS[$i]}" && success=1
                    fi
                fi
                i=$((i + 1))
            done
            ;;
        "GOOGLE_PIXEL")
            for node in "${GOOGLE_PIXEL_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$GOOGLE_PIXEL_BYPASS" && success=1
                    else
                        write_node "$node" "$GOOGLE_PIXEL_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "SAMSUNG_STORE_MODE")
            for node in "${SAMSUNG_STORE_MODE_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$SAMSUNG_STORE_MODE_BYPASS" && success=1
                    else
                        write_node "$node" "$SAMSUNG_STORE_MODE_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "QCOM_SUSPEND")
            for node in "${QCOM_SUSPEND_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$QCOM_SUSPEND_BYPASS" && success=1
                    else
                        write_node "$node" "$QCOM_SUSPEND_NORMAL" && success=1
                    fi
                fi
            done
            ;;
        "HUAWEI_COMMON")
            for node in "${HUAWEI_COMMON_NODES[@]}"; do
                if [ -w "$node" ]; then
                    if [ "$action" = "bypass" ]; then
                        write_node "$node" "$HUAWEI_COMMON_BYPASS" && success=1
                    else
                        write_node "$node" "$HUAWEI_COMMON_NORMAL" && success=1
                    fi
                fi
            done
            ;;
    esac
    
    return $success
}

# Function to test bypass support
test_bypass_support() {
    echo "Testing bypass charging support..."
    
    # List of methods to test (ordered by common usage)
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    local supported_methods=""
    local count=0
    
    for method in $methods; do
        echo "Testing method: $method"
        if test_bypass_method "$method"; then
            echo "  ✓ $method - Supported"
            supported_methods="$supported_methods $method"
            count=$((count + 1))
        else
            echo "  ✗ $method - Not supported"
        fi
    done
    
    if [ $count -gt 0 ]; then
        echo ""
        echo "Found $count supported bypass method(s)"
        update_config "BYPASS_SUPPORTED" "Yes"
        update_config "SUPPORTED_METHODS" "$supported_methods"
        # Set the first supported method as default
        local first_method=$(echo $supported_methods | awk '{print $1}')
        update_config "DEFAULT_METHOD" "$first_method"
        return 0
    else
        echo ""
        echo "No bypass methods supported on this device"
        update_config "BYPASS_SUPPORTED" "No"
        update_config "SUPPORTED_METHODS" ""
        return 1
    fi
}

# Function to enable bypass charging
enable_bypass() {
    # Check if bypass is supported first
    local supported=$(get_config "BYPASS_SUPPORTED")
    if [ "$supported" != "Yes" ]; then
        return 1
    fi
    
    # Get supported methods
    local methods=$(get_config "SUPPORTED_METHODS")
    if [ -z "$methods" ]; then
        return 1
    fi
    
    # Try each supported method until one works
    for method in $methods; do
        if apply_bypass_method "$method" "bypass"; then
            update_config "BYPASS" "Yes"
            update_config "ACTIVE_METHOD" "$method"
            return 0
        fi
    done
    
    update_config "BYPASS" "No"
    return 1
}

# Function to disable bypass charging
disable_bypass() {
    local method=$(get_config "ACTIVE_METHOD")
    if [ -z "$method" ]; then
        # Try to restore all supported methods just in case
        local methods=$(get_config "SUPPORTED_METHODS")
        if [ -n "$methods" ]; then
            for m in $methods; do
                apply_bypass_method "$m" "restore"
            done
        fi
    else
        apply_bypass_method "$method" "restore"
    fi
    
    update_config "BYPASS" "No"
    update_config "ACTIVE_METHOD" ""
}



# Show usage
show_usage() {
    echo "Usage: $0 [test|enable|disable]"
    echo ""
    echo "Commands:"
    echo "  test    - Test bypass support and detect available methods"
    echo "  enable  - Enable bypass charging"
    echo "  disable - Disable bypass charging"
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
    *)
        show_usage
        exit 1
        ;;
esac
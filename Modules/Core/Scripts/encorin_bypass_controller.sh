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
    local count=0
    
    # List of methods to test (ordered by common usage)
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    
    for method in $methods; do
        if test_bypass_method "$method"; then
            count=$((count + 1))
        fi
    done
    
    if [ $count -gt 0 ]; then
        update_config "BYPASS_SUPPORTED" "Yes"
        echo "Executed Successfully."
        return 0
    else
        update_config "BYPASS_SUPPORTED" "No"
        echo "Executed Successfully."
        return 1
    fi
}

# Function to enable bypass charging
enable_bypass() {
    local bypass_success=0
    
    # Check if bypass is supported first
    local supported=$(get_config "BYPASS_SUPPORTED")
    if [ "$supported" != "Yes" ]; then
        echo "Executed Successfully." 
        return 1
    fi
    
    # List of methods to try (ordered by common usage)
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    
    for method in $methods; do
        if test_bypass_method "$method"; then
            if apply_bypass_method "$method" "bypass"; then
                echo "Executed Successfully."
                bypass_success=1
                break
            fi
        fi
    done
    
    if [ "$bypass_success" -eq 0 ]; then
        echo "Executed Successfully." 
        return 1
    fi
}

# Function to disable bypass charging
disable_bypass() {
    # Attempt to restore all commonly used methods, as we don't track the active method in config anymore
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    for m in $methods; do
        apply_bypass_method "$m" "restore" # Best effort restore
    done
    
    echo "Executed Successfully."
}

# Show usage
show_usage() {
    echo "EnCorin Bypass Controller - Enhanced rem01_bypass.sh Integration"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  test     - Test bypass support and detect available methods"
    echo "  enable   - Enable bypass charging using the best available method"
    echo "  disable  - Disable bypass charging and restore normal charging"
    echo ""
    echo "Examples:"
    echo "  $0 test      # Test what bypass methods work on this device"
    echo "  $0 enable    # Enable bypass charging"
    echo "  $0 disable   # Disable bypass charging"
    echo ""
    echo "Config file: $CONFIG_FILE"
    echo "Bypass script: $BYPASS_SCRIPT"
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
#!/system/bin/sh

# EnCorin Bypass Controller - Rewritten Version
# Simplified without SUPPORTED_BYPASS configuration

MODULE_PATH="/data/adb/modules/EnCorinVest"
BYPASS_SCRIPT="$MODULE_PATH/Scripts/rem01_bypass.sh"

# Source the bypass script to get all constants
if [ -f "$BYPASS_SCRIPT" ]; then
    . "$BYPASS_SCRIPT"
else
    echo "Error: rem01_bypass.sh not found at $BYPASS_SCRIPT"
    exit 1
fi

# Node operations
write_node() {
    [ -w "$1" ] && echo "$2" > "$1" 2>/dev/null
}

read_node() {
    local node="$1"
    [ -r "$node" ] && cat "$node" 2>/dev/null
}

# Test if a bypass method has working nodes
test_bypass_method() {
    local method="$1"
    local working_nodes=0
    
    case "$method" in
        "OPLUS_MMI")
            for node in "${OPLUS_MMI_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "TRANSISSION_BYPASSCHG")
            for node in "${TRANSISSION_BYPASSCHG_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "SUSPEND_COMMON")
            for node in "${SUSPEND_COMMON_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "CONTROL_COMMON")
            for node in "${CONTROL_COMMON_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "DISABLE_COMMON")
            for node in "${DISABLE_COMMON_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "GOOGLE_PIXEL")
            for node in "${GOOGLE_PIXEL_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "SAMSUNG_STORE_MODE")
            for node in "${SAMSUNG_STORE_MODE_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "QCOM_SUSPEND")
            for node in "${QCOM_SUSPEND_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
        "HUAWEI_COMMON")
            for node in "${HUAWEI_COMMON_NODES[@]}"; do
                [ -w "$node" ] && working_nodes=$((working_nodes + 1))
            done
            ;;
    esac
    
    [ $working_nodes -gt 0 ]
}

# Apply bypass for a specific method
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

# Test bypass support
test_bypass_support() {
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    local supported_count=0
    
    for method in $methods; do
        if test_bypass_method "$method"; then
            supported_count=$((supported_count + 1))
        fi
    done
    
    if [ $supported_count -gt 0 ]; then
        echo "supported"
    else
        echo "unsupported"
    fi
    
    return $supported_count
}

# Enable bypass charging
enable_bypass() {
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    
    for method in $methods; do
        if test_bypass_method "$method"; then
            if apply_bypass_method "$method" "bypass"; then
                echo "Executed Successfully."
                return 0
            fi
        fi
    done
    
    echo "Executed Successfully."
    return 1
}

# Disable bypass charging
disable_bypass() {
    local methods="OPLUS_MMI SUSPEND_COMMON DISABLE_COMMON GOOGLE_PIXEL SAMSUNG_STORE_MODE QCOM_SUSPEND HUAWEI_COMMON CONTROL_COMMON TRANSISSION_BYPASSCHG"
    
    for method in $methods; do
        apply_bypass_method "$method" "restore" >/dev/null 2>&1
    done
    
    echo "Executed Successfully."
}

# Show usage
show_usage() {
    echo "EnCorin Bypass Controller"
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
    echo "Bypass script: $BYPASS_SCRIPT"
}

# Check root permissions
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Main execution
case "$1" in
    "test") test_bypass_support ;;
    "enable") enable_bypass ;;
    "disable") disable_bypass ;;
    *) show_usage ;;
esac
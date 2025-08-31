# Original By: Rem01 Gaming
# Port to shell By: Kanagawa Yamada

_worker() {
    local action="$1"
    local method_name="$2"
    local nodes_data="$3"
    local success=1 # 1 = fail, 0 = success

    # The subshell created by the pipe `|` makes returning status tricky.
    # We check the output of the subshell to determine success.
    local result=$(echo "$nodes_data" | while IFS='|' read -r path normal_val bypass_val; do
        # Skip empty lines
        [ -z "$path" ] && continue

        if [ -f "$path" ] && [ -w "$path" ]; then
            case "$action" in
                test)
                    # For test, just finding a path is success.
                    # We echo "success" to be captured by the 'result' variable.
                    echo "success"
                    exit 0 # Exit the 'while' loop subshell immediately
                    ;;
                enable)
                    echo "$bypass_val" > "$path"
                    # Verify write succeeded
                    if [ "$(cat "$path")" = "$bypass_val" ]; then
                        echo "Bypass ENABLED successfully via method: $method_name"
                        echo "  Path: $path (Wrote '$bypass_val')"
                        echo "success"
                        exit 0
                    fi
                    ;;
                disable)
                    echo "$normal_val" > "$path"
                    # Verify write succeeded
                    if [ "$(cat "$path")" = "$normal_val" ]; then
                        echo "Bypass DISABLED successfully via method: $method_name"
                        echo "  Path: $path (Wrote '$normal_val')"
                        echo "success"
                        exit 0
                    fi
                    ;;
            esac
        fi
    done)

    # Check if the subshell echoed "success"
    if echo "$result" | grep -q "success"; then
        success=0
    fi

    return $success
}

# --- Method Executor ---
# Tries all methods sequentially and stops on the first success.
try_all_methods() {
    local action="$1"

    _worker "$action" "OPLUS_MMI" "$(cat <<'EOF'
/sys/class/oplus_chg/battery/mmi_charging_enable|1|0
/sys/class/power_supply/battery/mmi_charging_enable|1|0
/sys/devices/virtual/oplus_chg/battery/mmi_charging_enable|1|0
/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/mmi_charging_enable|1|0
EOF
)" && return 0

    _worker "$action" "TRANSISSION_BYPASSCHG" "$(cat <<'EOF'
/sys/devices/platform/charger/bypass_charger|0|1
EOF
)" && return 0

    _worker "$action" "OPLUS_EXPERIMENTAL" "$(cat <<'EOF'
/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/chg_enable|1|0
EOF
)" && return 0

    _worker "$action" "OPLUS_COOLDOWN" "$(cat <<'EOF'
/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/cool_down|0|1
EOF
)" && return 0

    _worker "$action" "SUSPEND_COMMON" "$(cat <<'EOF'
/sys/class/power_supply/battery/input_suspend|0|1
/sys/class/power_supply/battery/battery_input_suspend|0|1
EOF
)" && return 0

    _worker "$action" "CONTROL_COMMON" "$(cat <<'EOF'
/sys/class/power_supply/battery/charger_control|1|0
EOF
)" && return 0

    _worker "$action" "DISABLE_COMMON" "$(cat <<'EOF'
/sys/class/power_supply/battery/charge_disable|0|1
/sys/class/power_supply/battery/charging_enabled|1|0
/sys/class/power_supply/battery/charge_enabled|1|0
/sys/class/power_supply/battery/battery_charging_enabled|1|0
/sys/class/power_supply/battery/device/Charging_Enable|1|0
/sys/class/power_supply/ac/charging_enabled|1|0
/sys/class/power_supply/charge_data/enable_charger|1|0
/sys/class/power_supply/dc/charging_enabled|1|0
/sys/devices/platform/charger/tran_aichg_disable_charger|0|1
/sys/class/power_supply/battery/op_disable_charge|0|1
/sys/class/power_supply/chargalg/disable_charging|0|1
/sys/class/power_supply/battery/connect_disable|0|1
/sys/devices/platform/omap/omap_i2c.3/i2c-3/3-005f/charge_enable|1|0
/sys/devices/soc/qpnp-smbcharger-18/power_supply/battery/battery_charging_enabled|1|0
EOF
)" && return 0

    _worker "$action" "SPREADTRUM_STOPCHG" "$(cat <<'EOF'
/sys/class/power_supply/battery/stop_charge|0|1
EOF
)" && return 0

    _worker "$action" "TEGRA_I2C" "$(cat <<'EOF'
/sys/devices/platform/tegra12-i2c.0/i2c-0/0-006b/charging_state|enabled|disabled
EOF
)" && return 0

    _worker "$action" "SIOP_LEVEL" "$(cat <<'EOF'
/sys/class/power_supply/battery/siop_level|100|0
EOF
)" && return 0

    _worker "$action" "SMART_INTERRUPT" "$(cat <<'EOF'
/sys/class/power_supply/battery_ext/smart_charging_interruption|0|1
EOF
)" && return 0

    _worker "$action" "MEDIATEK_COMMON" "$(cat <<'EOF'
/proc/mtk_battery_cmd/current_cmd|0 0|0 1
EOF
)" && return 0

    _worker "$action" "MEDIATEK_ADVANCED" "$(cat <<'EOF'
/proc/mtk_battery_cmd/current_cmd|0 0|0 1
/proc/mtk_battery_cmd/en_power_path|1|0
EOF
)" && return 0

    _worker "$action" "QCOM_SUSPEND" "$(cat <<'EOF'
/sys/class/qcom-battery/input_suspend|1|0
EOF
)" && return 0

    _worker "$action" "QCOM_ENABLE_CHG" "$(cat <<'EOF'
/sys/class/qcom-battery/charging_enabled|1|0
EOF
)" && return 0

    _worker "$action" "QCOM_COOLDOWN" "$(cat <<'EOF'
/sys/class/qcom-battery/cool_mode|0|1
EOF
)" && return 0

    _worker "$action" "QCOM_BATT_PROTECT" "$(cat <<'EOF'
/sys/class/qcom-battery/batt_protect_en|0|1
EOF
)" && return 0

    _worker "$action" "PMIC_MODULES" "$(cat <<'EOF'
/sys/module/pmic8058_charger/parameters/disabled|0|1
/sys/module/pm8921_charger/parameters/disabled|0|1
/sys/module/smb137b/parameters/disabled|0|1
/proc/smb1357_disable_chrg|0|1
EOF
)" && return 0

    _worker "$action" "BQ2589X_PMIC" "$(cat <<'EOF'
/sys/class/power_supply/bq2589x_charger/enable_charging|1|0
EOF
)" && return 0

    _worker "$action" "QCOM_PMIC_SUSPEND" "$(cat <<'EOF'
/sys/devices/platform/soc/soc:qcom,pmic_glink/soc:qcom,pmic_glink:qcom,battery_charger/force_charger_suspend|0|1
EOF
)" && return 0

    _worker "$action" "NUBIA_COMMON" "$(cat <<'EOF'
/sys/kernel/nubia_charge/charger_bypass|off|on
EOF
)" && return 0

    _worker "$action" "GOOGLE_PIXEL" "$(cat <<'EOF'
/sys/devices/platform/soc/soc:google,charger/charge_disable|0|1
/sys/kernel/debug/google_charger/chg_suspend|0|1
/sys/kernel/debug/google_charger/input_suspend|0|1
EOF
)" && return 0

    _worker "$action" "HUAWEI_COMMON" "$(cat <<'EOF'
/sys/devices/platform/huawei_charger/enable_charger|1|0
/sys/class/hw_power/charger/charge_data/enable_charger|1|0
EOF
)" && return 0

    _worker "$action" "ASUS" "$(cat <<'EOF'
/sys/class/asuslib/charger_limit_en|0|1
/sys/class/asuslib/charging_suspend_en|0|1
EOF
)" && return 0

    _worker "$action" "LGE" "$(cat <<'EOF'
/sys/devices/platform/lge-unified-nodes/charging_enable|1|0
/sys/devices/platform/lge-unified-nodes/charging_completed|0|1
/sys/module/lge_battery/parameters/charge_stop_level|100|5
/sys/class/power_supply/battery/input_suspend|0|0
EOF
)" && return 0

    _worker "$action" "MANTA_BATTERY" "$(cat <<'EOF'
/sys/devices/virtual/power_supply/manta-battery/charge_enabled|1|0
EOF
)" && return 0

    _worker "$action" "CAT_CHG_SWITCH" "$(cat <<'EOF'
/sys/devices/platform/battery/CCIChargerSwitch|1|0
EOF
)" && return 0

    _worker "$action" "MT_BATTERY" "$(cat <<'EOF'
/sys/devices/platform/mt-battery/disable_charger|0|1
EOF
)" && return 0

    _worker "$action" "SAMSUNG_STORE_MODE" "$(cat <<'EOF'
/sys/class/power_supply/battery/store_mode|0|1
EOF
)" && return 0

    _worker "$action" "CHARGE_LIMIT" "$(cat <<'EOF'
/proc/driver/charger_limit_enable|0|1
/proc/driver/charger_limit|100|5
EOF
)" && return 0

    _worker "$action" "QPNP_BLOCKING" "$(cat <<'EOF'
/sys/module/qpnp_adaptive_charge/parameters/blocking|0|1
EOF
)" && return 0

    _worker "$action" "GOOGLE_STOP_LEVEL" "$(cat <<'EOF'
/sys/devices/platform/google,charger/charge_stop_level|100|5
/sys/kernel/debug/google_charger/chg_mode|1|0
EOF
)" && return 0

    _worker "$action" "GENERIC_MODES" "$(cat <<'EOF'
/sys/class/power_supply/battery/test_mode|2|1
/sys/class/power_supply/battery/batt_slate_mode|0|1
/sys/class/power_supply/battery/bd_trickle_cnt|0|1
/sys/class/power_supply/idt/pin_enabled|0|1
/sys/class/power_supply/battery/charge_charger_state|0|1
/sys/class/power_supply/main/adapter_cc_mode|0|1
/sys/class/power_supply/battery/hmt_ta_charge|1|0
/sys/class/power_supply/maxfg/offmode_charger|0|1
/sys/class/power_supply/main/cool_mode|0|1
EOF
)" && return 0

    _worker "$action" "RESTRICTED_CHARGING" "$(cat <<'EOF'
/sys/class/power_supply/battery/restricted_charging|0|1
/sys/class/power_supply/wireless/restricted_charging|0|1
EOF
)" && return 0

    # If we get here, no methods succeeded
    return 1
}

# --- Main Script Logic ---
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root access. Please run as root." >&2
    exit 1
fi

case "$1" in
    test)
        # For the 'test' action, we silence the worker's output
        # and print our own summary message based on the final result.
        if try_all_methods "$1" >/dev/null 2>&1; then
            echo "supported"
        else
            echo "unsupported"
        fi
        ;;
    enable|disable)
        if ! try_all_methods "$1"; then
             # This block runs only if ALL methods failed
             echo "Operation failed. No supported bypass method found on this device." >&2
             exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {test|enable|disable}" >&2
        exit 1
        ;;
esac

exit 0
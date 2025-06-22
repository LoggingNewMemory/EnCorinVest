#!/system/bin/sh
# Very huge thanks to Rem01 Gaming for this

# Function to check if file exists and is writable
check_node() {
    local path="$1"
    if [ -e "$path" ] && [ -w "$path" ]; then
        return 0
    fi
    return 1
}

# Function to write value to node
write_node() {
    local path="$1"
    local value="$2"
    if check_node "$path"; then
        echo "$value" > "$path" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✓ $path = $value"
            return 0
        else
            echo "✗ Failed to write to $path"
        fi
    fi
    return 1
}

# Function to apply bypass settings for a specific part
apply_bypass() {
    local part="$1"
    local success=0
    
    case "$part" in
        "OPLUS_MMI")
            echo "Applying OPLUS MMI bypass..."
            write_node "/sys/class/oplus_chg/battery/mmi_charging_enable" "0" && success=1
            write_node "/sys/class/power_supply/battery/mmi_charging_enable" "0" && success=1
            write_node "/sys/devices/virtual/oplus_chg/battery/mmi_charging_enable" "0" && success=1
            write_node "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/mmi_charging_enable" "0" && success=1
            ;;
        "TRANSISSION_BYPASSCHG")
            echo "Applying Transission bypass charging..."
            write_node "/sys/devices/platform/charger/bypass_charger" "1" && success=1
            ;;
        "OPLUS_EXPERIMENTAL")
            echo "Applying OPLUS experimental bypass..."
            write_node "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/chg_enable" "0" && success=1
            ;;
        "OPLUS_COOLDOWN")
            echo "Applying OPLUS cooldown..."
            write_node "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/cool_down" "1" && success=1
            ;;
        "SUSPEND_COMMON")
            echo "Applying suspend common..."
            write_node "/sys/class/power_supply/battery/input_suspend" "1" && success=1
            write_node "/sys/class/power_supply/battery/battery_input_suspend" "1" && success=1
            ;;
        "CONTROL_COMMON")
            echo "Applying control common..."
            write_node "/sys/class/power_supply/battery/charger_control" "0" && success=1
            ;;
        "DISABLE_COMMON")
            echo "Applying disable common..."
            write_node "/sys/class/power_supply/battery/charge_disable" "1" && success=1
            write_node "/sys/class/power_supply/battery/charging_enabled" "0" && success=1
            write_node "/sys/class/power_supply/battery/charge_enabled" "0" && success=1
            write_node "/sys/class/power_supply/battery/battery_charging_enabled" "0" && success=1
            write_node "/sys/class/power_supply/battery/device/Charging_Enable" "0" && success=1
            write_node "/sys/class/power_supply/ac/charging_enabled" "0" && success=1
            write_node "/sys/class/power_supply/charge_data/enable_charger" "0" && success=1
            write_node "/sys/class/power_supply/dc/charging_enabled" "0" && success=1
            write_node "/sys/devices/platform/charger/tran_aichg_disable_charger" "1" && success=1
            write_node "/sys/class/power_supply/battery/op_disable_charge" "1" && success=1
            write_node "/sys/class/power_supply/chargalg/disable_charging" "1" && success=1
            write_node "/sys/class/power_supply/battery/connect_disable" "1" && success=1
            write_node "/sys/devices/platform/omap/omap_i2c.3/i2c-3/3-005f/charge_enable" "0" && success=1
            write_node "/sys/devices/soc/qpnp-smbcharger-18/power_supply/battery/battery_charging_enabled" "0" && success=1
            ;;
        "SPREADTRUM_STOPCHG")
            echo "Applying Spreadtrum stop charging..."
            write_node "/sys/class/power_supply/battery/stop_charge" "1" && success=1
            ;;
        "TEGRA_I2C")
            echo "Applying Tegra I2C..."
            write_node "/sys/devices/platform/tegra12-i2c.0/i2c-0/0-006b/charging_state" "disabled" && success=1
            ;;
        "SIOP_LEVEL")
            echo "Applying SIOP level..."
            write_node "/sys/class/power_supply/battery/siop_level" "0" && success=1
            ;;
        "SMART_INTERRUPT")
            echo "Applying smart interrupt..."
            write_node "/sys/class/power_supply/battery_ext/smart_charging_interruption" "1" && success=1
            ;;
        "MEDIATEK_COMMON")
            echo "Applying MediaTek common..."
            write_node "/proc/mtk_battery_cmd/current_cmd" "0 1" && success=1
            ;;
        "MEDIATEK_ADVANCED")
            echo "Applying MediaTek advanced..."
            write_node "/proc/mtk_battery_cmd/current_cmd" "0 1" && success=1
            write_node "/proc/mtk_battery_cmd/en_power_path" "0" && success=1
            ;;
        "QCOM_SUSPEND")
            echo "Applying Qualcomm suspend..."
            write_node "/sys/class/qcom-battery/input_suspend" "0" && success=1
            ;;
        "QCOM_ENABLE_CHG")
            echo "Applying Qualcomm enable charging..."
            write_node "/sys/class/qcom-battery/charging_enabled" "0" && success=1
            ;;
        "QCOM_COOLDOWN")
            echo "Applying Qualcomm cooldown..."
            write_node "/sys/class/qcom-battery/cool_mode" "1" && success=1
            ;;
        "QCOM_BATT_PROTECT")
            echo "Applying Qualcomm battery protect..."
            write_node "/sys/class/qcom-battery/batt_protect_en" "1" && success=1
            ;;
        "PM8058_PMIC")
            echo "Applying PM8058 PMIC..."
            write_node "/sys/module/pmic8058_charger/parameters/disabled" "1" && success=1
            ;;
        "PM8921_PMIC")
            echo "Applying PM8921 PMIC..."
            write_node "/sys/module/pm8921_charger/parameters/disabled" "1" && success=1
            ;;
        "SMB137B_PMIC")
            echo "Applying SMB137B PMIC..."
            write_node "/sys/module/smb137b/parameters/disabled" "1" && success=1
            ;;
        "SMB1357_PMIC")
            echo "Applying SMB1357 PMIC..."
            write_node "/proc/smb1357_disable_chrg" "1" && success=1
            ;;
        "BQ2589X_PMIC")
            echo "Applying BQ2589X PMIC..."
            write_node "/sys/class/power_supply/bq2589x_charger/enable_charging" "0" && success=1
            ;;
        "QCOM_PMIC_SUSPEND")
            echo "Applying Qualcomm PMIC suspend..."
            write_node "/sys/devices/platform/soc/soc:qcom,pmic_glink/soc:qcom,pmic_glink:qcom,battery_charger/force_charger_suspend" "1" && success=1
            ;;
        "NUBIA_COMMON")
            echo "Applying Nubia common..."
            write_node "/sys/kernel/nubia_charge/charger_bypass" "on" && success=1
            ;;
        "GOOGLE_PIXEL")
            echo "Applying Google Pixel..."
            write_node "/sys/devices/platform/soc/soc:google,charger/charge_disable" "1" && success=1
            write_node "/sys/kernel/debug/google_charger/chg_suspend" "1" && success=1
            write_node "/sys/kernel/debug/google_charger/input_suspend" "1" && success=1
            ;;
        "HUAWEI_COMMON")
            echo "Applying Huawei common..."
            write_node "/sys/devices/platform/huawei_charger/enable_charger" "0" && success=1
            write_node "/sys/class/hw_power/charger/charge_data/enable_charger" "0" && success=1
            ;;
        "ASUS_LIMIT")
            echo "Applying ASUS limit..."
            write_node "/sys/class/asuslib/charger_limit_en" "1" && success=1
            ;;
        "ASUS_SUSPEND")
            echo "Applying ASUS suspend..."
            write_node "/sys/class/asuslib/charging_suspend_en" "1" && success=1
            ;;
        "LGE_COMMON")
            echo "Applying LG common..."
            write_node "/sys/devices/platform/lge-unified-nodes/charging_enable" "0" && success=1
            ;;
        "LGE_CHG_COMPLETED")
            echo "Applying LG charging completed..."
            write_node "/sys/devices/platform/lge-unified-nodes/charging_completed" "1" && success=1
            ;;
        "LGE_CHG_LEVEL")
            echo "Applying LG charging level..."
            write_node "/sys/module/lge_battery/parameters/charge_stop_level" "5" && success=1
            write_node "/sys/class/power_supply/battery/input_suspend" "0" && success=1
            ;;
        "MANTA_BATTERY")
            echo "Applying Manta battery..."
            write_node "/sys/devices/virtual/power_supply/manta-battery/charge_enabled" "0" && success=1
            ;;
        "CAT_CHG_SWITCH")
            echo "Applying CAT charging switch..."
            write_node "/sys/devices/platform/battery/CCIChargerSwitch" "0" && success=1
            ;;
        "MT_BATTERY")
            echo "Applying MT battery..."
            write_node "/sys/devices/platform/mt-battery/disable_charger" "1" && success=1
            ;;
        "SAMSUNG_STORE_MODE")
            echo "Applying Samsung store mode..."
            write_node "/sys/class/power_supply/battery/store_mode" "1" && success=1
            ;;
        "CHARGE_LIMIT")
            echo "Applying charge limit..."
            write_node "/proc/driver/charger_limit_enable" "1" && success=1
            write_node "/proc/driver/charger_limit" "5" && success=1
            ;;
        "QPNP_BLOCKING")
            echo "Applying QPNP blocking..."
            write_node "/sys/module/qpnp_adaptive_charge/parameters/blocking" "1" && success=1
            ;;
        "GOOGLE_STOP_LEVEL")
            echo "Applying Google stop level..."
            write_node "/sys/devices/platform/google,charger/charge_stop_level" "5" && success=1
            ;;
        "GOOGLE_CHG_MODE")
            echo "Applying Google charging mode..."
            write_node "/sys/kernel/debug/google_charger/chg_mode" "0" && success=1
            ;;
        "TEST_MODE")
            echo "Applying test mode..."
            write_node "/sys/class/power_supply/battery/test_mode" "1" && success=1
            ;;
        "SLATE_MODE")
            echo "Applying slate mode..."
            write_node "/sys/class/power_supply/battery/batt_slate_mode" "1" && success=1
            ;;
        "BATTERY_DEFENDER")
            echo "Applying battery defender..."
            write_node "/sys/class/power_supply/battery/bd_trickle_cnt" "1" && success=1
            ;;
        "IDT_PIN")
            echo "Applying IDT pin..."
            write_node "/sys/class/power_supply/idt/pin_enabled" "1" && success=1
            ;;
        "CHG_STATE")
            echo "Applying charging state..."
            write_node "/sys/class/power_supply/battery/charge_charger_state" "1" && success=1
            ;;
        "ADAPTER_CC")
            echo "Applying adapter CC..."
            write_node "/sys/class/power_supply/main/adapter_cc_mode" "1" && success=1
            ;;
        "HMT_TA")
            echo "Applying HMT TA..."
            write_node "/sys/class/power_supply/battery/hmt_ta_charge" "0" && success=1
            ;;
        "MAXFG_OFFMODE")
            echo "Applying MaxFG offmode..."
            write_node "/sys/class/power_supply/maxfg/offmode_charger" "1" && success=1
            ;;
        "COOL_MODE")
            echo "Applying cool mode..."
            write_node "/sys/class/power_supply/main/cool_mode" "1" && success=1
            ;;
        "RESTRICTED_CHARGING")
            echo "Applying restricted charging..."
            write_node "/sys/class/power_supply/battery/restricted_charging" "1" && success=1
            write_node "/sys/class/power_supply/wireless/restricted_charging" "1" && success=1
            ;;
        *)
            echo "Unknown part: $part"
            return 1
            ;;
    esac
    
    if [ $success -eq 0 ]; then
        echo "No compatible nodes found for $part"
        return 1
    fi
    return 0
}

# Function to restore normal charging
restore_normal() {
    local part="$1"
    local success=0
    
    case "$part" in
        "OPLUS_MMI")
            echo "Restoring OPLUS MMI normal..."
            write_node "/sys/class/oplus_chg/battery/mmi_charging_enable" "1" && success=1
            write_node "/sys/class/power_supply/battery/mmi_charging_enable" "1" && success=1
            write_node "/sys/devices/virtual/oplus_chg/battery/mmi_charging_enable" "1" && success=1
            write_node "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/mmi_charging_enable" "1" && success=1
            ;;
        "TRANSISSION_BYPASSCHG")
            echo "Restoring Transission normal..."
            write_node "/sys/devices/platform/charger/bypass_charger" "0" && success=1
            ;;
        "OPLUS_EXPERIMENTAL")
            echo "Restoring OPLUS experimental normal..."
            write_node "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/chg_enable" "1" && success=1
            ;;
        "OPLUS_COOLDOWN")
            echo "Restoring OPLUS cooldown normal..."
            write_node "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/cool_down" "0" && success=1
            ;;
        "SUSPEND_COMMON")
            echo "Restoring suspend common normal..."
            write_node "/sys/class/power_supply/battery/input_suspend" "0" && success=1
            write_node "/sys/class/power_supply/battery/battery_input_suspend" "0" && success=1
            ;;
        # Add more restore cases as needed...
        *)
            echo "Restore not implemented for: $part"
            return 1
            ;;
    esac
    
    if [ $success -eq 0 ]; then
        echo "No compatible nodes found for $part"
        return 1
    fi
    return 0
}

# Auto-detect available charging control methods
auto_detect() {
    echo "Auto-detecting available charging control methods..."
    local found=0
    
    # Check each part type for available nodes
    for part in OPLUS_MMI TRANSISSION_BYPASSCHG OPLUS_EXPERIMENTAL OPLUS_COOLDOWN \
                SUSPEND_COMMON CONTROL_COMMON DISABLE_COMMON SPREADTRUM_STOPCHG \
                TEGRA_I2C SIOP_LEVEL SMART_INTERRUPT MEDIATEK_COMMON MEDIATEK_ADVANCED \
                QCOM_SUSPEND QCOM_ENABLE_CHG QCOM_COOLDOWN QCOM_BATT_PROTECT \
                PM8058_PMIC PM8921_PMIC SMB137B_PMIC SMB1357_PMIC BQ2589X_PMIC \
                QCOM_PMIC_SUSPEND NUBIA_COMMON GOOGLE_PIXEL HUAWEI_COMMON \
                ASUS_LIMIT ASUS_SUSPEND LGE_COMMON LGE_CHG_COMPLETED LGE_CHG_LEVEL \
                MANTA_BATTERY CAT_CHG_SWITCH MT_BATTERY SAMSUNG_STORE_MODE \
                CHARGE_LIMIT QPNP_BLOCKING GOOGLE_STOP_LEVEL GOOGLE_CHG_MODE \
                TEST_MODE SLATE_MODE BATTERY_DEFENDER IDT_PIN CHG_STATE \
                ADAPTER_CC HMT_TA MAXFG_OFFMODE COOL_MODE RESTRICTED_CHARGING; do
        
        # Check if any nodes for this part exist
        case "$part" in
            "OPLUS_MMI")
                if check_node "/sys/class/oplus_chg/battery/mmi_charging_enable" || \
                   check_node "/sys/class/power_supply/battery/mmi_charging_enable"; then
                    echo "Found: $part"
                    found=1
                fi
                ;;
            "SUSPEND_COMMON")
                if check_node "/sys/class/power_supply/battery/input_suspend"; then
                    echo "Found: $part"
                    found=1
                fi
                ;;
            "DISABLE_COMMON")
                if check_node "/sys/class/power_supply/battery/charging_enabled" || \
                   check_node "/sys/class/power_supply/battery/charge_disable"; then
                    echo "Found: $part"
                    found=1
                fi
                ;;
            # Add more detection logic as needed
        esac
    done
    
    if [ $found -eq 0 ]; then
        echo "No compatible charging control methods found"
        return 1
    fi
    return 0
}

# Main script logic
show_usage() {
    echo "Usage: $0 [bypass|restore|auto|list] [PART_TYPE]"
    echo ""
    echo "Commands:"
    echo "  bypass PART_TYPE  - Apply bypass charging for specific part"
    echo "  restore PART_TYPE - Restore normal charging for specific part"
    echo "  auto             - Auto-detect and apply first available method"
    echo "  list             - List all available part types"
    echo ""
    echo "Examples:"
    echo "  $0 bypass OPLUS_MMI"
    echo "  $0 restore DISABLE_COMMON"
    echo "  $0 auto"
}

list_parts() {
    echo "Available part types:"
    echo "OPLUS_MMI TRANSISSION_BYPASSCHG OPLUS_EXPERIMENTAL OPLUS_COOLDOWN"
    echo "SUSPEND_COMMON CONTROL_COMMON DISABLE_COMMON SPREADTRUM_STOPCHG"
    echo "TEGRA_I2C SIOP_LEVEL SMART_INTERRUPT MEDIATEK_COMMON MEDIATEK_ADVANCED"
    echo "QCOM_SUSPEND QCOM_ENABLE_CHG QCOM_COOLDOWN QCOM_BATT_PROTECT"
    echo "PM8058_PMIC PM8921_PMIC SMB137B_PMIC SMB1357_PMIC BQ2589X_PMIC"
    echo "QCOM_PMIC_SUSPEND NUBIA_COMMON GOOGLE_PIXEL HUAWEI_COMMON"
    echo "ASUS_LIMIT ASUS_SUSPEND LGE_COMMON LGE_CHG_COMPLETED LGE_CHG_LEVEL"
    echo "MANTA_BATTERY CAT_CHG_SWITCH MT_BATTERY SAMSUNG_STORE_MODE"
    echo "CHARGE_LIMIT QPNP_BLOCKING GOOGLE_STOP_LEVEL GOOGLE_CHG_MODE"
    echo "TEST_MODE SLATE_MODE BATTERY_DEFENDER IDT_PIN CHG_STATE"
    echo "ADAPTER_CC HMT_TA MAXFG_OFFMODE COOL_MODE RESTRICTED_CHARGING"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Warning: This script should be run as root for proper access to system files"
fi

# Main execution
case "$1" in
    "bypass")
        if [ -z "$2" ]; then
            echo "Error: Part type required for bypass command"
            show_usage
            exit 1
        fi
        apply_bypass "$2"
        ;;
    "restore")
        if [ -z "$2" ]; then
            echo "Error: Part type required for restore command"
            show_usage
            exit 1
        fi
        restore_normal "$2"
        ;;
    "auto")
        auto_detect
        ;;
    "list")
        list_parts
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
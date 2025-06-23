#!/bin/bash

# OPLUS_MMI
OPLUS_MMI_NODES=(
    "/sys/class/oplus_chg/battery/mmi_charging_enable"
    "/sys/class/power_supply/battery/mmi_charging_enable"
    "/sys/devices/virtual/oplus_chg/battery/mmi_charging_enable"
    "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/mmi_charging_enable"
)
OPLUS_MMI_NORMAL="1"
OPLUS_MMI_BYPASS="0"

# TRANSISSION_BYPASSCHG
TRANSISSION_BYPASSCHG_NODES=(
    "/sys/devices/platform/charger/bypass_charger"
)
TRANSISSION_BYPASSCHG_NORMAL="0"
TRANSISSION_BYPASSCHG_BYPASS="1"

# OPLUS_EXPERIMENTAL
OPLUS_EXPERIMENTAL_NODES=(
    "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/chg_enable"
)
OPLUS_EXPERIMENTAL_NORMAL="1"
OPLUS_EXPERIMENTAL_BYPASS="0"

# OPLUS_COOLDOWN
OPLUS_COOLDOWN_NODES=(
    "/sys/devices/platform/soc/soc:oplus,chg_intf/oplus_chg/battery/cool_down"
)
OPLUS_COOLDOWN_NORMAL="0"
OPLUS_COOLDOWN_BYPASS="1"

# SUSPEND_COMMON
SUSPEND_COMMON_NODES=(
    "/sys/class/power_supply/battery/input_suspend"
    "/sys/class/power_supply/battery/battery_input_suspend"
)
SUSPEND_COMMON_NORMAL="0"
SUSPEND_COMMON_BYPASS="1"

# CONTROL_COMMON
CONTROL_COMMON_NODES=(
    "/sys/class/power_supply/battery/charger_control"
)
CONTROL_COMMON_NORMAL="1"
CONTROL_COMMON_BYPASS="0"

# DISABLE_COMMON
DISABLE_COMMON_NODES=(
    "/sys/class/power_supply/battery/charge_disable"
    "/sys/class/power_supply/battery/charging_enabled"
    "/sys/class/power_supply/battery/charge_enabled"
    "/sys/class/power_supply/battery/battery_charging_enabled"
    "/sys/class/power_supply/battery/device/Charging_Enable"
    "/sys/class/power_supply/ac/charging_enabled"
    "/sys/class/power_supply/charge_data/enable_charger"
    "/sys/class/power_supply/dc/charging_enabled"
    "/sys/devices/platform/charger/tran_aichg_disable_charger"
    "/sys/class/power_supply/battery/op_disable_charge"
    "/sys/class/power_supply/chargalg/disable_charging"
    "/sys/class/power_supply/battery/connect_disable"
    "/sys/class/power_supply/battery/battery_charging_enabled"
    "/sys/devices/platform/omap/omap_i2c.3/i2c-3/3-005f/charge_enable"
    "/sys/devices/soc/qpnp-smbcharger-18/power_supply/battery/battery_charging_enabled"
)
DISABLE_COMMON_NORMAL_VALS=("0" "1" "1" "1" "1" "1" "1" "1" "0" "0" "0" "0" "1" "1" "1")
DISABLE_COMMON_BYPASS_VALS=("1" "0" "0" "0" "0" "0" "0" "0" "1" "1" "1" "1" "0" "0" "0")

# SPREADTRUM_STOPCHG
SPREADTRUM_STOPCHG_NODES=(
    "/sys/class/power_supply/battery/stop_charge"
)
SPREADTRUM_STOPCHG_NORMAL="0"
SPREADTRUM_STOPCHG_BYPASS="1"

# TEGRA_I2C
TEGRA_I2C_NODES=(
    "/sys/devices/platform/tegra12-i2c.0/i2c-0/0-006b/charging_state"
)
TEGRA_I2C_NORMAL="enabled"
TEGRA_I2C_BYPASS="disabled"

# SIOP_LEVEL
SIOP_LEVEL_NODES=(
    "/sys/class/power_supply/battery/siop_level"
)
SIOP_LEVEL_NORMAL="100"
SIOP_LEVEL_BYPASS="0"

# SMART_INTERRUPT
SMART_INTERRUPT_NODES=(
    "/sys/class/power_supply/battery_ext/smart_charging_interruption"
)
SMART_INTERRUPT_NORMAL="0"
SMART_INTERRUPT_BYPASS="1"

# MEDIATEK_COMMON
MEDIATEK_COMMON_NODES=(
    "/proc/mtk_battery_cmd/current_cmd"
)
MEDIATEK_COMMON_NORMAL="0 0"
MEDIATEK_COMMON_BYPASS="0 1"

# MEDIATEK_ADVANCED
MEDIATEK_ADVANCED_NODES=(
    "/proc/mtk_battery_cmd/current_cmd"
    "/proc/mtk_battery_cmd/en_power_path"
)
MEDIATEK_ADVANCED_NORMAL_VALS=("0 0" "1")
MEDIATEK_ADVANCED_BYPASS_VALS=("0 1" "0")

# QCOM_SUSPEND
QCOM_SUSPEND_NODES=(
    "/sys/class/qcom-battery/input_suspend"
)
QCOM_SUSPEND_NORMAL="1"
QCOM_SUSPEND_BYPASS="0"

# QCOM_ENABLE_CHG
QCOM_ENABLE_CHG_NODES=(
    "/sys/class/qcom-battery/charging_enabled"
)
QCOM_ENABLE_CHG_NORMAL="1"
QCOM_ENABLE_CHG_BYPASS="0"

# QCOM_COOLDOWN
QCOM_COOLDOWN_NODES=(
    "/sys/class/qcom-battery/cool_mode"
)
QCOM_COOLDOWN_NORMAL="0"
QCOM_COOLDOWN_BYPASS="1"

# QCOM_BATT_PROTECT
QCOM_BATT_PROTECT_NODES=(
    "/sys/class/qcom-battery/batt_protect_en"
)
QCOM_BATT_PROTECT_NORMAL="0"
QCOM_BATT_PROTECT_BYPASS="1"

# PM8058_PMIC
PM8058_PMIC_NODES=(
    "/sys/module/pmic8058_charger/parameters/disabled"
)
PM8058_PMIC_NORMAL="0"
PM8058_PMIC_BYPASS="1"

# PM8921_PMIC
PM8921_PMIC_NODES=(
    "/sys/module/pm8921_charger/parameters/disabled"
)
PM8921_PMIC_NORMAL="0"
PM8921_PMIC_BYPASS="1"

# SMB137B_PMIC
SMB137B_PMIC_NODES=(
    "/sys/module/smb137b/parameters/disabled"
)
SMB137B_PMIC_NORMAL="0"
SMB137B_PMIC_BYPASS="1"

# SMB1357_PMIC
SMB1357_PMIC_NODES=(
    "/proc/smb1357_disable_chrg"
)
SMB1357_PMIC_NORMAL="0"
SMB1357_PMIC_BYPASS="1"

# BQ2589X_PMIC
BQ2589X_PMIC_NODES=(
    "/sys/class/power_supply/bq2589x_charger/enable_charging"
)
BQ2589X_PMIC_NORMAL="1"
BQ2589X_PMIC_BYPASS="0"

# QCOM_PMIC_SUSPEND
QCOM_PMIC_SUSPEND_NODES=(
    "/sys/devices/platform/soc/soc:qcom,pmic_glink/soc:qcom,pmic_glink:qcom,battery_charger/force_charger_suspend"
)
QCOM_PMIC_SUSPEND_NORMAL="0"
QCOM_PMIC_SUSPEND_BYPASS="1"

# NUBIA_COMMON
NUBIA_COMMON_NODES=(
    "/sys/kernel/nubia_charge/charger_bypass"
)
NUBIA_COMMON_NORMAL="off"
NUBIA_COMMON_BYPASS="on"

# GOOGLE_PIXEL
GOOGLE_PIXEL_NODES=(
    "/sys/devices/platform/soc/soc:google,charger/charge_disable"
    "/sys/kernel/debug/google_charger/chg_suspend"
    "/sys/kernel/debug/google_charger/input_suspend"
)
GOOGLE_PIXEL_NORMAL="0"
GOOGLE_PIXEL_BYPASS="1"

# HUAWEI_COMMON
HUAWEI_COMMON_NODES=(
    "/sys/devices/platform/huawei_charger/enable_charger"
    "/sys/class/hw_power/charger/charge_data/enable_charger"
)
HUAWEI_COMMON_NORMAL="1"
HUAWEI_COMMON_BYPASS="0"

# ASUS_LIMIT
ASUS_LIMIT_NODES=(
    "/sys/class/asuslib/charger_limit_en"
)
ASUS_LIMIT_NORMAL="0"
ASUS_LIMIT_BYPASS="1"

# ASUS_SUSPEND
ASUS_SUSPEND_NODES=(
    "/sys/class/asuslib/charging_suspend_en"
)
ASUS_SUSPEND_NORMAL="0"
ASUS_SUSPEND_BYPASS="1"

# LGE_COMMON
LGE_COMMON_NODES=(
    "/sys/devices/platform/lge-unified-nodes/charging_enable"
)
LGE_COMMON_NORMAL="1"
LGE_COMMON_BYPASS="0"

# LGE_CHG_COMPLETED
LGE_CHG_COMPLETED_NODES=(
    "/sys/devices/platform/lge-unified-nodes/charging_completed"
)
LGE_CHG_COMPLETED_NORMAL="0"
LGE_CHG_COMPLETED_BYPASS="1"

# LGE_CHG_LEVEL
LGE_CHG_LEVEL_NODES=(
    "/sys/module/lge_battery/parameters/charge_stop_level"
    "/sys/class/power_supply/battery/input_suspend"
)
LGE_CHG_LEVEL_NORMAL_VALS=("100" "0")
LGE_CHG_LEVEL_BYPASS_VALS=("5" "0")

# MANTA_BATTERY
MANTA_BATTERY_NODES=(
    "/sys/devices/virtual/power_supply/manta-battery/charge_enabled"
)
MANTA_BATTERY_NORMAL="1"
MANTA_BATTERY_BYPASS="0"

# CAT_CHG_SWITCH
CAT_CHG_SWITCH_NODES=(
    "/sys/devices/platform/battery/CCIChargerSwitch"
)
CAT_CHG_SWITCH_NORMAL="1"
CAT_CHG_SWITCH_BYPASS="0"

# MT_BATTERY
MT_BATTERY_NODES=(
    "/sys/devices/platform/mt-battery/disable_charger"
)
MT_BATTERY_NORMAL="0"
MT_BATTERY_BYPASS="1"

# SAMSUNG_STORE_MODE
SAMSUNG_STORE_MODE_NODES=(
    "/sys/class/power_supply/battery/store_mode"
)
SAMSUNG_STORE_MODE_NORMAL="0"
SAMSUNG_STORE_MODE_BYPASS="1"

# CHARGE_LIMIT
CHARGE_LIMIT_NODES=(
    "/proc/driver/charger_limit_enable"
    "/proc/driver/charger_limit"
)
CHARGE_LIMIT_NORMAL_VALS=("0" "100")
CHARGE_LIMIT_BYPASS_VALS=("1" "5")

# QPNP_BLOCKING
QPNP_BLOCKING_NODES=(
    "/sys/module/qpnp_adaptive_charge/parameters/blocking"
)
QPNP_BLOCKING_NORMAL="0"
QPNP_BLOCKING_BYPASS="1"

# GOOGLE_STOP_LEVEL
GOOGLE_STOP_LEVEL_NODES=(
    "/sys/devices/platform/google,charger/charge_stop_level"
)
GOOGLE_STOP_LEVEL_NORMAL="100"
GOOGLE_STOP_LEVEL_BYPASS="5"

# GOOGLE_CHG_MODE
GOOGLE_CHG_MODE_NODES=(
    "/sys/kernel/debug/google_charger/chg_mode"
)
GOOGLE_CHG_MODE_NORMAL="1"
GOOGLE_CHG_MODE_BYPASS="0"

# TEST_MODE
TEST_MODE_NODES=(
    "/sys/class/power_supply/battery/test_mode"
)
TEST_MODE_NORMAL="2"
TEST_MODE_BYPASS="1"

# SLATE_MODE
SLATE_MODE_NODES=(
    "/sys/class/power_supply/battery/batt_slate_mode"
)
SLATE_MODE_NORMAL="0"
SLATE_MODE_BYPASS="1"

# BATTERY_DEFENDER
BATTERY_DEFENDER_NODES=(
    "/sys/class/power_supply/battery/bd_trickle_cnt"
)
BATTERY_DEFENDER_NORMAL="0"
BATTERY_DEFENDER_BYPASS="1"

# IDT_PIN
IDT_PIN_NODES=(
    "/sys/class/power_supply/idt/pin_enabled"
)
IDT_PIN_NORMAL="0"
IDT_PIN_BYPASS="1"

# CHG_STATE
CHG_STATE_NODES=(
    "/sys/class/power_supply/battery/charge_charger_state"
)
CHG_STATE_NORMAL="0"
CHG_STATE_BYPASS="1"

# ADAPTER_CC
ADAPTER_CC_NODES=(
    "/sys/class/power_supply/main/adapter_cc_mode"
)
ADAPTER_CC_NORMAL="0"
ADAPTER_CC_BYPASS="1"

# HMT_TA
HMT_TA_NODES=(
    "/sys/class/power_supply/battery/hmt_ta_charge"
)
HMT_TA_NORMAL="1"
HMT_TA_BYPASS="0"

# MAXFG_OFFMODE
MAXFG_OFFMODE_NODES=(
    "/sys/class/power_supply/maxfg/offmode_charger"
)
MAXFG_OFFMODE_NORMAL="0"
MAXFG_OFFMODE_BYPASS="1"

# COOL_MODE
COOL_MODE_NODES=(
    "/sys/class/power_supply/main/cool_mode"
)
COOL_MODE_NORMAL="0"
COOL_MODE_BYPASS="1"

# RESTRICTED_CHARGING
RESTRICTED_CHARGING_NODES=(
    "/sys/class/power_supply/battery/restricted_charging"
    "/sys/class/power_supply/wireless/restricted_charging"
)
RESTRICTED_CHARGING_NORMAL="0"
RESTRICTED_CHARGING_BYPASS="1"

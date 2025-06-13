#!/bin/bash

# Kobo Fast Charge, collab with Charging Enhancer+ By: VelocityFox22

tweak() {
	if [ -f $2 ]; then
		chmod 644 $2 >/dev/null 2>&1
		echo $1 >$2 2>/dev/null
		chmod 444 $2 >/dev/null 2>&1
	fi
}

# Disable thermal zones for maximum performance
for zone in /sys/class/thermal/thermal_zone*/mode; do
    tweak "$zone" "disabled"
done

# BMS (Battery Management System) temperature tweaks
for bms in /sys/devices/platform/bms/*; do
    tweak 150 $bms/temp_cool
    tweak 460 $bms/temp_hot
    tweak 460 $bms/temp_warm
done 

# Platform charger optimizations
for platformCharger in /sys/devices/platform/charger/*; do
    tweak 9000000 $platformCharger/current_max
    tweak 9000 $platformCharger/sc_ibat_limit
    tweak 14000 $platformCharger/sc_stime
    tweak 9000000 $platformCharger/hw_current_max
    tweak 9000000 $platformCharger/pd_current_max
    tweak 9000000 $platformCharger/ctm_current_max
    tweak 9000000 $platformCharger/sdp_current_max
done

# Platform main charging parameters
for platformMain in /sys/devices/platform/main/*; do
    tweak 9000000 $platformMain/current_max
    tweak 9000000 $platformMain/constant_charge_current_max
done

# Platform battery parameters
for platformBattery in /sys/devices/platform/battery/*; do
    tweak 9000000 $platformBattery/current_max
    tweak 9000000 $platformBattery/constant_charge_current_max
done

# Power supply current limits (original KoboKanaeru values)
for powerSupplyCurrent in /sys/class/power_supply/*; do
    tweak 5750000 $powerSupplyCurrent/constant_charge_current_max
    tweak 12500000 $powerSupplyCurrent/input_current_limit
done

# Enhanced power supply optimizations with higher limits
for path in $(find /sys/class/power_supply -type f \( -name "constant_charge_current_max" -o -name "input_current_limit" \)); do
    tweak "$path" 3000000
done

# Voltage limits
tweak 12500000 /sys/class/power_supply/*/input_voltage_limit
for path in $(find /sys/class/power_supply -type f -name "input_voltage_limit"); do
    tweak "$path" 5000000
done

# Additional power supply tweaks
tweak 100 /sys/class/power_supply/*/siop_level
tweak 500 /sys/class/power_supply/*/temp_warm

# Enable fast charging features
for feature in fast_charge boost_mode turbo_mode; do
    tweak "/sys/class/power_supply/battery/$feature" 1
done

# MTK and platform specific optimizations
tweak 10800000 /sys/devices/mtk-battery/restricted_current
tweak 9000000 /sys/devices/platform/pc_port/current_max
tweak 9000000 /sys/devices/platform/constant_charge_current__max
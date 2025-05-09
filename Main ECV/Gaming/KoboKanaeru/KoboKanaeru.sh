tweak() {
	if [ -f $2 ]; then
		chmod 644 $2 >/dev/null 2>&1
		echo $1 >$2 2>/dev/null
		chmod 444 $2 >/dev/null 2>&1
	fi
}

for bms in /sys/devices/platform/bms/*; do
    tweak 150 $bms/temp_cool
    tweak 460 $bms/temp_hot
    tweak 460 $bms/temp_warm
done 

for platformCharger in /sys/devices/platform/charger/*; do
    tweak 9000000 $platformCharger/current_max
    tweak 9000 $platformCharger/sc_ibat_limit
    tweak 14000 $platformCharger/sc_stime
    tweak 9000000 $platformCharger/hw_current_max
    tweak 9000000 $platformCharger/pd_current_max
    tweak 9000000 $platformCharger/ctm_current_max
    tweak 9000000 $platformCharger/sdp_current_max
done

for platformMain in /sys/devices/platform/main/*; do
    tweak 9000000 $platformMain/current_max
    tweak 9000000 $platformMain/constant_charge_current_max
done

for platformBattery in /sys/devices/platform/battery/*; do
    tweak 9000000 $platformBattery/current_max
    tweak 9000000 $platformBattery/constant_charge_current_max
done

for powerSupplyCurrent in /sys/class/power_supply/*; do
    tweak 5750000 $powerSupplyCurrent/constant_charge_current_max
    tweak 12500000 $powerSupplyCurrent/input_current_limit
done

tweak 12500000 /sys/class/power_supply/*/input_voltage_limit
tweak 100 /sys/class/power_supply/*/siop_level
tweak 500 /sys/class/power_supply/*/temp_warm
tweak 10800000 /sys/devices/mtk-battery/restricted_current
tweak 9000000 /sys/devices/platform/pc_port/current_max
tweak 9000000 /sys/devices/platform/constant_charge_current__max

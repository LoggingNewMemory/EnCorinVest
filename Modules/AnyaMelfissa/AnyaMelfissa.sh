tweak() {
	if [ -f $2 ]; then
		chmod 644 $2 >/dev/null 2>&1
		echo $1 >$2 2>/dev/null
		chmod 444 $2 >/dev/null 2>&1
	fi
}


for trip in /sys/class/thermal/thermal_zone*/trip_point*; do
    tweak 999999999 $trip
done

stop thermal
stop thermal_manager
stop thermald
stop thermalloadalgod
stop vendor.thermal-hal-2-0.mtk

for a in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc. | sed 's/init.svc.//'); do 
    stop $a
done

for b in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc.); do 
    setprop $b stopped
done

for c in $(getprop | grep thermal | cut -f1 -d] | cut -f2 -d[ | grep -F init.svc_); do 
    setprop $c ""
done

# From RiProG Thermal NextGen

for i in {1..5}; do
    for result in $(getprop | grep -E 'logd|thermal' | cut -d '[' -f2 | cut -d ']' -f1); do
        output=$(getprop "$result")
        if [[ "$output" == "running" || "$output" == "restarting" ]]; then
            service="${result:9}"
            setprop ctl.stop "$service"
        fi
    done
done

for i in {1..5}; do
    for result in $(getprop | grep -E 'logd|thermal' | cut -d '[' -f2 | cut -d ']' -f1); do
        output=$(getprop "$result")
        if [[ "$output" == "running" || "$output" == "restarting" ]]; then
            service="${result:9}"
            stop "$service"
            getprop "$result"
        fi
    done
done

for i in {1..5}; do
    for result in $(getprop | grep -E 'logd|thermal' | cut -d '[' -f2 | cut -d ']' -f1); do
        output=$(getprop "$result")
        if [[ "$output" == "running" || "$output" == "restarting" ]]; then
            setprop "$result" "stopped"
        fi
    done
done

find /sys/devices/virtual/thermal -type f -exec chmod 000 {} +

resetprop -n dalvik.vm.dexopt.thermal-cutoff 0
resetprop -n ro.boottime.thermal 0
resetprop -n ro.boottime.thermald 0
resetprop -n ro.boottime.thermal_manager 0 
resetprop -n ro.boottime.thermald 0 
resetprop -n ro.boottime.thermalloadalgod 0
resetprop -n ro.boottime.vendor.thermal-hal-2-0.mtk 0
resetprop -n ro.dar.thermal_core.support 0
resetprop -n ro.vendor.mtk_thermal_2_0 0
resetprop -n ro.vendor.tran.hbm.thermal.temp.clr 99999
resetprop -n ro.vendor.tran.hbm.thermal.temp.trig 99999
resetprop -n debug.thermal.throttle.support "no"

su -lp 2000 -c "cmd notification post -S bigtext -t 'Anya Melfissa' Tag492849 'Thermal Is Dead ⚔️'"
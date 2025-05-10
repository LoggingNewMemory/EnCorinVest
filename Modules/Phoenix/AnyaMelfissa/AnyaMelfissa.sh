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

# From RiProG Thermal Low Unsensor

# Function to check and stop services
check_and_stop_services() {
    getprop | grep -E 'logd|thermal' | cut -d '[' -f2 | cut -d ']' -f1 | grep -v 'hal' | while read -r result; do
        properties=$(getprop "$result")
        if [ "$properties" = "running" ] || [ "$properties" = "restarting" ]; then
            if [ "$1" = "setprop" ]; then
                setprop ctl.stop "${result#*.}"
            else
                stop "${result#*.}"
                getprop "$result"
            fi
        fi
    done
}

# First round of service checks using setprop
for i in {1..2}; do
    check_and_stop_services "setprop"
    sleep 2
done

# Second round of service checks using stop command
for i in {1..2}; do
    check_and_stop_services "stop"
    sleep 5
done

# Wait and modify thermal device permissions
sleep 10
find /sys/devices/virtual/thermal -type f -exec chmod 000 {} +

resetprop -n dalvik.vm.dexopt.thermal-cutoff 0
resetprop -n ro.boottime.thermal 0
resetprop -n ro.boottime.thermald 0
resetprop -n ro.boottime.thermal_manager 0 
resetprop -n ro.boottime.thermald 0 
resetprop -n ro.boottime.thermalloadalgod 0
resetprop -n ro.dar.thermal_core.support 0
resetprop -n ro.vendor.mtk_thermal_2_0 0
resetprop -n ro.vendor.tran.hbm.thermal.temp.clr 99999
resetprop -n ro.vendor.tran.hbm.thermal.temp.trig 99999
resetprop -n debug.thermal.throttle.support "no"

su -lp 2000 -c "cmd notification post -S bigtext -t 'Anya Melfissa' -i file:///data/local/tmp/Anya.png -I file:///data/local/tmp/Anya.png TagAnya 'Good Day! Thermal Is Dead BTW'"
# This is function for EnCorinVest
# Not much, but I need it
# Note: Encore is modified, so don't expect easy sync

###############################
# DEFINE CONFIG
###############################

# Config file path
ENCORIN_CONFIG="/data/adb/modules/EnCorinVest/encorin.txt"

# Format: 1=MTK, 2=SD, 3=Exynos, 4=Unisoc, 5=Tensor, 6=Intel, 7=Tegra
SOC=$(grep '^SOC=' "$ENCORIN_CONFIG" | cut -d'=' -f2)
LITE_MODE=$(grep '^LITE_MODE=' "$ENCORIN_CONFIG" | cut -d'=' -f2)
PPM_POLICY=$(grep '^PPM_POLICY=' "$ENCORIN_CONFIG" | cut -d'=' -f2)

DEFAULT_CPU_GOV=$(grep '^GOV=' "$ENCORIN_CONFIG" | cut -d'=' -f2)
if [ -z "$DEFAULT_CPU_GOV" ]; then
    if [ -e /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ] && grep -q "schedhorizon" /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors; then
        DEFAULT_CPU_GOV="schedhorizon"
    else
        DEFAULT_CPU_GOV="schedutil"
    fi
fi

DEVICE_MITIGATION=$(grep '^DEVICE_MITIGATION=' "$ENCORIN_CONFIG" | cut -d'=' -f2)
DND=$(grep '^DND=' "$ENCORIN_CONFIG" | cut -d'=' -f2)

##############################
# Begin Functions
##############################

tweak() {
    if [ -e "$2" ]; then
        chmod 644 "$2" >/dev/null 2>&1
        echo "$1" > "$2" 2>/dev/null
        chmod 444 "$2" >/dev/null 2>&1
    fi
}

kill_all() {
	for pkg in $(pm list packages -3 | cut -f 2 -d ":"); do
    if [ "$pkg" != "com.google.android.inputmethod.latin" ]; then
        am force-stop $pkg
    fi
done

echo 3 > /proc/sys/vm/drop_caches
am kill-all
}

# This is also external

bypass_on() {
    BYPASS=$(grep "^ENABLE_BYPASS=" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
    if [ "$BYPASS" = "Yes" ]; then
        sh $SCRIPT_PATH/encorin_bypass_controller.sh enable
    fi
}

bypass_off() {
    BYPASS=$(grep "^ENABLE_BYPASS=" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
    if [ "$BYPASS" = "Yes" ]; then
        sh $SCRIPT_PATH/encorin_bypass_controller.sh disable
    fi
}

notification() {
    local TITLE="EnCorinVest"
    local MESSAGE="$1"
    local LOGO="/data/local/tmp/logo.png"
    
    su -lp 2000 -c "cmd notification post -S bigtext -t '$TITLE' -i file://$LOGO -I file://$LOGO TagEncorin '$MESSAGE'"
}

# DND Function is treated as external, because overrided by ECV App

dnd_off() {
	DND=$(grep "^DND" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
	if [ "$DND" = "No" ]; then
		cmd notification set_dnd off
	fi
}

dnd_on() {
	DND=$(grep "^DND" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
	if [ "$DND" = "Yes" ]; then
		cmd notification set_dnd priority
	fi
}

##########################################
# Performance Basic 
##########################################
performance_basic() {
sync

# I/O Tweaks
for dir in /sys/block/*; do
apply 0 "$dir/queue/iostats"
apply 0 "$dir/queue/add_random"
done &

apply 1 /proc/sys/net/ipv4/tcp_low_latency
apply 1 /proc/sys/net/ipv4/tcp_ecn
apply 3 /proc/sys/net/ipv4/tcp_fastopen
apply 1 /proc/sys/net/ipv4/tcp_sack
apply 0 /proc/sys/net/ipv4/tcp_timestamps


# Limit max perf event processing time to this much CPU usage
apply 3 /proc/sys/kernel/perf_cpu_time_max_percent

# Disable schedstats
apply 0 /proc/sys/kernel/sched_schedstats

# Disable Oppo/Realme cpustats
apply 0 /proc/sys/kernel/task_cpustats_enable

# Disable Sched auto group
apply 0 /proc/sys/kernel/sched_autogroup_enabled

# Enable CRF
apply 1 /proc/sys/kernel/sched_child_runs_first

# Improve real time latencies by reducing the scheduler migration time
apply 32 /proc/sys/kernel/sched_nr_migrate

# Tweaking scheduler to reduce latency
apply 50000 /proc/sys/kernel/sched_migration_cost_ns
apply 1000000 /proc/sys/kernel/sched_min_granularity_ns
apply 1500000 /proc/sys/kernel/sched_wakeup_granularity_ns

# Disable read-ahead for swap devices
apply 0 /proc/sys/vm/page-cluster

# Update /proc/stat less often to reduce jitter
apply 15 /proc/sys/vm/stat_interval

# Disable compaction_proactiveness
apply 0 /proc/sys/vm/compaction_proactiveness

# Disable SPI CRC
apply 0 /sys/module/mmc_core/parameters/use_spi_crc

# Disable OnePlus opchain
apply 0 /sys/module/opchain/parameters/chain_on

# Disable Oplus bloats
apply 0 /sys/module/cpufreq_bouncing/parameters/enable
apply 0 /proc/task_info/task_sched_info/task_sched_info_enable
apply 0 /proc/oplus_scheduler/sched_assist/sched_assist_enabled

# Report max CPU capabilities to these libraries
apply "libunity.so, libil2cpp.so, libmain.so, libUE4.so, libgodot_android.so, libgdx.so, libgdx-box2d.so, libminecraftpe.so, libLive2DCubismCore.so, libyuzu-android.so, libryujinx.so, libcitra-android.so, libhdr_pro_engine.so, libandroidx.graphics.path.so, libeffect.so" /proc/sys/kernel/sched_lib_name
apply 255 /proc/sys/kernel/sched_lib_mask_force

# Set thermal governor to step_wise
for dir in /sys/class/thermal/thermal_zone*; do
	apply "step_wise" "$dir/policy"
done
}


##########################################
# Balanced Script
##########################################


##########################################
# Powersave Script
##########################################


##########################################
# SOC Recognition
##########################################
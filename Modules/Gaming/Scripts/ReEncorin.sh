#!/system/bin/sh
# This still have some Encore function 
# However this is out of Encore, so don't expect easy SYNC

###############################
# DEFINE CONFIG
###############################

# Config file path
ENCORIN_CONFIG="/data/adb/modules/EnCorinVest/encorin.txt"

# Format: 1=MTK, 2=SD, 3=Exynos, 4=Unisoc, 5=Tensor, 6=Intel, 7=Tegra
SOC=$(grep '^SOC=' "$ENCORIN_CONFIG" | cut -d'=' -f2)
LITE_MODE=$(grep '^LITE_MODE=' "$ENCORIN_CONFIG" | cut -d'=' -f2)

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

kakangkuh() {
	[ ! -f "$2" ] && return 1
	chmod 644 "$2" >/dev/null 2>&1
	echo "$1" >"$2" 2>/dev/null
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

which_maxfreq() {
	tr ' ' '\n' <"$1" | sort -nr | head -n 1
}

which_minfreq() {
	tr ' ' '\n' <"$1" | grep -v '^[[:space:]]*$' | sort -n | head -n 1
}

which_midfreq() {
	total_opp=$(wc -w <"$1")
	mid_opp=$(((total_opp + 1) / 2))
	tr ' ' '\n' <"$1" | grep -v '^[[:space:]]*$' | sort -nr | head -n $mid_opp | tail -n 1
}

devfreq_max_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	tweak "$max_freq" "$1/max_freq"
	tweak "$max_freq" "$1/min_freq"
}

devfreq_mid_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	mid_freq=$(which_midfreq "$1/available_frequencies")
	tweak "$max_freq" "$1/max_freq"
	tweak "$mid_freq" "$1/min_freq"
}

devfreq_unlock() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	min_freq=$(which_minfreq "$1/available_frequencies")
	kakangkuh "$max_freq" "$1/max_freq"
	kakangkuh "$min_freq" "$1/min_freq"
}

change_cpu_gov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
}

cpufreq_ppm_max_perf() {
	cluster=-1
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		((cluster++))
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq

		if [ "$LITE_MODE" -eq 1 ]; then
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			tweak "$cluster $cpu_midfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		else
			tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		fi
	done
}

cpufreq_max_perf() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		tweak "$cpu_maxfreq" "$path/scaling_max_freq"

		if [ "$LITE_MODE" -eq 1 ]; then
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			tweak "$cpu_midfreq" "$path/scaling_min_freq"
		else
			tweak "$cpu_maxfreq" "$path/scaling_min_freq"
		fi
	done
	chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
}

cpufreq_ppm_unlock() {
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		kakangkuh "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		kakangkuh "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
}

cpufreq_unlock() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		kakangkuh "$cpu_maxfreq" "$path/scaling_max_freq"
		kakangkuh "$cpu_minfreq" "$path/scaling_min_freq"
	done
	chmod -f 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
}

##################################
# Function End
##################################

##################################
# Performance Profile (1)
##################################
performance_basic() {
    sync

    # I/O Tweaks
    for dir in /sys/block/*; do
        tweak 0 "$dir/queue/iostats"
        tweak 0 "$dir/queue/add_random"
    done &

    tweak 1 /proc/sys/net/ipv4/tcp_low_latency
    tweak 1 /proc/sys/net/ipv4/tcp_ecn
    tweak 3 /proc/sys/net/ipv4/tcp_fastopen
    tweak 1 /proc/sys/net/ipv4/tcp_sack
    tweak 0 /proc/sys/net/ipv4/tcp_timestamps

    # Limit max perf event processing time to this much CPU usage
    tweak 3 /proc/sys/kernel/perf_cpu_time_max_percent

    # Disable schedstats
    tweak 0 /proc/sys/kernel/sched_schedstats

    # Disable Oppo/Realme cpustats
    tweak 0 /proc/sys/kernel/task_cpustats_enable

    # Disable Sched auto group
    tweak 0 /proc/sys/kernel/sched_autogroup_enabled

    # Enable CRF
    tweak 1 /proc/sys/kernel/sched_child_runs_first

    # Improve real time latencies by reducing the scheduler migration time
    tweak 32 /proc/sys/kernel/sched_nr_migrate

    # Tweaking scheduler to reduce latency
    tweak 50000 /proc/sys/kernel/sched_migration_cost_ns
    tweak 1000000 /proc/sys/kernel/sched_min_granularity_ns
    tweak 1500000 /proc/sys/kernel/sched_wakeup_granularity_ns

    # Disable read-ahead for swap devices
    tweak 0 /proc/sys/vm/page-cluster

    # Update /proc/stat less often to reduce jitter
    tweak 15 /proc/sys/vm/stat_interval

    # Disable compaction_proactiveness
    tweak 0 /proc/sys/vm/compaction_proactiveness

    # Disable SPI CRC
    tweak 0 /sys/module/mmc_core/parameters/use_spi_crc

    # Disable OnePlus opchain
    tweak 0 /sys/module/opchain/parameters/chain_on

    # Disable Oplus bloats
    tweak 0 /sys/module/cpufreq_bouncing/parameters/enable
    tweak 0 /proc/task_info/task_sched_info/task_sched_info_enable
    tweak 0 /proc/oplus_scheduler/sched_assist/sched_assist_enabled

    # Report max CPU capabilities to these libraries
    tweak "libunity.so, libil2cpp.so, libmain.so, libUE4.so, libgodot_android.so, libgdx.so, libgdx-box2d.so, libminecraftpe.so, libLive2DCubismCore.so, libyuzu-android.so, libryujinx.so, libcitra-android.so, libhdr_pro_engine.so, libandroidx.graphics.path.so, libeffect.so" /proc/sys/kernel/sched_lib_name
    tweak 255 /proc/sys/kernel/sched_lib_mask_force

    # Set thermal governor to step_wise
    for dir in /sys/class/thermal/thermal_zone*; do
        tweak "step_wise" "$dir/policy"
    done

    # Enable DND | External
    dnd_on

    # Disable battery saver module
    [ -f /sys/module/battery_saver/parameters/enabled ] && {
        if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
            tweak 0 /sys/module/battery_saver/parameters/enabled
        else
            tweak N /sys/module/battery_saver/parameters/enabled
        fi
    }

    # Disable split lock mitigation
    tweak 0 /proc/sys/kernel/split_lock_mitigate

    if [ -f "/sys/kernel/debug/sched_features" ]; then
        # Consider scheduling tasks that are eager to run
        tweak NEXT_BUDDY /sys/kernel/debug/sched_features

        # Some sources report large latency spikes during large migrations
        tweak NO_TTWU_QUEUE /sys/kernel/debug/sched_features
    fi

    if [ -d "/dev/stune/" ]; then
        # Prefer to schedule top-app tasks on idle CPUs
        tweak 1 /dev/stune/top-app/schedtune.prefer_idle

        # Mark top-app as boosted, find high-performing CPUs
        tweak 1 /dev/stune/top-app/schedtune.boost
    fi

    # Oppo/Oplus/Realme Touchpanel
    tp_path="/proc/touchpanel"
    if [ -d "$tp_path" ]; then
        tweak 1 $tp_path/game_switch_enable
        tweak 0 $tp_path/oplus_tp_limit_enable
        tweak 0 $tp_path/oppo_tp_limit_enable
        tweak 1 $tp_path/oplus_tp_direction
        tweak 1 $tp_path/oppo_tp_direction
    fi

    # Memory tweak
    tweak 80 /proc/sys/vm/vfs_cache_pressure

    # eMMC and UFS frequency
    for path in /sys/class/devfreq/*.ufshc \
        /sys/class/devfreq/mmc*; do

        if [ -d "$path" ]; then
            if [ "$LITE_MODE" -eq 1 ]; then
                devfreq_mid_perf "$path"
            else
                devfreq_max_perf "$path"
            fi
        fi
    done &

    # CPU GOV
    if [ "$LITE_MODE" -eq 0 ] && [ "$DEVICE_MITIGATION" -eq 0 ]; then
        change_cpu_gov "performance"
    else
        change_cpu_gov "$DEFAULT_CPU_GOV"
    fi

    # Force CPU frequency to the highest possible value
    if [ -d "/proc/ppm" ]; then
        cpufreq_ppm_max_perf
    else
        cpufreq_max_perf
    fi

    # I/O Tweaks
    for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
        tweak 32 "$dir/queue/read_ahead_kb"
        tweak 32 "$dir/queue/nr_requests"
    done &
}

##########################################
# Balanced Profile (2)
##########################################
balanced_basic() {
dnd_off

    [ -f /sys/module/battery_saver/parameters/enabled ] && {
        if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
        kakangkuh 0 /sys/module/battery_saver/parameters/enabled
        else
        kakangkuh N /sys/module/battery_saver/parameters/enabled
        fi
    }

    kakangkuh 1 /proc/sys/kernel/split_lock_mitigate

    if [ -f "/sys/kernel/debug/sched_features" ]; then
        kakangkuh NEXT_BUDDY /sys/kernel/debug/sched_features
        kakangkuh TTWU_QUEUE /sys/kernel/debug/sched_features
    fi

    if [ -d "/dev/stune/" ]; then
        kakangkuh 0 /dev/stune/top-app/schedtune.prefer_idle
        kakangkuh 1 /dev/stune/top-app/schedtune.boost
    fi

    tp_path="/proc/touchpanel"
    if [ -d "$tp_path" ]; then
        kakangkuh 0 $tp_path/game_switch_enable
        kakangkuh 1 $tp_path/oplus_tp_limit_enable
        kakangkuh 1 $tp_path/oppo_tp_limit_enable
        kakangkuh 0 $tp_path/oplus_tp_direction
        kakangkuh 0 $tp_path/oppo_tp_direction
    fi

    kakangkuh 120 /proc/sys/vm/vfs_cache_pressure

    for path in /sys/class/devfreq/*.ufshc \
        /sys/class/devfreq/mmc*; do
        devfreq_unlock "$path"
    done &

    # Restore the default CPU governor
    change_cpu_gov "$DEFAULT_CPU_GOV"

    # Unlock CPU frequency limits
    if [ -d /proc/ppm ]; then
        cpufreq_ppm_unlock
    else
        cpufreq_unlock
    fi
}

##########################################
# Powersave Profile (3)
##########################################
powersave_basic() {
    echo "Powersave Profile is not yet implemented."
    # Add your powersave mode tweaks here in the future
}

##########################################
# MAIN EXECUTION LOGIC
##########################################

# Check if an argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <mode>"
    echo "  1: Performance"
    echo "  2: Balanced"
    echo "  3: Powersave"
    exit 1
fi

MODE=$1

# Execute the corresponding function based on the mode
case $MODE in
    1)
        performance_basic
        ;;
    2)
        balanced_basic
        ;;
    3)
        powersave_basic
        ;;
    *)
        echo "Error: Invalid mode '$MODE'. Please use 1, 2, or 3."
        exit 1
        ;;
esac

exit 0
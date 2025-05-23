# EnCorinVest Functions

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
notification() {
    local TITLE="EnCorinVest"
    local MESSAGE="$1"
    local LOGO="/data/local/tmp/logo.png"
    
    su -lp 2000 -c "cmd notification post -S bigtext -t '$TITLE' -i file://$LOGO -I file://$LOGO TagEncorin '$MESSAGE'"
}
# From Encore Profiler + Utility
write() {
	[ ! -f "$2" ] && return 1
	chmod 644 "$2" >/dev/null 2>&1
	echo "$1" >"$2" 2>/dev/null
}
which_maxfreq() {
	tr ' ' '\n' <"$1" | sort -nr | head -n 1
}

which_minfreq() {
	tr ' ' '\n' <"$1" | grep -v '^[[:space:]]*$' | sort -n | head -n 1
}

devfreq_max_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_maxfreq "$1/available_frequencies")
	tweak "$freq" "$1/max_freq"
	tweak "$freq" "$1/min_freq"
}

devfreq_unlock() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	min_freq=$(which_minfreq "$1/available_frequencies")
	write "$max_freq" "$1/max_freq"
	write "$min_freq" "$1/min_freq"
}

devfreq_min_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_minfreq "$1/available_frequencies")
	tweak "$freq" "$1/min_freq"
	tweak "$freq" "$1/max_freq"
}

change_cpu_gov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

change_cpu_gov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

encore_perfcommon() {
	for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
		# Disable I/O statistics accounting
		tweak 0 "$dir/queue/iostats"

		# Reduce the maximum number of I/O requests in exchange for latency
		tweak 64 "$dir/queue/nr_requests"

		# Don't use I/O as random spice
		tweak 0 "$dir/queue/add_random"
	done &

	# Networking tweaks
	if grep -q bbr2 /proc/sys/net/ipv4/tcp_available_congestion_control; then
		tweak "bbr2" /proc/sys/net/ipv4/tcp_congestion_control
	else
		tweak "cubic" /proc/sys/net/ipv4/tcp_congestion_control
	fi

	tweak 1 /proc/sys/net/ipv4/tcp_low_latency
	tweak 1 /proc/sys/net/ipv4/tcp_ecn
	tweak 3 /proc/sys/net/ipv4/tcp_fastopen
	tweak 1 /proc/sys/net/ipv4/tcp_sack
	tweak 0 /proc/sys/net/ipv4/tcp_timestamps

	# Stop tracing and debugging
	tweak 0 /sys/kernel/ccci/debug
	tweak 0 /sys/kernel/tracing/tracing_on
	tweak 0 /proc/sys/kernel/perf_event_paranoid
	tweak 0 /proc/sys/kernel/debug_locks
	tweak 0 /proc/sys/kernel/perf_cpu_time_max_percent
	tweak off /proc/sys/kernel/printk_devkmsg
	stop logd
	stop traced
	stop statsd

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
	tweak 120 /proc/sys/vm/stat_interval

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
}

encore_perfprofile() {
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
	for path in /sys/class/devfreq/*.ufshc; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/mmc*; do
		devfreq_max_perf "$path"
	done &

	# Force CPU to highest possible OPP
	change_cpu_gov performance

	if [ -d /proc/ppm ]; then
		cluster=0
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
			tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
			tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
			((cluster++))
		done
	fi

	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		tweak "$cpu_maxfreq" "$path/scaling_max_freq"
		tweak "$cpu_maxfreq" "$path/scaling_min_freq"
	done
	chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq

	# I/O Tweaks
	for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
		# Reduce heuristic read-ahead in exchange for I/O latency
		tweak 32 "$dir/queue/read_ahead_kb"
	done &

	echo 3 >/proc/sys/vm/drop_caches
}

# Encore Normal SCript 

encore_balanced_common() {
	# We don't use it here
	# [ "$(</data/encore/dnd_gameplay)" -eq 1 ] && set_dnd 0

	# Disable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
		if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
			tweak 0 /sys/module/battery_saver/parameters/enabled
		else
			tweak N /sys/module/battery_saver/parameters/enabled
		fi
	}

	# Enable split lock mitigation
	tweak 1 /proc/sys/kernel/split_lock_mitigate

	if [ -f "/sys/kernel/debug/sched_features" ]; then
		# Consider scheduling tasks that are eager to run
		tweak NEXT_BUDDY /sys/kernel/debug/sched_features

		# Schedule tasks on their origin CPU if possible
		tweak TTWU_QUEUE /sys/kernel/debug/sched_features
	fi

	if [ -d "/dev/stune/" ]; then
		# We are not concerned with prioritizing latency
		tweak 0 /dev/stune/top-app/schedtune.prefer_idle

		# Mark top-app as boosted, find high-performing CPUs
		tweak 1 /dev/stune/top-app/schedtune.boost
	fi

	# Oppo/Oplus/Realme Touchpanel
	tp_path="/proc/touchpanel"
	if [ -d "$tp_path" ]; then
		tweak 0 $tp_path/game_switch_enable
		tweak 1 $tp_path/oplus_tp_limit_enable
		tweak 1 $tp_path/oppo_tp_limit_enable
		tweak 0 $tp_path/oplus_tp_direction
		tweak 0 $tp_path/oppo_tp_direction
	fi

	# Memory Tweaks
	tweak 120 /proc/sys/vm/vfs_cache_pressure

	# eMMC and UFS frequency
	for path in /sys/class/devfreq/*.ufshc; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/mmc*; do
		devfreq_unlock "$path"
	done &

	if [ -d /proc/ppm ]; then
		integer cluster=0
		for path in /sys/devices/system/cpu/cpufreq/policy*; do
			cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
			cpu_minfreq=$(<"$path/cpuinfo_min_freq")
			write "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
			write "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
			((cluster++))
		done
	fi

	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		write "$cpu_maxfreq" "$path/scaling_max_freq"
		write "$cpu_minfreq" "$path/scaling_min_freq"
	done
	chmod -f 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq

	# I/O Tweaks
	for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
		# Reduce heuristic read-ahead in exchange for I/O latency
		tweak 128 "$dir/queue/read_ahead_kb"
	done &
}

corin_powersave_common() {

# Borrow old Encore Scripts

# Enable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
	if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
		tweak 1 /sys/module/battery_saver/parameters/enabled
	else
		tweak Y /sys/module/battery_saver/parameters/enabled
	fi
}

# Take from Balanced script
# Disable split lock mitigation
	tweak 0 /proc/sys/kernel/split_lock_mitigate

if [ -f "/sys/kernel/debug/sched_features" ]; then
    # Consider scheduling tasks that are eager to run
    if grep -qo '[0-9]\+' /sys/kernel/debug/sched_features; then
		tweak NEXT_BUDDY /sys/kernel/debug/sched_features
    fi

	# Schedule tasks on their origin CPU if possible
	tweak TTWU_QUEUE /sys/kernel/debug/sched_features
fi

if [ -d "/dev/stune/" ]; then
    # We are not concerned with prioritizing latency
    if grep -qo '[0-9]\+' /sys/kernel/debug/sched_features; then
		tweak 0 /dev/stune/top-app/schedtune.prefer_idle
    fi

	# Mark top-app as boosted, find high-performing CPUs
	tweak 1 /dev/stune/top-app/schedtune.boost
fi

# Oppo/Oplus/Realme Touchpanel
tp_path="/proc/touchpanel"
if [ -d tp_path ]; then
	tweak "0" $tp_path/game_switch_enable
	tweak "1" $tp_path/oplus_tp_limit_enable
	tweak "1" $tp_path/oppo_tp_limit_enable
	tweak "0" $tp_path/oplus_tp_direction
	tweak "0" $tp_path/oppo_tp_direction
fi

# Memory Tweaks
tweak 120 /proc/sys/vm/vfs_cache_pressure

# eMMC and UFS governor
for path in /sys/class/devfreq/*.ufshc; do
	tweak simple_ondemand $path/governor
done &
for path in /sys/class/devfreq/mmc*; do
	tweak simple_ondemand $path/governor
done &

# Restore min CPU frequency
for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak "$default_cpu_gov" "$path/scaling_governor"
done &
tweak 1 /sys/devices/system/cpu/cpu1/online

if [ -d /proc/ppm ]; then
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
		cpu_minfreq=$(cat $path/cpuinfo_min_freq)
		tweak "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		tweak "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
	fi

for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
		cpu_minfreq=$(cat $path/cpuinfo_min_freq)
		tweak "$cpu_minfreq" $path/scaling_max_freq
		tweak "$cpu_minfreq" $path/scaling_min_freq
	done
chmod 644 /sys/devices/virtual/thermal/thermal_message/cpu_limits

# I/O Tweaks
for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
	# Reduce heuristic read-ahead in exchange for I/O latency
	tweak 128 "$dir/queue/read_ahead_kb"
done &

# Switch to powersave
for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak powersave $path/scaling_governor
done 
}

# CPU Detection | Must be at last!
ambatusoc() {
    detect_soc() {
        local chipset=""
        
        if [ -f "/proc/cpuinfo" ]; then
            chipset=$(grep -E "Hardware|Processor" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')
        fi
        
        # If empty, check Android properties
        if [ -z "$chipset" ]; then
            if command -v getprop >/dev/null 2>&1; then
                chipset="$(getprop ro.board.platform) $(getprop ro.hardware)"
            fi
        fi
        echo "$chipset"
    }

    chipset=$(detect_soc)
    chipset_lower=$(echo "$chipset" | tr '[:upper:]' '[:lower:]')

    case "$chipset_lower" in
        *mt* | *MT*) 
            echo "- Implementing tweaks for Mediatek"
            mediatek
            ;;
       *sm* | *qcom* | *SM* | *QCOM* | *Qualcomm*) 
            echo "- Implementing tweaks for Snapdragon"
            snapdragon
            ;;
        *exynos* | *Exynos* | *EXYNOS* | *universal* | *samsung* | *erd* | *s5e*) 
            echo "- Implementing tweaks for Exynos"
            exynos
            ;;
        *Unisoc* | *unisoc* | *ums*)
            echo "- Implementing tweaks for Unisoc"
            unisoc
            ;;
        *) 
            echo "- Unknown chipset: $chipset"
            echo "- No tweaks applied."
            ;;
    esac
}

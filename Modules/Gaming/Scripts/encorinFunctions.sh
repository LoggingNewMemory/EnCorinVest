# Disable encore lite mode
LITE_MODE=0
# Set mitigation
DEVICE_MITIGATION=0

#######################
# EnCorinVest Functions
#######################

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

# Replace encore Governor logic

if [ -f "$FIRST_POLICY/scaling_available_governors" ]; then
    if grep -q 'schedhorizon' "$FIRST_POLICY/scaling_available_governors"; then
        DEFAULT_CPU_GOV="schedhorizon"
    else
        DEFAULT_CPU_GOV="schedutil"
    fi
else
    # Fallback if no policies found
    DEFAULT_CPU_GOV="schedutil"
fi

# Taken from encore_utility
# Thanks to Rem01 Gaming, definitely helping to reduce suddent lag bcs of notification
dnd_off() {
	DND=$(grep "^DND" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
	if [ "$DND" = "Yes" ]; then
		cmd notification set_dnd off
	fi
}

dnd_on() {
	DND=$(grep "^DND" /data/adb/modules/EnCorinVest/encorin.txt | cut -d'=' -f2 | tr -d ' ')
	if [ "$DND" = "Yes" ]; then
		cmd notification set_dnd priority
	fi
}

##################################
# BYPASS CHARGING SWITCH
##################################

SCRIPT_PATH="/data/adb/modules/EnCorinVest/Scripts"

##################################
# BYPASS CHARGING SWITCH
##################################

SCRIPT_PATH="/data/adb/modules/EnCorinVest/Scripts"

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

###########################################
# EnCorinVest Logging Functions
###########################################

# Configuration
ENCORIN_LOG_FILE="/data/EnCorinVest/EnCorinVest.log"
ENCORIN_LOG_DIR="/data/EnCorinVest"
MAX_ENCORIN_LOG_SIZE=5242880  # 5MB limit

# Create log directory
mkdir -p "$ENCORIN_LOG_DIR"

# Delete and recreate log if too large
rotate_encorin_log() {
    if [ -f "$ENCORIN_LOG_FILE" ] && [ $(stat -c%s "$ENCORIN_LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_ENCORIN_LOG_SIZE ]; then
        tail -n 2000 "$ENCORIN_LOG_FILE" > "${ENCORIN_LOG_FILE}.tmp" 2>/dev/null
        mv "${ENCORIN_LOG_FILE}.tmp" "$ENCORIN_LOG_FILE" 2>/dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log rotated" >> "$ENCORIN_LOG_FILE"
    fi
}

# Capture kernel messages (dmesg)
capture_dmesg() {
    local context="$1"
    local lines="${2:-50}"
    
    {
        echo "=== DMESG [$context] ==="
        dmesg -T 2>/dev/null | tail -n $lines || dmesg 2>/dev/null | tail -n $lines
        echo "=== END DMESG ==="
    } >> "$ENCORIN_LOG_FILE"
}

# Capture system logs (logcat)
capture_logcat() {
    local context="$1"
    local lines="${2:-50}"
    
    {
        echo "=== LOGCAT [$context] ==="
        logcat -d -t $lines 2>/dev/null | tail -n $lines
        echo "=== END LOGCAT ==="
    } >> "$ENCORIN_LOG_FILE"
}

# Log message with timestamp
log_encorin() {
    rotate_encorin_log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ENCORIN_LOG_FILE"
}

# Main logging function to call at end of other functions
log_execution() {
    local function_name="$1"
    local status="${2:-INVESTIGATING}"
    
    log_encorin "=== FREEZE INVESTIGATION: $function_name [$status] ==="
    capture_dmesg "$function_name" 100
    capture_logcat "$function_name" 100
    log_encorin "=== END FREEZE INVESTIGATION: $function_name ==="
    echo "" >> "$ENCORIN_LOG_FILE"
}

# Initialize logging
log_encorin "EnCorinVest Logging Started"

################################
# From Encore Profiler + Utility
################################

# Encore Utility
change_cpu_gov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

# Encore Profiler 

apply() {
	[ ! -f "$2" ] && return 1
	chmod 644 "$2" >/dev/null 2>&1
	echo "$1" >"$2" 2>/dev/null
	chmod 444 "$2" >/dev/null 2>&1
}

write() {
	[ ! -f "$2" ] && return 1
	chmod 644 "$2" >/dev/null 2>&1
	echo "$1" >"$2" 2>/dev/null
}

change_cpu_gov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	chmod 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_governor
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

# MediaTek gpufreq
# Returns OPP index of the frequency

mtk_gpufreq_minfreq_index() {
	awk -F'[][]' '{print $2}' "$1" | tail -n 1
}

mtk_gpufreq_midfreq_index() {
	total_opp=$(wc -l <"$1")
	mid_opp=$(((total_opp + 1) / 2))
	awk -F'[][]' '{print $2}' "$1" | head -n $mid_opp | tail -n 1
}

###################################
# Frequency settings
###################################

cpufreq_ppm_max_perf() {
	cluster=-1
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		((cluster++))
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		apply "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq

		[ $LITE_MODE -eq 1 ] && {
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			apply "$cluster $cpu_midfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
			continue
		}

		apply "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
	done
}

cpufreq_max_perf() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		apply "$cpu_maxfreq" "$path/scaling_max_freq"

		[ $LITE_MODE -eq 1 ] && {
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			apply "$cpu_midfreq" "$path/scaling_min_freq"
			continue
		}

		apply "$cpu_maxfreq" "$path/scaling_min_freq"
	done
	chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
}

cpufreq_ppm_unlock() {
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		write "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		write "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
}

cpufreq_unlock() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_maxfreq=$(<"$path/cpuinfo_max_freq")
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		write "$cpu_maxfreq" "$path/scaling_max_freq"
		write "$cpu_minfreq" "$path/scaling_min_freq"
	done
	chmod -f 644 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
}

devfreq_max_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	apply "$max_freq" "$1/max_freq"
	apply "$max_freq" "$1/min_freq"
}

devfreq_mid_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	mid_freq=$(which_midfreq "$1/available_frequencies")
	apply "$max_freq" "$1/max_freq"
	apply "$mid_freq" "$1/min_freq"
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
	apply "$freq" "$1/min_freq"
	apply "$freq" "$1/max_freq"
}

qcom_cpudcvs_max_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_maxfreq "$1/available_frequencies")
	apply "$freq" "$1/hw_max_freq"
	apply "$freq" "$1/hw_min_freq"
}

qcom_cpudcvs_mid_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	mid_freq=$(which_midfreq "$1/available_frequencies")
	apply "$max_freq" "$1/hw_max_freq"
	apply "$mid_freq" "$1/hw_min_freq"
}

qcom_cpudcvs_unlock() {
	[ ! -f "$1/available_frequencies" ] && return 1
	max_freq=$(which_maxfreq "$1/available_frequencies")
	min_freq=$(which_minfreq "$1/available_frequencies")
	write "$max_freq" "$1/hw_max_freq"
	write "$min_freq" "$1/hw_min_freq"
}

qcom_cpudcvs_min_perf() {
	[ ! -f "$1/available_frequencies" ] && return 1
	freq=$(which_minfreq "$1/available_frequencies")
	apply "$freq" "$1/hw_min_freq"
	apply "$freq" "$1/hw_max_freq"
}

#################################
# CPU Minumum (Modified from Encore max CPU)
#################################

cpufreq_ppm_min_perf() {
	cluster=-1
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		((cluster++))
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		apply "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq

		[ $LITE_MODE -eq 1 ] && {
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			apply "$cluster $cpu_midfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
			continue
		}

		apply "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
	done
}

cpufreq_min_perf() {
	for path in /sys/devices/system/cpu/*/cpufreq; do
		cpu_minfreq=$(<"$path/cpuinfo_min_freq")
		apply "$cpu_minfreq" "$path/scaling_max_freq"

		[ $LITE_MODE -eq 1 ] && {
			cpu_midfreq=$(which_midfreq "$path/scaling_available_frequencies")
			apply "$cpu_midfreq" "$path/scaling_min_freq"
			continue
		}

		apply "$cpu_minfreq" "$path/scaling_min_freq"
	done
	chmod -f 444 /sys/devices/system/cpu/cpufreq/policy*/scaling_*_freq
}

###############################
# Encore common scripts
###############################

encore_perfcommon() {
	# I/O Tweaks
	for dir in /sys/block/*; do
		# Disable I/O statistics accounting
		apply 0 "$dir/queue/iostats"

		# Don't use I/O as random spice
		apply 0 "$dir/queue/add_random"
	done &

	# Networking tweaks
	for algo in bbr3 bbr2 bbrplus bbr westwood cubic; do
		if grep -q "$algo" /proc/sys/net/ipv4/tcp_available_congestion_control; then
			apply "$algo" /proc/sys/net/ipv4/tcp_congestion_control
			break
		fi
	done

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

encore_perfprofile() {
	# Disable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
		if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
			apply 0 /sys/module/battery_saver/parameters/enabled
		else
			apply N /sys/module/battery_saver/parameters/enabled
		fi
	}

	# Disable split lock mitigation
	apply 0 /proc/sys/kernel/split_lock_mitigate

	if [ -f "/sys/kernel/debug/sched_features" ]; then
		# Consider scheduling tasks that are eager to run
		apply NEXT_BUDDY /sys/kernel/debug/sched_features

		# Some sources report large latency spikes during large migrations
		apply NO_TTWU_QUEUE /sys/kernel/debug/sched_features
	fi

	if [ -d "/dev/stune/" ]; then
		# Prefer to schedule top-app tasks on idle CPUs
		apply 1 /dev/stune/top-app/schedtune.prefer_idle

		# Mark top-app as boosted, find high-performing CPUs
		apply 1 /dev/stune/top-app/schedtune.boost
	fi

	# Oppo/Oplus/Realme Touchpanel
	tp_path="/proc/touchpanel"
	if [ -d "$tp_path" ]; then
		apply 1 $tp_path/game_switch_enable
		apply 0 $tp_path/oplus_tp_limit_enable
		apply 0 $tp_path/oppo_tp_limit_enable
		apply 1 $tp_path/oplus_tp_direction
		apply 1 $tp_path/oppo_tp_direction
	fi

	# Memory tweak
	apply 80 /proc/sys/vm/vfs_cache_pressure

	# eMMC and UFS frequency
	for path in /sys/class/devfreq/*.ufshc \
		/sys/class/devfreq/mmc*; do

		[ $LITE_MODE -eq 1 ] &&
			devfreq_mid_perf "$path" ||
			devfreq_max_perf "$path"
	done &

	# Set CPU governor to performance.
	# performance governor in this case is only used for "flex"
	# since the frequencies already maxed out (ifykyk).
	# If lite mode enabled, use the default governor instead.
	# device mitigation also will prevent performance gov to be
	# applied (some device hates performance governor).
	[ $LITE_MODE -eq 0 ] && [ $DEVICE_MITIGATION -eq 0 ] &&
		change_cpu_gov performance ||
		change_cpu_gov "$DEFAULT_CPU_GOV"

	# Force CPU to highest possible frequency.
	[ -d /proc/ppm ] && cpufreq_ppm_max_perf || cpufreq_max_perf

	# I/O Tweaks
	for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
		# Reduce heuristic read-ahead in exchange for I/O latency
		apply 32 "$dir/queue/read_ahead_kb"

		# Reduce the maximum number of I/O requests in exchange for latency
		apply 32 "$dir/queue/nr_requests"
	done &

	echo 3 >/proc/sys/vm/drop_caches
}

# Encore Normal SCript 

encore_balanced_common() {
	# Disable battery saver module
	[ -f /sys/module/battery_saver/parameters/enabled ] && {
		if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
			apply 0 /sys/module/battery_saver/parameters/enabled
		else
			apply N /sys/module/battery_saver/parameters/enabled
		fi
	}

	# Enable split lock mitigation
	apply 1 /proc/sys/kernel/split_lock_mitigate

	if [ -f "/sys/kernel/debug/sched_features" ]; then
		# Consider scheduling tasks that are eager to run
		apply NEXT_BUDDY /sys/kernel/debug/sched_features

		# Schedule tasks on their origin CPU if possible
		apply TTWU_QUEUE /sys/kernel/debug/sched_features
	fi

	if [ -d "/dev/stune/" ]; then
		# We are not concerned with prioritizing latency
		apply 0 /dev/stune/top-app/schedtune.prefer_idle

		# Mark top-app as boosted, find high-performing CPUs
		apply 1 /dev/stune/top-app/schedtune.boost
	fi

	# Oppo/Oplus/Realme Touchpanel
	tp_path="/proc/touchpanel"
	if [ -d "$tp_path" ]; then
		apply 0 $tp_path/game_switch_enable
		apply 1 $tp_path/oplus_tp_limit_enable
		apply 1 $tp_path/oppo_tp_limit_enable
		apply 0 $tp_path/oplus_tp_direction
		apply 0 $tp_path/oppo_tp_direction
	fi

	# Memory Tweaks
	apply 120 /proc/sys/vm/vfs_cache_pressure

	# eMMC and UFS frequency
	for path in /sys/class/devfreq/*.ufshc \
		/sys/class/devfreq/mmc*; do
		devfreq_unlock "$path"
	done &

	# Restore min CPU frequency
	change_cpu_gov "$DEFAULT_CPU_GOV"
	[ -d /proc/ppm ] && cpufreq_ppm_unlock || cpufreq_unlock

	# I/O Tweaks
	for dir in /sys/block/mmcblk0 /sys/block/mmcblk1 /sys/block/sd*; do
		# Reduce heuristic read-ahead in exchange for I/O latency
		apply 128 "$dir/queue/read_ahead_kb"

		# Reduce the maximum number of I/O requests in exchange for latency
		apply 64 "$dir/queue/nr_requests"
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

# Set min CPU frequency
[ -d /proc/ppm ] && cpufreq_ppm_min_perf || cpufreq_min_perf

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

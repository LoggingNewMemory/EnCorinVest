tweak() {
    if [ -f $2 ]; then
        chmod 644 $2 >/dev/null 2>&1
        echo $1 >$2 2>/dev/null
        chmod 444 $2 >/dev/null 2>&1
    fi
}

# Switch to powersave
for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak powersave $path/scaling_governor
done &

# Set CPU Freq to Minimum

for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak "$default_cpu_gov" "$path/scaling_governor"
done &

if [ -d /proc/ppm ]; then
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
		cpu_minfreq=$(cat $path/cpuinfo_min_freq)
		# Set the hard user limit to the minimum frequency
		tweak "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		tweak "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
fi

for path in /sys/devices/system/cpu/*/cpufreq; do
	cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
	cpu_minfreq=$(cat $path/cpuinfo_min_freq)
	# Set the scaling frequencies to the minimum frequency
	tweak "$cpu_minfreq" $path/scaling_max_freq
	tweak "$cpu_minfreq" $path/scaling_min_freq
done

# Enable Battery Efficient Mode
cmd power set-adaptive-power-saver-enabled true
cmd looper_stats enable

# Set Low Power Mode
settings put global low_power 1

# Adjust VM settings for cooling
for vmtweak in /proc/sys/vm; do
    tweak 0 "$vmtweak/vfs_cache_pressure"
    tweak 1 "$vmtweak/stat_interval"
    tweak 20 "$vmtweak/compaction_proactiveness"
    tweak 80 "$vmtweak/page-cluster"
done &

# Notify Cooling Status
su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest Cooling - カリン・ウィクス & 安可'"

sleep 120

# Balanced Script

for queue in /sys/block/sd*/queue; do

    tweak 0 "$queue/add_random"
    tweak 0 "$queue/iostats"
    tweak 2 "$queue/nomerges"
    tweak 2 "$queue/rq_affinity"
    tweak 0 "$queue/rotational"
    tweak 128 "$queue/nr_requests"
    tweak 128 "$queue/read_ahead_kb"

done &

# Restore CPU Perf

for cpuadd_perf in /sys/devices/system/cpu/perf; do

    tweak 0 "$cpuadd_perf/enable"
    tweak 0 "$cpuadd_perf/gpu_pmu_enable"
    tweak 0 "$cpuadd_perf/fuel_gauge_enable"
    tweak 0 "$cpuadd_perf/charger_enable"
    tweak 0 "$cpuadd_perf/enable"

done &

# Network Tweaks

tweak "cubic" /proc/sys/net/ipv4/tcp_congestion_control

for netweak in /proc/sys/net/ipv4; do

    tweak 0 "$netweak/tcp_low_latency"
    tweak 2 "$netweak/tcp_ecn"
    tweak 1 "$netweak/tcp_fastopen"
    tweak 1 "$netweak/tcp_sack"
    tweak 1 "$netweak/tcp_timestamps"

done &

for schedtweak in /sys/devices/system/cpu/cpufreq/schedutil; do

    tweak 1000 "$schedtweak/rate_limit_us"

done &

tweak menu /sys/devices/system/cpu/cpuidle/current_governor
tweak 0 /sys/module/kernel/parameters/panic_on_warn

for vmtweak in /proc/sys/vm; do
    tweak 0 "$vmtweak/page-cluster"
    tweak 1 "$vmtweak/stat_interval"
    tweak 20 "$vmtweak/compaction_proactiveness"
    tweak 80 "$vmtweak/vfs_cache_pressure"
done &

for schedtweak in /sys/devices/system/cpu/cpufreq/schedutil; do

    tweak 1000 "$schedtweak/rate_limit_us"

done &

if [ -f "/sys/kernel/debug/sched_features" ]; then
	# Consider scheduling tasks that are eager to run
	tweak NEXT_BUDDY "/sys/kernel/debug/sched_features"

	# Some sources report large latency spikes during large migrations
	tweak TTWU_QUEUE "/sys/kernel/debug/sched_features"
fi

if [ -f /proc/ppm/policy_status ]; then
	policy_file="/proc/ppm/policy_status"
	pwr_thro_idx=$(grep 'PPM_POLICY_PWR_THRO' $policy_file | sed 's/.*\[\(.*\)\].*/\1/')
	thermal_idx=$(grep 'PPM_POLICY_THERMAL' $policy_file | sed 's/.*\[\(.*\)\].*/\1/')

	tweak "$pwr_thro_idx 1" $policy_file
	tweak "$thermal_idx 1" $policy_file
fi

for proccpu in /proc/cpufreq; do
    tweak 0 "$proccpu/cpufreq_cci_mode"
    tweak 0 "$proccpu/cpufreq_power_mode"
    tweak 0 "$proccpu/cpufreq_sched_disable"
done &

# GPU Frequency
if [ -d /proc/gpufreq ]; then
	tweak 0 /proc/gpufreq/gpufreq_opp_freq
elif [ -d /proc/gpufreqv2 ]; then
	tweak -1 /proc/gpufreqv2/fix_target_opp_index
    tweak enable /proc/gpufreqv2/aging_mode
fi

# Disable battery current limiter

tweak "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop

# DRAM Tweak
tweak -1 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
tweak -1 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
tweak "userspace" /sys/class/devfreq/mtk-dvfsrc-devfreq/governor
tweak "userspace" /sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor

# eMMC and UFS governor
for path in /sys/class/devfreq/*.ufshc; do
	tweak simple_ondemand $path/governor
done &
for path in /sys/class/devfreq/mmc*; do
	tweak simple_ondemand $path/governor
done &

tweak 100 /proc/sys/vm/vfs_cache_pressure

# Restore Devfreq Frequencies

DEVFREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/available_frequencies"
MIN_FREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/min_freq"
MAX_FREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/max_freq"

frequencies=$(tr ' ' '\n' < "$DEVFREQ_FILE" | grep -E '^[0-9]+$' | sort -n)

lowest_freq=$(echo "$frequencies" | head -n 1)
highest_freq=$(echo "$frequencies" | tail -n 1)

# Restore default CPU Frequency 

# Switch to schedutil
for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak schedutil $path/scaling_governor
done &

# Restore Default CPU Freq

for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak "$default_cpu_gov" "$path/scaling_governor"
done &

if [ -d /proc/ppm ]; then
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
		cpu_minfreq=$(cat $path/cpuinfo_min_freq)
		tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		tweak "$cluster $cpu_minfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
fi

for path in /sys/devices/system/cpu/*/cpufreq; do
	cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
	cpu_minfreq=$(cat $path/cpuinfo_min_freq)
	tweak "$cpu_maxfreq" $path/scaling_max_freq
	tweak "$cpu_minfreq" $path/scaling_min_freq
done

# Enable Battery Efficient

cmd power set-adaptive-power-saver-enabled true
cmd looper_stats enable

# Power Save Mode Off
settings put global low_power 0

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest Cooling Done - カリン・ウィクス & 安可'"

wait
exit 0

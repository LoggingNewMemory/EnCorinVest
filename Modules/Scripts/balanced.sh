sync

tweak() {
	if [ -f $2 ]; then
		chmod 644 $2 >/dev/null 2>&1
		echo $1 >$2 2>/dev/null
		chmod 444 $2 >/dev/null 2>&1
	fi
}

# Encore Script

# IO Tweaks

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

# Restore CCCI & debug
tweak 2 /sys/kernel/ccci/debug
tweak 0 /sys/kernel/tracing/tracing_on

for kernelperfdebug in /proc/sys/kernel; do
    tweak -1 "$kernelperfdebug/perf_event_paranoid"
    tweak 75 "$kernelperfdebug/perf_cpu_time_max_percent"

    tweak on "$kernelperfdebug/printk_devkmsg"
    tweak 1 "$kernelperfdebug/sched_schedstats"
    tweak 0 "$kernelperfdebug/sched_child_runs_first"
    tweak 32 "$kernelperfdebug/sched_nr_migrate"
    tweak 1 "$kernelperfdebug/sched_migration_cost_ns"
    tweak 3000000 "$kernelperfdebug/sched_min_granularity_ns"
    tweak 2000000 "$kernelperfdebug/sched_wakeup_granularity_ns"

    tweak 1000000 "$kernelperfdebug/sched_latency_ns"
    tweak 256 "$kernelperfdebug/sched_util_clamp_max"
    tweak 256 "$kernelperfdebug/sched_util_clamp_min"
    tweak 0 "$kernelperfdebug/sched_tunable_scaling"
    tweak 1 "$kernelperfdebug/sched_energy_aware"
    tweak 0 "$kernelperfdebug/sched_util_clamp_min_rt_default"
    tweak 4194304 "$kernelperfdebug/sched_deadline_period_max_us"
    tweak 100 "$kernelperfdebug/sched_deadline_period_min_us"

    tweak 1000000 "$kernelperfdebug/sched_rt_period_us"
    tweak 950000 "$kernelperfdebug/sched_rt_runtime_us"
    tweak 1 "$kernelperfdebug/sched_pelt_multiplier"
    tweak -1 "$kernelperfdebug/panic"
    tweak 1 "$kernelperfdebug/panic_on_oops"
    tweak 0 "$kernelperfdebug/panic_on_rcu_stall"
    tweak 0 "$kernelperfdebug/panic_on_warn"
    tweak 7 4 1 7 "$kernelperfdebug/printk"
    tweak on "$kernelperfdebug/printk_devkmsg"

done &

tweak menu /sys/devices/system/cpu/cpuidle/current_governor
tweak 0 /sys/module/kernel/parameters/panic_on_warn

for vmtweak in /proc/sys/vm; do
    tweak 0 "$vmtweak/page-cluster"
    tweak 1 "$vmtweak/stat_interval"
    tweak 20 "$vmtweak/compaction_proactiveness"
    tweak 80 "$vmtweak/vfs_cache_pressure"
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

# Restore CPU Frequency

for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak schedutil $path/scaling_governor
done &

# Corin X MTKVest Script

for cpus in /sys/devices/system/cpu/cpu*/online; do
    tweak 1 $cpus 2>/dev/null
done

tweak 1 /proc/trans_scheduler/enable
tweak 0 /proc/game_state
tweak always_on /sys/class/misc/mali0/device/power_policy

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

for policy in /sys/devices/system/cpu/cpufreq/policy*/; do
    if [ -d "$policy" ]; then
        chmod 644 "${policy}scaling_max_freq"
        chmod 644 "${policy}scaling_min_freq"

        default_max=$(cat "${policy}cpuinfo_max_freq")
        default_min=$(cat "${policy}cpuinfo_min_freq")

        echo "$default_max" > "${policy}scaling_max_freq"
        echo "$default_min" > "${policy}scaling_min_freq"

    fi
done

# Restore default CPU Value

for cpuset_tweak in /dev/cpuset
    do
		tweak "0-6" $cpuset_tweak/cpus
		tweak "0-1" $cpuset_tweak/background/cpus
		tweak "0-3" $cpuset_tweak/system-background/cpus
		tweak "0-6" $cpuset_tweak/foreground/cpus
		tweak "0-6" $cpuset_tweak/top-app/cpus
		tweak "0-2" $cpuset_tweak/restricted/cpus
		tweak "0-6" $cpuset_tweak/camera-daemon/cpus
        tweak 0 $cpuset_tweak/memory_pressure_enabled
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground/sched_load_balance
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground-l/sched_load_balance
        tweak 1 $cpuset_tweak/dex2oat/sched_load_balance
    done

    for cpuctl_tweak in /dev/cpuctl
    do 
        tweak 0 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
        tweak 1 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive

    done

# Restore Original Memory Optimization

for memtweak in /sys/kernel/mm/transparent_hugepage
    do
        tweak never $memtweak/enabled
        tweak never $memtweak/shmem_enabled
    done

# Restore RAM Tweaks

for ramtweak in /sys/block/ram*/bdi
    do
    tweak 128 $ramtweak/read_ahead_kb
done

tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
tweak 0 /sys/module/task_turbo/parameters/feats
tweak 0 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode

# Restore Virtual Memory Tweaks

for vim_mem in /dev/memcg
    do

tweak 100 "$vim_mem/memory.swappiness"
tweak 60 "$vim_mem/apps/memory.swappiness"
tweak 60 "$vim_mem/system/memory.swappiness"

done

# Enable Battery Efficient

cmd power set-adaptive-power-saver-enabled true
cmd looper_stats enable

# Power Save Mode Off
settings put global low_power 0

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' TagBalanced 'Balanced Mode! - カリン・ウィクス'"

wait
exit 0

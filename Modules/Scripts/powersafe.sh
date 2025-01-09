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

# Disable CCCI & debug
tweak 1 /sys/kernel/ccci/debug
tweak 1 /sys/kernel/tracing/tracing_on

for kernelperfdebug in /proc/sys/kernel; do
    tweak 4 "$kernelperfdebug/perf_event_paranoid"
    
    tweak on "$kernelperfdebug/printk_devkmsg"
    tweak 1 "$kernelperfdebug/sched_schedstats"
    tweak 0 "$kernelperfdebug/sched_child_runs_first"
    
    tweak 1024 "$kernelperfdebug/sched_util_clamp_max"
    tweak 0 "$kernelperfdebug/sched_util_clamp_min"
    tweak 0 "$kernelperfdebug/sched_util_clamp_min_rt_default"
    tweak 4194304 "$kernelperfdebug/sched_deadline_period_max_us"
    tweak 100 "$kernelperfdebug/sched_deadline_period_min_us"
    
    tweak 16 "$kernelperfdebug/sched_pelt_multiplier"
    tweak 1 "$kernelperfdebug/panic"
    tweak 1 "$kernelperfdebug/panic_on_oops"
    tweak 1 "$kernelperfdebug/panic_on_rcu_stall"
    tweak 1 "$kernelperfdebug/panic_on_warn"
    tweak 4 4 1 7 "$kernelperfdebug/printk"
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

# Memory Optimization
for memtweak in /sys/kernel/mm/transparent_hugepage
    do
        tweak madvise $memtweak/enabled
        tweak madvise $memtweak/shmem_enabled
    done

# RAM Tweaks
for ramtweak in /sys/block/ram*/bdi
    do
    tweak 1024 $ramtweak/read_ahead_kb
done

tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
tweak 0 /sys/module/task_turbo/parameters/feats
tweak 0 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode

# Virtual Memory Tweaks
for vim_mem in /dev/memcg
    do
    tweak 60 "$vim_mem/memory.swappiness"
    tweak 60 "$vim_mem/apps/memory.swappiness"
    tweak 60 "$vim_mem/system/memory.swappiness"
done

# CPU Tweaks
for cpuset_tweak in /dev/cpuset
    do
        tweak 0-7 $cpuset_tweak/cpus
        tweak 0-3 $cpuset_tweak/background/cpus
        tweak 0-3 $cpuset_tweak/system-background/cpus
        tweak 0-7 $cpuset_tweak/foreground/cpus
        tweak 0-7 $cpuset_tweak/top-app/cpus
        tweak 0-3 $cpuset_tweak/restricted/cpus
        tweak 0-3 $cpuset_tweak/camera-daemon/cpus
        tweak 1 $cpuset_tweak/memory_pressure_enabled
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
        tweak 0 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive
    done

# Restore Devfreq Frequencies

DEVFREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/available_frequencies"
MIN_FREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/min_freq"
MAX_FREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/max_freq"

frequencies=$(tr ' ' '\n' < "$DEVFREQ_FILE" | grep -E '^[0-9]+$' | sort -n)

lowest_freq=$(echo "$frequencies" | head -n 1)
highest_freq=$(echo "$frequencies" | tail -n 1)

# Switch to powersave
for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak powersave $path/scaling_governor
done 

# Set CPU Freq to Minimum
for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak "$default_cpu_gov" "$path/scaling_governor"
done 

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

# Revert FPSGo & GED Parameter to Default

# FPSGo
for fpsgo in /sys/kernel/fpsgo
do
    tweak 0 $fpsgo/fbt/boost_ta
    tweak 1 $fpsgo/fbt/enable_switch_down_throttle
    tweak 1 $fpsgo/fstb/adopt_low_fps
    tweak 1 $fpsgo/fstb/fstb_self_ctrl_fps_enable
    tweak 0 $fpsgo/fstb/boost_ta
    tweak 1 $fpsgo/fstb/enable_switch_sync_flag
    tweak 0 $fpsgo/fbt/boost_VIP
    tweak 1 $fpsgo/fstb/gpu_slowdown_check
    tweak 1 $fpsgo/fbt/thrm_limit_cpu
    tweak 80 $fpsgo/fbt/thrm_temp_th
    tweak 0 $fpsgo/fbt/llf_task_policy
done

tweak 0 /sys/kernel/ged/hal/gpu_boost_level

# FPSGO Advanced
for fpsgo_adv in /sys/module/mtk_fpsgo/parameters
do
    tweak 0 $fpsgo_adv/boost_affinity
    tweak 0 $fpsgo_adv/boost_LR
    tweak 0 $fpsgo_adv/xgf_uboost
    tweak 0 $fpsgo_adv/xgf_extra_sub
    tweak 0 $fpsgo_adv/gcc_enable
    tweak 0 $fpsgo_adv/gcc_hwui_hint
done

# GED Extra
for ged_extra in /sys/module/ged/parameters
do
    tweak 0 $ged_extra/ged_smart_boost
    tweak 0 $ged_extra/boost_upper_bound
    tweak 0 $ged_extra/enable_gpu_boost
    tweak 0 $ged_extra/enable_cpu_boost
    tweak 0 $ged_extra/ged_boost_enable
    tweak 0 $ged_extra/boost_gpu_enable
    tweak 0 $ged_extra/gpu_dvfs_enable
    tweak 0 $ged_extra/gx_frc_mode
    tweak 0 $ged_extra/gx_dfps
    tweak 0 $ged_extra/gx_force_cpu_boost
    tweak 0 $ged_extra/gx_boost_on
    tweak 0 $ged_extra/gx_game_mode
    tweak 1 $ged_extra/gx_3D_benchmark_on
    tweak 1 $ged_extra/gpu_loading
    tweak 0 $ged_extra/cpu_boost_policy
    tweak 0 $ged_extra/boost_extra
    tweak 1 $ged_extra/is_GED_KPI_enabled
    tweak 0 $ged_extra/gpu_cust_boost_freq
    tweak 0 $ged_extra/gpu_cust_upbound_freq
    tweak 0 $ged_extra/gpu_bottom_freq
    tweak 0 $ged_extra/ged_smart_boost
    tweak 0 $ged_extra/enable_game_self_frc_detect
    tweak 0 $ged_extra/boost_amp
    tweak 1 $ged_extra/gpu_idle
done

tweak "default_mode" /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 00 /sys/kernel/ged/hal/custom_boost_gpu_freq

# Revert CrazyKT
for crazyKT in /proc/sys/kernel
do
    tweak 500000 $crazyKT/sched_migration_cost_ns
    tweak 25 $crazyKT/perf_cpu_time_max_percent
    tweak 18000000 $crazyKT/sched_latency_ns
    tweak 1024 $crazyKT/sched_util_clamp_max
    tweak 0 $crazyKT/sched_util_clamp_min
    tweak 1 $crazyKT/sched_tunable_scaling
    tweak 1 $crazyKT/sched_energy_aware
    tweak 32 $crazyKT/sched_nr_migrate
    tweak 16 $crazyKT/sched_pelt_multiplier
    tweak 100 $crazyKT/sched_rr_timeslice_ms
    tweak 0 $crazyKT/sched_util_clamp_min_rt_default
    tweak 4294967295 $crazyKT/sched_deadline_period_max_us
    tweak 1000 $crazyKT/sched_deadline_period_min_us
    tweak 0 $crazyKT/sched_schedstats
    tweak 3000000 $crazyKT/sched_wakeup_granularity_ns
    tweak 4000000 $crazyKT/sched_min_granularity_ns
    tweak 950000 $crazyKT/sched_rt_runtime_us
    tweak 1000000 $crazyKT/sched_rt_period_us
done

# Celestial Tweaks
# Optimize Priority with balanced values
settings put secure high_priority 0
settings put secure low_priority 1

# GPU Freq Optimization with default values
for celes_gpu in /proc/gpufreq
    do
    tweak 0 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 0 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 1 $celes_gpu/gpufreq_opp_freq
    tweak 1 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 1 $celes_gpu/gpufreq_opp_stress_test
    tweak 1 $celes_gpu/gpufreq_power_dump
    tweak 1 $celes_gpu/gpufreq_power_limited
done

# Additional Kernel Tweak with default values
for celes_kernel in /proc/sys/kernel
    do
    tweak 0 $celes_kernel/sched_autogroup_enabled
    tweak 0 $celes_kernel/sched_cstate_aware
    tweak 0 $celes_kernel/sched_sync_hint_enable
done

# Enable Battery Efficient
cmd power set-adaptive-power-saver-enabled true
cmd looper_stats enable

# Power Save Mode On
settings put global low_power 1

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest Powersave - カリン・ウィクス & 安可'"
wait
exit 0
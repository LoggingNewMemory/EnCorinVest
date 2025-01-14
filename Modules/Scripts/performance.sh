tweak() {
	if [ -f $2 ]; then
		chmod 644 $2 >/dev/null 2>&1
		echo $1 >$2 2>/dev/null
		chmod 444 $2 >/dev/null 2>&1
	fi
}

# Encore Scripts

# IO Tweaks

for queue in /sys/block/sd*/queue; do

    tweak 0 "$queue/add_random"
    tweak 0 "$queue/iostats"
    tweak 2 "$queue/nomerges"
    tweak 2 "$queue/rq_affinity"
    tweak 0 "$queue/rotational"
    tweak 64 "$queue/nr_requests"
    tweak 312 "$queue/read_ahead_kb"

done &

# Additional CPU Perf

for cpuadd_perf in /sys/devices/system/cpu/perf; do

    tweak 1 "$cpuadd_perf/enable"
    tweak 1000000 "$cpuadd_perf/gpu_pmu_enable"
    tweak 1 "$cpuadd_perf/fuel_gauge_enable"
    tweak 1 "$cpuadd_perf/charger_enable"
    tweak 1 "$cpuadd_perf/enable"

done &

# Network Tweaks

tweak "bbr2" /proc/sys/net/ipv4/tcp_congestion_control

for netweak in /proc/sys/net/ipv4; do

    tweak 1 "$netweak/tcp_low_latency"
    tweak 1 "$netweak/tcp_ecn"
    tweak 3 "$netweak/tcp_fastopen"
    tweak 1 "$netweak/tcp_sack"
    tweak 0 "$netweak/tcp_timestamps"

done &

for schedtweak in /sys/devices/system/cpu/cpufreq/schedutil; do

    tweak 10000 "$schedtweak/rate_limit_us"

done &

# Disable CCCI & debug
tweak 0 /sys/kernel/ccci/debug
tweak 0 /sys/kernel/tracing/tracing_on

for kernelperfdebug in /proc/sys/kernel; do
    tweak 0 "$kernelperfdebug/perf_event_paranoid"

    tweak off "$kernelperfdebug/printk_devkmsg"
    tweak 0 "$kernelperfdebug/sched_schedstats"
    tweak 1 "$kernelperfdebug/sched_child_runs_first"

    tweak 1024 "$kernelperfdebug/sched_util_clamp_max"
    tweak 1024 "$kernelperfdebug/sched_util_clamp_min"
    tweak 1 "$kernelperfdebug/sched_util_clamp_min_rt_default"
    tweak 4194304 "$kernelperfdebug/sched_deadline_period_max_us"
    tweak 100 "$kernelperfdebug/sched_deadline_period_min_us"

    tweak 4 "$kernelperfdebug/sched_pelt_multiplier"
    tweak 0 "$kernelperfdebug/panic"
    tweak 0 "$kernelperfdebug/panic_on_oops"
    tweak 0 "$kernelperfdebug/panic_on_rcu_stall"
    tweak 0 "$kernelperfdebug/panic_on_warn"
    tweak 0 0 0 0 "$kernelperfdebug/printk"
    tweak off "$kernelperfdebug/printk_devkmsg"

done &

tweak teo /sys/devices/system/cpu/cpuidle/current_governor
tweak 0 /sys/module/kernel/parameters/panic_on_warn

for vmtweak in /proc/sys/vm; do
    tweak 0 "$vmtweak/page-cluster"
    tweak 120 "$vmtweak/stat_interval"
    tweak 0 "$vmtweak/compaction_proactiveness"
    tweak 80 "$vmtweak/vfs_cache_pressure"
done &

if [ -f "/sys/kernel/debug/sched_features" ]; then
	# Consider scheduling tasks that are eager to run
	tweak NEXT_BUDDY "/sys/kernel/debug/sched_features"

	# Some sources report large latency spikes during large migrations
	tweak NO_TTWU_QUEUE "/sys/kernel/debug/sched_features"
fi

if [ -d /proc/ppm ]; then
	for idx in $(cat /proc/ppm/policy_status | grep -E 'PWR_THRO|THERMAL' | awk -F'[][]' '{print $2}'); do
	tweak "$idx 0" /proc/ppm/policy_status
	done
fi

for proccpu in /proc/cpufreq; do
    tweak 1 "$proccpu/cpufreq_cci_mode"
    tweak 3 "$proccpu/cpufreq_power_mode"
    tweak 1 "$proccpu/cpufreq_sched_disable"
done &

# GPU Frequency
if [ -d /proc/gpufreq ]; then
	gpu_freq="$(cat /proc/gpufreq/gpufreq_opp_dump | grep -o 'freq = [0-9]*' | sed 's/freq = //' | sort -nr | head -n 1)"
	tweak "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
elif [ -d /proc/gpufreqv2 ]; then
	tweak -1 /proc/gpufreqv2/fix_target_opp_index
    tweak disable /proc/gpufreqv2/aging_mode
fi
 
# Disable battery current limiter

tweak "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop

# DRAM Tweak
tweak 0 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
tweak "performance" /sys/class/devfreq/mtk-dvfsrc-devfreq/governor
tweak "performance" /sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor

# eMMC and UFS governor
for path in /sys/class/devfreq/*.ufshc; do
	tweak performance $path/governor
done &
for path in /sys/class/devfreq/mmc*; do
	tweak performance $path/governor
done &

tweak 80 /proc/sys/vm/vfs_cache_pressure

# Corin X MTKVest Script

for cpus in /sys/devices/system/cpu/cpu*/online; do
    tweak 1 $cpus 2>/dev/null
done

tweak 0 /proc/trans_scheduler/enable
tweak 1 /proc/game_state
tweak always_on /sys/class/misc/mali0/device/power_policy

# Devfreq Max

DEVFREQ_FILE="/sys/class/devfreq/mtk-dvfsrc-devfreq/available_frequencies"
highest_freq=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/ && $i > max) max=$i} END{print max}' "$DEVFREQ_FILE")
tweak $highest_freq /sys/class/devfreq/mtk-dvfsrc-devfreq/min_freq
tweak $highest_freq /sys/class/devfreq/mtk-dvfsrc-devfreq/max_freq

# CPU Max

# Force CPU to highest possible OPP

for path in /sys/devices/system/cpu/cpufreq/policy*; do
	tweak performance "$path/scaling_governor"
done 

if [ -d /proc/ppm ]; then
	cluster=0
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
		tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_max_cpu_freq
		tweak "$cluster $cpu_maxfreq" /proc/ppm/policy/hard_userlimit_min_cpu_freq
		((cluster++))
	done
fi

for path in /sys/devices/system/cpu/*/cpufreq; do
	cpu_maxfreq=$(cat $path/cpuinfo_max_freq)
	tweak "$cpu_maxfreq" $path/scaling_max_freq
	tweak "$cpu_maxfreq" $path/scaling_min_freq
	tweak "cpu$(awk '{print $1}' $path/affected_cpus) $cpu_maxfreq" /sys/devices/virtual/thermal/thermal_message/cpu_limits
done

# CPU Tweaks

for cpuset_tweak in /dev/cpuset
    do
        tweak 0-7 $cpuset_tweak/cpus
        tweak 0-7 $cpuset_tweak/background/cpus
        tweak 0-3 $cpuset_tweak/system-background/cpus
        tweak 0-7 $cpuset_tweak/foreground/cpus
        tweak 0-7 $cpuset_tweak/top-app/cpus
        tweak 0-3 $cpuset_tweak/restricted/cpus
        tweak 0-7 $cpuset_tweak/camera-daemon/cpus
        tweak 0 $cpuset_tweak/memory_pressure_enabled
        tweak 0 $cpuset_tweak/sched_load_balance
        tweak 0 $cpuset_tweak/foreground/sched_load_balance
        tweak 0 $cpuset_tweak/sched_load_balance
        tweak 0 $cpuset_tweak/foreground-l/sched_load_balance
        tweak 0 $cpuset_tweak/dex2oat/sched_load_balance
    done

for cpuctl_tweak in /dev/cpuctl
    do 
        tweak 1 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
        tweak 1 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
        tweak 1 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
        tweak 1 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
        tweak 1 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
        tweak 1 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive

    done

# Memory Optimization

for memtweak in /sys/kernel/mm/transparent_hugepage
    do
        tweak always $memtweak/enabled
        tweak always $memtweak/shmem_enabled
    done

# RAM Tweaks

for ramtweak in /sys/block/ram*/bdi
    do
    tweak 2048 $ramtweak/read_ahead_kb
done

tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
tweak -1 /sys/module/task_turbo/parameters/feats
tweak 1 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode

# Virtual Memory Tweaks

for vim_mem in /dev/memcg
    do

tweak 30 "$vim_mem/memory.swappiness"
tweak 30 "$vim_mem/apps/memory.swappiness"
tweak 55 "$vim_mem/system/memory.swappiness"

done

# Disable Battery Efficient

cmd power set-adaptive-power-saver-enabled false
cmd looper_stats disable

# FPSGo & GED Parameter

# FPSGo

for fpsgo in /sys/kernel/fpsgo
    do

tweak 1 $fpsgo/fbt/boost_ta
tweak 0 $fpsgo/fbt/enable_switch_down_throttle
tweak 0 $fpsgo/fstb/adopt_low_fps
tweak 0 $fpsgo/fstb/fstb_self_ctrl_fps_enable
tweak 1 $fpsgo/fstb/boost_ta
tweak 0 $fpsgo/fstb/enable_switch_sync_flag
tweak 1 $fpsgo/fbt/boost_VIP
tweak 0 $fpsgo/fstb/gpu_slowdown_check
tweak 0 $fpsgo/fbt/thrm_limit_cpu
tweak 100 $fpsgo/fbt/thrm_temp_th
tweak 2 $fpsgo/fbt/llf_task_policy
done

tweak 101 /sys/kernel/ged/hal/gpu_boost_level

# FPSGO Advanced

for fpsgo_adv in /sys/module/mtk_fpsgo/parameters
    do
tweak 1 $fpsgo_adv/boost_affinity
tweak 1 $fpsgo_adv/boost_LR
tweak 1 $fpsgo_adv/xgf_uboost
tweak 1 $fpsgo_adv/xgf_extra_sub
tweak 1 $fpsgo_adv/gcc_enable
tweak 1 $fpsgo_adv/gcc_hwui_hint
done

# GED Extra

for ged_extra in /sys/module/ged/parameters
    do
tweak 1 $ged_extra/ged_smart_boost
tweak 100 $ged_extra/boost_upper_bound
tweak 1 $ged_extra/enable_gpu_boost
tweak 1 $ged_extra/enable_cpu_boost
tweak 1 $ged_extra/ged_boost_enable
tweak 1 $ged_extra/boost_gpu_enable
tweak 1 $ged_extra/gpu_dvfs_enable
tweak 1 $ged_extra/gx_frc_mode
tweak 1 $ged_extra/gx_dfps
tweak 1 $ged_extra/gx_force_cpu_boost
tweak 1 $ged_extra/gx_boost_on
tweak 1 $ged_extra/gx_game_mode
tweak 1 $ged_extra/gx_3D_benchmark_on
tweak 0 $ged_extra/gpu_loading
tweak 1 $ged_extra/cpu_boost_policy
tweak 1 $ged_extra/boost_extra
tweak 0 $ged_extra/is_GED_KPI_enabled
tweak 1500000 $ged_extra/gpu_cust_boost_freq
tweak 1800000 $ged_extra/gpu_cust_upbound_freq
tweak 600000 $ged_extra/gpu_bottom_freq
tweak 500 $ged_extra/ged_smart_boost
tweak 1 $ged_extra/enable_game_self_frc_detect
tweak 1 $ged_extra/boost_amp
tweak 0 $ged_extra/gpu_idle
done

tweak "default_mode" /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 00 /sys/kernel/ged/hal/custom_boost_gpu_freq

# PKT Performance

tweak 0 /sys/module/kernel/parameters/panic
tweak 0 /proc/sys/kernel/panic_on_oops
tweak 0 /sys/module/kernel/parameters/panic_on_warn
tweak 0 /sys/module/kernel/parameters/pause_on_oops
tweak 0 /proc/sys/vm/panic_on_oom

tweak 1 /proc/sys/vm/overcommit_memory

for pkt_kernel in /proc/sys/kernel
    do
tweak 0 $pkt_kernel/sched_autogroup_enabled
tweak 1 $pkt_kernel/sched_child_runs_first
tweak 10 $pkt_kernel/perf_cpu_time_max_percent
tweak 0 $pkt_kernel/sched_cstate_aware
tweak "0 0 0 0" $pkt_kernel/printk
tweak off $pkt_kernel/printk_devkmsg
tweak 50000 $pkt_kernel/sched_migration_cost_ns
tweak 1000000 $pkt_kernel/sched_min_granularity_ns
tweak 1500000 $pkt_kernel/sched_wakeup_granularity_ns
tweak 0 $pkt_kernel/timer_migration
tweak 0 $pkt_kernel/sched_min_task_util_for_colocation
done

for pkt_memory in /proc/sys/vm
    do
tweak 50 $pkt_memory/vfs_cache_pressure
tweak 30 $pkt_memory/stat_interval
tweak 0 $pkt_memory/compaction_proactiveness
tweak 0 $pkt_memory/page-cluster
tweak 60 $pkt_memory/swappiness
tweak 60 $pkt_memory/dirty_ratio
done

for pkt_cputweak in /dev/cpuset
do
    tweak max $pkt_cputweak/top-app/uclamp.max
    tweak 10 $pkt_cputweak/top-app/uclamp.min
    tweak 1 $pkt_cputweak/top-app/uclamp.boosted
    tweak 1 $pkt_cputweak/top-app/uclamp.latency_sensitive

    tweak 50 $pkt_cputweak/foreground/uclamp.max
    tweak 0 $pkt_cputweak/foreground/uclamp.min
    tweak 0 $pkt_cputweak/foreground/uclamp.boosted
    tweak 0 $pkt_cputweak/foreground/uclamp.latency_sensitive

    tweak max $pkt_cputweak/background/uclamp.max
    tweak 20 $pkt_cputweak/background/uclamp.min
    tweak 0 $pkt_cputweak/background/uclamp.boosted
    tweak 0 $pkt_cputweak/background/uclamp.latency_sensitive

    tweak 0 $pkt_cputweak/system-background/uclamp.min
    tweak 40 $pkt_cputweak/system-background/uclamp.max
    tweak 0 $pkt_cputweak/system-background/uclamp.boosted
    tweak 0 $pkt_cputweak/system-background/uclamp.latency_sensitive
done

sysctl -w kernel.sched_util_clamp_min_rt_default=0
sysctl -w kernel.sched_util_clamp_min=128

tweak 1 /sys/module/workqueue/parameters/power_efficient

for pkt_ipv4 in /proc/sys/net/ipv4
    do
tweak 0 $pkt_ipv4/tcp_timestamp
tweak 1 $pkt_ipv4/tcp_low_latency
done

# Celestial Tweaks

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# Power Save Mode Off
settings put global low_power 0

# GPU Freq Optimization

for celes_gpu in /proc/gpufreq
    do
tweak 1 $celes_gpu/gpufreq_limited_thermal_ignore
tweak 1 $celes_gpu/gpufreq_limited_oc_ignore
tweak 1 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
tweak 1 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
tweak 0 $celes_gpu/gpufreq_opp_freq
tweak 0 $celes_gpu/gpufreq_fixed_freq_volt
tweak 0 $celes_gpu/gpufreq_opp_stress_test
tweak 0 $celes_gpu/gpufreq_opp_stress_test
tweak 0 $celes_gpu/gpufreq_power_dump
tweak 0 $celes_gpu/gpufreq_power_limited
done

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest Performance - カリン・ウィクス & 安可'"
wait
exit 0

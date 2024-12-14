sync

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
    tweak 0 "$kernelperfdebug/perf_cpu_time_max_percent"

    tweak off "$kernelperfdebug/printk_devkmsg"
    tweak 0 "$kernelperfdebug/sched_schedstats"
    tweak 1 "$kernelperfdebug/sched_child_runs_first"
    tweak 32 "$kernelperfdebug/sched_nr_migrate"
    tweak 50000 "$kernelperfdebug/sched_migration_cost_ns"
    tweak 1000000 "$kernelperfdebug/sched_min_granularity_ns"
    tweak 1500000 "$kernelperfdebug/sched_wakeup_granularity_ns"

    tweak 1000000 "$kernelperfdebug/sched_latency_ns"
    tweak 1024 "$kernelperfdebug/sched_util_clamp_max"
    tweak 1024 "$kernelperfdebug/sched_util_clamp_min"
    tweak 1 "$kernelperfdebug/sched_tunable_scaling"
    tweak 0 "$kernelperfdebug/sched_energy_aware"
    tweak 1 "$kernelperfdebug/sched_util_clamp_min_rt_default"
    tweak 4194304 "$kernelperfdebug/sched_deadline_period_max_us"
    tweak 100 "$kernelperfdebug/sched_deadline_period_min_us"

    tweak -1 "$kernelperfdebug/sched_rt_period_us"
    tweak -1 "$kernelperfdebug/sched_rt_runtime_us"
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

if [ -f /proc/ppm/policy_status ]; then
	policy_file="/proc/ppm/policy_status"
	pwr_thro_idx=$(grep 'PPM_POLICY_PWR_THRO' $policy_file | sed 's/.*\[\(.*\)\].*/\1/')
	thermal_idx=$(grep 'PPM_POLICY_THERMAL' $policy_file | sed 's/.*\[\(.*\)\].*/\1/')

	tweak "$pwr_thro_idx 0" $policy_file
	tweak "$thermal_idx 0" $policy_file
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
	tweak performance $path/scaling_governor
done &

# Set CPU Freq to Max

for policy in /sys/devices/system/cpu/cpufreq/policy*/; do
    if [ -d "$policy" ]; then
        chmod 644 "${policy}scaling_max_freq"
        chmod 644 "${policy}scaling_min_freq"

        default_max=$(cat "${policy}cpuinfo_max_freq")

        echo "$default_max" > "${policy}scaling_max_freq"
        echo "$default_max" > "${policy}scaling_min_freq"
    fi
done &

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

chmod 644 /sys/module/sspm/holders/ged/parameters/is_GED_KPI_enabled
echo '0' > /sys/module/sspm/holders/ged/parameters/is_GED_KPI_enabled

chmod 644 /sys/kernel/fpsgo/fbt/*
chmod 644 /sys/kernel/fpsgo/fstb/*

echo 1 > /sys/kernel/fpsgo/fbt/enable_uclamp_boost

echo "1" > /sys/pnpmgr/fpsgo_boost/boost_mode
echo "0" > /sys/pnpmgr/mwn
echo "2" > /sys/module/mtk_fpsgo/parameters/bhr_opp
echo "1" > /sys/module/mtk_fpsgo/parameters/bhr_opp_l
echo "1" > /sys/module/mtk_fpsgo/parameters/boost_affinity
echo "1" > /sys/module/mtk_fpsgo/parameters/xgf_uboost
echo "-1" > /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
echo "1" > /sys/module/mtk_fpsgo/parameters/gcc_fps_margin
echo "1" > /sys/module/mtk_fpsgo/parameters/rescue_enhance_f
echo "1" > /sys/module/mtk_fpsgo/parameters/qr_mod_frame
echo "1" > /sys/module/mtk_fpsgo/parameters/fstb_separate_runtime_enable
echo "1" > /sys/module/mtk_fpsgo/parameters/fstb_consider_deq
echo "0" > /sys/pnpmgr/fpsgo_boost/fstb/fstb_tune_quantile
echo "1" > /sys/pnpmgr/fpsgo_boost/fstb/fstb_tune_error_threshold
echo "1" > /sys/pnpmgr/fpsgo_boost/fstb/margin_mode
echo "2" > /sys/pnpmgr/fpsgo_boost/fbt/bhr_opp
echo "-1" > /sys/pnpmgr/fpsgo_boost/fbt/adjust_loading
echo "-1" > /sys/pnpmgr/fpsgo_boost/fbt/dyn_tgt_time_en
echo "2" > /sys/pnpmgr/fpsgo_boost/fbt/floor_opp
echo "-1" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_enhance_f
echo "-1" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_opp_c
echo "-1" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_opp_f
echo "-1" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_percent
echo "1" > /sys/pnpmgr/fpsgo_boost/fbt/ultra_rescue
echo "0" > /sys/kernel/fpsgo/xgf/xgf_trace_enable
echo "1" > /sys/kernel/fpsgo/fstb/tfps_to_powerhal_enable
echo "1" > /sys/kernel/fpsgo/fstb/set_cam_active
echo "1" > /sys/kernel/fpsgo/fbt/boost_ta
echo "1" > /sys/module/ged/parameters/ged_smart_boost
echo "-1" > /sys/module/ged/parameters/gpu_cust_upbound_freq
echo "1" > /sys/module/ged/parameters/enable_gpu_boost
echo "1" > /sys/module/ged/parameters/ged_boost_enable
echo "1" > /sys/module/ged/parameters/boost_gpu_enable
echo "1" > /sys/module/ged/parameters/gpu_dvfs_enable
echo "1" > /sys/module/ged/parameters/gpu_idle
echo "1" > /sys/module/ged/parameters/ged_monitor_3D_fence_systrace
echo "-1" > /sys/module/ged/parameters/g_fb_dvfs_threshold
echo "0" > /sys/module/ged/parameters/g_gpu_timer_based_emu
echo "-1" > /sys/module/ged/parameters/gpu_cust_boost_freq
echo "101" > /sys/kernel/ged/hal/gpu_boost_level
echo "0" > /sys/module/ged/parameters/is_GED_KPI_enabled
echo "-1" > /sys/kernel/ged/hal/custom_boost_gpu_freq
echo "-1" > /sys/kernel/ged/hal/custom_upbound_gpu_freq
echo "0" > /sys/kernel/ged/hal/dvfs_loading_mode
echo "0" > /sys/kernel/ged/hal/dvfs_workload_mode
echo "-1" > /sys/kernel/ged/hal/dvfs_margin_value

# Advanced FPSGO & GED

echo "15" > /sys/module/mtk_fpsgo/parameters/bhr_opp
echo "1" > /sys/module/mtk_fpsgo/parameters/bhr_opp_l
echo "90" > /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
echo "1" > /sys/module/mtk_fpsgo/parameters/gcc_fps_margin
echo "90" > /sys/module/mtk_fpsgo/parameters/rescue_enhance_f
echo "1" > /sys/module/mtk_fpsgo/parameters/qr_mod_frame
echo "1" > /sys/module/mtk_fpsgo/parameters/fstb_separate_runtime_enable
echo "1" > /sys/module/mtk_fpsgo/parameters/fstb_consider_deq
echo "100" > /sys/pnpmgr/fpsgo_boost/fstb/fstb_tune_quantile
echo "0" > /sys/pnpmgr/fpsgo_boost/fstb/fstb_tune_error_threshold
echo "1" > /sys/pnpmgr/fpsgo_boost/fstb/margin_mode
echo "10" > /sys/pnpmgr/fpsgo_boost/fbt/bhr_opp
echo "1" > /sys/pnpmgr/fpsgo_boost/fbt/adjust_loading
echo "1" > /sys/pnpmgr/fpsgo_boost/fbt/dyn_tgt_time_en
echo "0" > /sys/pnpmgr/fpsgo_boost/fbt/floor_opp
echo "90" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_enhance_f
echo "80" > /sys/module/mtk_fpsgo/parameters/run_time_percent
echo "1" > /sys/module/mtk_fpsgo/parameters/loading_ignore_enable
echo "80" > /sys/module/mtk_fpsgo/parameters/kmin
echo "90" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_opp_c
echo "90" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_opp_f
echo "90" > /sys/pnpmgr/fpsgo_boost/fbt/rescue_percent
echo "1" > /sys/pnpmgr/fpsgo_boost/fbt/ultra_rescue

# Power Save Mode Off
settings put global low_power 0

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' TagPerformance 'Performance Mode! - カリン・ウィクス & 安可'"

wait
exit 0

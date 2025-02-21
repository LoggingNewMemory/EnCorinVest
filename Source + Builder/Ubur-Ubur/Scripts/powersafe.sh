tweak() {
	if [ -f $2 ]; then
		chmod 644 $2 >/dev/null 2>&1
		echo $1 >$2 2>/dev/null
		chmod 444 $2 >/dev/null 2>&1
	fi
}

celestial_opt() {
setprop debug.performance.tuning 1
setprop debug.sf.hw 1
setprop debug.egl.hw 1
write global activity_manager_constants "power_check_max_cpu_1=0,power_check_max_cpu_2=0,power_check_max_cpu_3=0,power_check_max_cpu_4=0,power_check_max_cpu_5=0,power_check_max_cpu_6=0,power_check_max_cpu_7=0,power_check_max_cpu_8=0"
write global activity_starts_logging_enabled 0
write secure high_priority 1
cmd stats clear-puller-cache
cmd display ab-logging-disable
cmd display dwb-logging-disable
cmd display set-match-content-frame-rate-pref 2
logcat -c --wrap
simpleperf --log fatal --log-to-android-buffer 0
cmd activity clear-watch-heap -a
cmd looper_stats disable
am memory-factor set CRITICAL
cmd power set-adaptive-power-saver-enabled false
cmd power set-fixed-performance-mode-enabled true
cmd thermalservice override-status 0
}
encore_cpu() {
    # Disable battery saver module
if [ -f /sys/module/battery_saver/parameters/enabled ]; then
    if grep -qo '[0-9]\+' /sys/module/battery_saver/parameters/enabled; then
		tweak 0 /sys/module/battery_saver/parameters/enabled
    else
		tweak N /sys/module/battery_saver/parameters/enabled
    fi
fi

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
pkt() {
    # PKT Value to Powersave

tweak 1 /proc/sys/vm/overcommit_memory

for pkt_kernel in /proc/sys/kernel
do
    tweak 1 $pkt_kernel/sched_autogroup_enabled
    tweak 0 $pkt_kernel/sched_child_runs_first
    tweak 5 $pkt_kernel/perf_cpu_time_max_percent
    tweak 1 $pkt_kernel/sched_cstate_aware
    tweak "0 0 0 0" $pkt_kernel/printk
    tweak off $pkt_kernel/printk_devkmsg
    tweak 100000 $pkt_kernel/sched_migration_cost_ns
    tweak 1500000 $pkt_kernel/sched_min_granularity_ns
    tweak 2000000 $pkt_kernel/sched_wakeup_granularity_ns
    tweak 0 $pkt_kernel/timer_migration
    tweak 30 $pkt_kernel/sched_min_task_util_for_colocation
done

for pkt_memory in /proc/sys/vm
do
    tweak 200 $pkt_memory/vfs_cache_pressure
    tweak 60 $pkt_memory/stat_interval
    tweak 0 $pkt_memory/compaction_proactiveness
    tweak 0 $pkt_memory/page-cluster
    tweak 100 $pkt_memory/swappiness
    tweak 40 $pkt_memory/dirty_ratio
done

for pkt_cputweak in /dev/cpuset
do
    tweak 60 $pkt_cputweak/top-app/uclamp.max
    tweak 5 $pkt_cputweak/top-app/uclamp.min
    tweak 0 $pkt_cputweak/top-app/uclamp.boosted
    tweak 0 $pkt_cputweak/top-app/uclamp.latency_sensitive

    tweak 40 $pkt_cputweak/foreground/uclamp.max
    tweak 0 $pkt_cputweak/foreground/uclamp.min
    tweak 0 $pkt_cputweak/foreground/uclamp.boosted
    tweak 0 $pkt_cputweak/foreground/uclamp.latency_sensitive

    tweak 30 $pkt_cputweak/background/uclamp.max
    tweak 0 $pkt_cputweak/background/uclamp.min
    tweak 0 $pkt_cputweak/background/uclamp.boosted
    tweak 0 $pkt_cputweak/background/uclamp.latency_sensitive

    tweak 0 $pkt_cputweak/system-background/uclamp.min
    tweak 20 $pkt_cputweak/system-background/uclamp.max
    tweak 0 $pkt_cputweak/system-background/uclamp.boosted
    tweak 0 $pkt_cputweak/system-background/uclamp.latency_sensitive
done

sysctl -w kernel.sched_util_clamp_min_rt_default=0
sysctl -w kernel.sched_util_clamp_min=0

tweak 1 /sys/module/workqueue/parameters/power_efficient

# Enable Battery Efficient

cmd power set-adaptive-power-saver-enabled true
cmd looper_stats enable

# Enable CCCI & Tracing

tweak 1 /sys/kernel/ccci/debug
tweak 1 /sys/kernel/tracing/tracing_on
}
mediatek() {
# Encore Script

# IO Tweaks

for queue in /sys/block/sd*/queue; do

    tweak 0 "$queue/add_random"
    tweak 0 "$queue/iostats"
    tweak 2 "$queue/nomerges"
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

done &

for schedtweak in /sys/devices/system/cpu/cpufreq/schedutil; do

    tweak 1000 "$schedtweak/rate_limit_us"

done &

tweak menu /sys/devices/system/cpu/cpuidle/current_governor
tweak 0 /sys/module/kernel/parameters/panic_on_warn

if [ -f "/sys/kernel/debug/sched_features" ]; then
	# Consider scheduling tasks that are eager to run
	tweak NEXT_BUDDY "/sys/kernel/debug/sched_features"

	# Some sources report large latency spikes during large migrations
	tweak TTWU_QUEUE "/sys/kernel/debug/sched_features"
fi

if [ -d /proc/ppm ]; then
	for idx in $(cat /proc/ppm/policy_status | grep -E 'PWR_THRO|THERMAL' | awk -F'[][]' '{print $2}'); do
	tweak "$idx 1" /proc/ppm/policy_status
	done
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

# Corin X MTKVest Script

tweak 1 /proc/trans_scheduler/enable
tweak 0 /proc/game_state
tweak coarse_demand /sys/class/misc/mali0/device/power_policy

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
    tweak "cpu$(awk '{print $1}' $path/affected_cpus) $cpu_minfreq" /sys/devices/virtual/thermal/thermal_message/cpu_limits
done

# Revert FPSGo & GED Parameter to Default

# FPSGo

for fpsgo in /sys/kernel/fpsgo
do
    tweak 0 $fpsgo/fbt/boost_ta
    tweak 1 $fpsgo/fbt/enable_switch_down_throttle
    tweak 1 $fpsgo/fstb/adopt_low_fps
    tweak 1 $fpsgo/fstb/fstb_self_ctrl_fps_enable
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
  tweak 1 $ged_extra/gpu_dvfs_enable
  tweak 0 $ged_extra/gx_frc_mode
  tweak 60 $ged_extra/gx_dfps
  tweak 0 $ged_extra/gx_force_cpu_boost
  tweak 0 $ged_extra/gx_boost_on
  tweak 0 $ged_extra/gx_game_mode
  tweak 0 $ged_extra/gx_3D_benchmark_on
  tweak 0 $ged_extra/gpu_loading
  tweak 0 $ged_extra/cpu_boost_policy
  tweak 0 $ged_extra/boost_extra
  tweak 1 $ged_extra/is_GED_KPI_enabled
  tweak 0 $ged_extra/gpu_cust_boost_freq
  tweak 0 $ged_extra/gpu_cust_upbound_freq
  tweak 0 $ged_extra/gpu_bottom_freq
  tweak 0 $ged_extra/ged_smart_boost
  tweak 0 $ged_extra/enable_game_self_frc_detect
  tweak 0 $ged_extra/boost_amp
  tweak 0 $ged_extra/gpu_idle
  tweak 0 $ged_extra/g_gpu_timer_based_emu
  tweak 1 $ged_extra/ged_monitor_3D_fence_disable
  tweak 0 $ged_extra/ged_monitor_3D_fence_debug
  tweak 0 $ged_extra/gpu_bw_err_debug
  tweak 0 $ged_extra/gpu_debug_enable
done

tweak "default_mode" /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 00 /sys/kernel/ged/hal/custom_boost_gpu_freq

# Celestial Tweaks
# Optimize Priority with balanced values
settings put secure high_priority 0
settings put secure low_priority 1

# GPU Freq Optimization with default values

if [ -d "/proc/gpufreq" ]; then
for celes_gpu in /proc/gpufreq
    do
    tweak 0 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 0 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 1 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 1 $celes_gpu/gpufreq_opp_stress_test
    tweak 1 $celes_gpu/gpufreq_power_dump
    tweak 1 $celes_gpu/gpufreq_power_limited
done
fi

# Additional Kernel Tweak with default values

for celes_kernel in /proc/sys/kernel
    do
    tweak 0 $celes_kernel/sched_sync_hint_enable
done

# Celestial Render

# PowerVR Tweaks

if [ -d "/sys/module/pvrsrvkm/parameters" ]; then

    for powervr_tweaks in /sys/module/pvrsrvkm/parameters 
        do
    tweak 0 $powervr_tweaks/gpu_power
    tweak 128 $powervr_tweaks/HTBufferSizeInKB
    tweak 1 $powervr_tweaks/DisableClockGating
    tweak 0 $powervr_tweaks/EmuMaxFreq
    tweak 0 $powervr_tweaks/EnableFWContextSwitch
    tweak 1 $powervr_tweaks/gPVRDebugLevel
    tweak 0 $powervr_tweaks/gpu_dvfs_enable
    done
fi

if [ -d "/sys/kernel/debug/pvr/apphint" ]; then

    for powervr_apphint in /sys/kernel/debug/pvr/apphint
        do
    tweak 0 $powervr_apphint/CacheOpConfig
    tweak 256 $powervr_apphint/CacheOpUMKMThresholdSize
    tweak 1 $powervr_apphint/EnableFTraceGPU
    tweak 0 $powervr_apphint/HTBOperationMode
    tweak 0 $powervr_apphint/TimeCorrClock
    tweak 1 $powervr_apphint/0/DisableFEDLogging
    tweak 1 $powervr_apphint/0/EnableAPM
    done
fi

if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
    for kgsl_tweak in /sys/class/kgsl/kgsl-3d0
        do
    tweak 4 $kgsl_tweak/max_pwrlevel
    tweak 0 $kgsl_tweak/adrenoboost
    tweak Y $kgsl_tweak/adreno_idler_active
    tweak 1 $kgsl_tweak/throttling
    tweak 1 $kgsl_tweak/perfcounter
    tweak 1 $kgsl_tweak/bus_split
    tweak 4 $kgsl_tweak/thermal_pwrlevel 
    tweak 1 $kgsl_tweak/force_clk_on 
    tweak 1 $kgsl_tweak/force_bus_on 
    tweak 1 $kgsl_tweak/force_rail_on 
    tweak 0 $kgsl_tweak/force_no_nap 
    tweak 0 $kgsl_tweak/idle_timer 
    tweak 100 $kgsl_tweak/pmqos_active_latency 
    done
fi

if [ -d "/sys/kernel/debug/fpsgo/common" ]; then
    tweak "0 0 0" /sys/kernel/debug/fpsgo/common/gpu_block_boost
fi


}

snapdragon() {

encore_cpu

# Qualcomm CPU Bus and DRAM frequencies
for path in /sys/class/devfreq/*cpu-ddr-latfloor*; do
	tweak "powersave" $path/governor
done &

for path in /sys/class/devfreq/*cpu*-lat; do
	tweak "powersave" $path/governor
done &

for path in /sys/class/devfreq/*cpu-cpu-ddr-bw; do
	tweak "powersave" $path/governor
done &

for path in /sys/class/devfreq/*cpu-cpu-llcc-bw; do
	tweak "powersave" $path/governor
done &

if [ -d /sys/devices/system/cpu/bus_dcvs/LLCC ]; then
	freq=$(cat /sys/devices/system/cpu/bus_dcvs/LLCC/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/max_freq; do
	tweak $freq $path
done &

for path in /sys/devices/system/cpu/bus_dcvs/LLCC/*/min_freq; do
	tweak $freq $path
	done &
fi

if [ -d /sys/devices/system/cpu/bus_dcvs/L3 ]; then
	freq=$(cat /sys/devices/system/cpu/bus_dcvs/L3/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
for path in /sys/devices/system/cpu/bus_dcvs/L3/*/max_freq; do
	tweak $freq $path
	done &
for path in /sys/devices/system/cpu/bus_dcvs/L3/*/min_freq; do
	tweak $freq $path
	done &
fi

if [ -d /sys/devices/system/cpu/bus_dcvs/DDR ]; then
	freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDR/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/max_freq; do
	tweak $freq $path
    done &
for path in /sys/devices/system/cpu/bus_dcvs/DDR/*/min_freq; do
	tweak $freq $path
	done &
fi

if [ -d /sys/devices/system/cpu/bus_dcvs/DDRQOS ]; then
	freq=$(cat /sys/devices/system/cpu/bus_dcvs/DDRQOS/available_frequencies | tr ' ' '\n' | sort -n | head -n 1)
for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/max_freq; do
	tweak $freq $path
	done &
for path in /sys/devices/system/cpu/bus_dcvs/DDRQOS/*/min_freq; do
    tweak $freq $path
	done &
fi

# GPU Frequency
gpu_path="/sys/class/kgsl/kgsl-3d0/devfreq"

if [ -d $gpu_path ]; then
	freq=$(cat $gpu_path/available_frequencies | tr ' ' '\n' | sort -n | head -n 2)
	tweak $freq $gpu_path/min_freq
	tweak $freq $gpu_path/max_freq
fi

# GPU Bus
for path in /sys/class/devfreq/*gpubw*; do
	tweak "powersave" $path/governor
done &

# Adreno Boost
    tweak 0 /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost

}

exynos() {

encore_cpu

# GPU Frequency
	gpu_path="/sys/kernel/gpu"

if [ -d $gpu_path ]; then
	freq=$(cat $gpu_path/gpu_available_frequencies | tr ' ' '\n' | sort -n | head -n 2)
	tweak $freq $gpu_path/gpu_min_clock
	tweak $freq $gpu_path/gpu_max_clock
fi

}

unisoc() {

encore_cpu

# GPU Frequency
gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)

if [ -d $gpu_path ]; then
	freq=$(cat $gpu_path/available_frequencies | tr ' ' '\n' | sort -n | head -n 2)
	tweak $freq $gpu_path/min_freq
	tweak $freq $gpu_path/max_freq
fi
}

# Additional Storage Tweak
freakzy_storage() {
    tweak "deadline" "$deviceio/queue/scheduler"
    tweak 2 "$queue/rq_affinity"
}


# SOC Recognition 

detect_soc() {
    # Check multiple sources for SOC information
    local chipset=""
    
    # Check /proc/cpuinfo
    if [ -f "/proc/cpuinfo" ]; then
        chipset=$(grep -E "Hardware|Processor" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')
    fi
    
    # If empty, check Android properties
    if [ -z "$chipset" ]; then
        if command -v getprop >/dev/null 2>&1; then
            chipset="$(getprop ro.board.platform) $(getprop ro.hardware)"
        fi
    fi
    
    # Additional checks for Exynos
    if [ -z "$chipset" ] || [ "$chipset" = " " ]; then
        # Check Samsung specific properties
        if command -v getprop >/dev/null 2>&1; then
            local samsung_soc=$(getprop ro.hardware.chipname)
            if [[ "$samsung_soc" == *"exynos"* ]] || [[ "$samsung_soc" == *"EXYNOS"* ]]; then
                chipset="$samsung_soc"
            fi
        fi
        
        # Check kernel version for Exynos information
        if [ -z "$chipset" ]; then
            local kernel_version=$(cat /proc/version 2>/dev/null)
            if [[ "$kernel_version" == *"exynos"* ]] || [[ "$kernel_version" == *"EXYNOS"* ]]; then
                chipset="exynos"
            fi
        fi
    fi
    
    echo "$chipset"
}

# Get the chipset information
chipset=$(detect_soc)

# Convert to lowercase for easier matching
chipset_lower=$(echo "$chipset" | tr '[:upper:]' '[:lower:]')

# Identify the chipset and execute the corresponding function
case "$chipset_lower" in
    *mt*) 
        echo "- Implementing tweaks for Mediatek"
        mediatek
        ;;
    *sm*|*qcom*|*qualcomm*) 
        echo "- Implementing tweaks for Snapdragon"
        snapdragon
        ;;
    *exynos*|*universal*|*samsung*) 
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

# Power Save Mode On
settings put global low_power 1

freakzy_storage
celestial_opt
pkt

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - Powersave'"
wait
exit 0

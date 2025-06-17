MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"

# Complete Modify of MTKVest | Maintain fast execution
mtkvest_perf() {

tweak "0"  /proc/mtk_lpm/lpm/rc/syspll/enable
tweak "0"  /proc/mtk_lpm/lpm/rc/dram/enable
tweak "0"  /proc/mtk_lpm/lpm/rc/cpu-buck-ldo/enable
tweak "0"  /proc/mtk_lpm/lpm/rc/bus26m/enable

# Configure GED HAL settings
if [ -d /sys/kernel/ged/hal ]; then
    tweak 2  "/sys/kernel/ged/hal/loading_base_dvfs_step"
    tweak 1  "/sys/kernel/ged/hal/loading_stride_size"
    tweak 16  "/sys/kernel/ged/hal/loading_window_size"
fi


tweak "100"  /sys/kernel/ged/hal/gpu_boost_level

# Disable Dynamic Clock Management
tweak "disable 0xFFFFFFF"  /sys/dcm/dcm_state

chmod 644 /proc/mtk_lpm/suspend/suspend_state
tweak "mtk_suspend 0"  /proc/mtk_lpm/suspend/suspend_state  
tweak "kernel_suspend 0"  /proc/mtk_lpm/suspend/suspend_state  

tweak "2"  /proc/mtk_lpm/cpuidle/control/armpll_mode
tweak "2"  /proc/mtk_lpm/cpuidle/control/buck_mode
tweak "0"  /proc/mtk_lpm/cpuidle/cpc/auto_off

# Disable CPU Idle (Try to optimize)
tweak "100 7 0"  /proc/mtk_lpm/cpuidle/state/enabled

tweak 100 7 200  /proc/mtk_lpm/cpuidle/state/latency  

# Workqueue settings
tweak "N"  /sys/module/workqueue/parameters/power_efficient
tweak "N"  /sys/module/workqueue/parameters/disable_numa

tweak "0"  /sys/devices/system/cpu/eas/enable

tweak "1"  /sys/devices/system/cpu/cpu2/online
tweak "1"  /sys/devices/system/cpu/cpu3/online

# Power level settings
for pl in /sys/devices/system/cpu/perf; do
    tweak "1"  "$pl/gpu_pmu_enable"
    tweak "1"  "$pl/fuel_gauge_enable"
    # tweak "1"  "$pl/enable"
    tweak "1"  "$pl/charger_enable"
done

for path in /sys/devices/platform/*.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp; do
    if [ -f "$path" ]; then
        tweak "0"  "$path"
    fi
done
for path in /sys/devices/platform/soc/1c00f000.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor; do
    if [ -f "$path" ]; then
        tweak "performance"  "$path"
    fi
done

# Power Policy GPU
tweak "always_on"  /sys/class/misc/mali0/device/power_policy

# Scheduler settings
tweak "0"  /proc/sys/kernel/perf_cpu_time_max_percent
tweak "0"  /proc/sys/kernel/perf_event_max_contexts_per_stack
tweak "0"  /proc/sys/kernel/sched_energy_aware
tweak "300000"  /proc/sys/kernel/perf_event_max_sample_rate

# Performance Manager
tweak "1"  /proc/perfmgr/syslimiter/syslimiter_force_disable

tweak "8 0 0"  /proc/gpufreq/gpufreq_limit_table

# MTK FPSGo advanced parameters
for param in adjust_loading boost_affinity boost_LR gcc_hwui_hint; do
    tweak "1"  "/sys/module/mtk_fpsgo/parameters/$param"
done

ged_params="ged_smart_boost 1
boost_upper_bound 100
enable_gpu_boost 1
enable_cpu_boost 1
ged_boost_enable 1
boost_gpu_enable 1
gpu_dvfs_enable 1
gx_frc_mode 1
gx_dfps 1
gx_force_cpu_boost 1
gx_boost_on 1
gx_game_mode 1
gx_3D_benchmark_on 1
gx_fb_dvfs_margin 100
gx_fb_dvfs_threshold 100
gpu_loading 100000
cpu_boost_policy 1
boost_extra 1
is_GED_KPI_enabled 0
ged_force_mdp_enable 1
force_fence_timeout_dump_enable 0
gpu_idle 0"

tweak "$ged_params" | while read -r param value; do
    tweak "$value"  "/sys/module/ged/parameters/$param"
done

tweak 100  /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
tweak 0  /sys/module/mtk_fpsgo/parameters/isolation_limit_cap
tweak "1"  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 1  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 1  /sys/pnpmgr/install
}

mtkvest_normal() {

tweak "mtk_suspend 0"  /proc/mtk_lpm/suspend/suspend_state  
tweak "kernel_suspend 1"  /proc/mtk_lpm/suspend/suspend_state  

# GPU Power Settings
tweak "coarse_demand"  /sys/class/misc/mali0/device/power_policy

tweak "1"  /proc/mtk_lpm/lpm/rc/syspll/enable
tweak "1"  /proc/mtk_lpm/lpm/rc/dram/enable
tweak "1"  /proc/mtk_lpm/lpm/rc/cpu-buck-ldo/enable
tweak "1"  /proc/mtk_lpm/lpm/rc/bus26m/enable

tweak "0"  /sys/kernel/ged/hal/gpu_boost_level

# Configure GED HAL settings
if [ -d /sys/kernel/ged/hal ]; then
    tweak 4  "/sys/kernel/ged/hal/loading_base_dvfs_step"
    tweak 2  "/sys/kernel/ged/hal/loading_stride_size"
    tweak 8  "/sys/kernel/ged/hal/loading_window_size"
fi

# Enable Dynamic Clock Management
tweak "restore 0xFFFFFFF"  /sys/dcm/dcm_state

# tweak "0"  /proc/pbm/pbm_stop (Disable Duplicate)

tweak "2"  /proc/mtk_lpm/cpuidle/control/armpll_mode
tweak "2"  /proc/mtk_lpm/cpuidle/control/buck_mode
tweak "1"  /proc/mtk_lpm/cpuidle/cpc/auto_off

tweak 100 7 20000  /proc/mtk_lpm/cpuidle/state/latency  

# Workqueue settings
tweak "Y"  /sys/module/workqueue/parameters/power_efficient
tweak "Y"  /sys/module/workqueue/parameters/disable_numa

# Disable Duplicate
# tweak "1"  /sys/kernel/eara_thermal/enable
tweak "1"  /sys/devices/system/cpu/eas/enable

# Power level settings
for pl in /sys/devices/system/cpu/perf; do
    tweak "0"  "$pl/gpu_pmu_enable"
    tweak "0"  "$pl/fuel_gauge_enable"
    # tweak "0"  "$pl/enable"
    tweak "1"  "$pl/charger_enable"
done

for path in /sys/devices/platform/*.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp; do
    if [ -f "$path" ]; then
        tweak "-1"  "$path"
    fi
done
for path in /sys/devices/platform/soc/*.dvfsrc/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor; do
    if [ -f "$path" ]; then
        tweak "userspace"  "$path"
    fi
done

tweak "1"  /proc/cpufreq/cpufreq_sched_disable

tweak "0"  /proc/perfmgr/syslimiter/syslimiter_force_disable

tweak "40"  /proc/sys/kernel/perf_cpu_time_max_percent
tweak "6"  /proc/sys/kernel/perf_event_max_contexts_per_stack
tweak "1"  /proc/sys/kernel/sched_energy_aware
tweak "100000"  /proc/sys/kernel/perf_event_max_sample_rate

# MTK FPSGo advanced parameters
for param in boost_affinity boost_LR gcc_hwui_hint; do
    tweak "0"  "/sys/module/mtk_fpsgo/parameters/$param"
done

# GED parameters
ged_params="ged_smart_boost 0
boost_upper_bound 0
enable_gpu_boost 0
enable_cpu_boost 0
ged_boost_enable 0
boost_gpu_enable 0
gpu_dvfs_enable 1
gx_frc_mode 0
gx_dfps 0
gx_force_cpu_boost 0
gx_boost_on 0
gx_game_mode 0
gx_3D_benchmark_on 0
gx_fb_dvfs_margin 0
gx_fb_dvfs_threshold 0
gpu_loading 0
cpu_boost_policy 0
boost_extra 0
is_GED_KPI_enabled 1
ged_force_mdp_enable 0
force_fence_timeout_dump_enable 0
gpu_idle 0"

tweak "$ged_params" | while read -r param value; do
    tweak "$value"  "/sys/module/ged/parameters/$param"
done
tweak 25  /sys/module/mtk_fpsgo/parameters/uboost_enhance_f
tweak 1  /sys/module/mtk_fpsgo/parameters/isolation_limit_cap
tweak "0"  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 0  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 0  /sys/pnpmgr/install
}
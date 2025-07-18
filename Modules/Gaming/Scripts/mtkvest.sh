MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"

# Complete Modify of MTKVest | Maintain fast execution
mtkvest_perf() {

# Try to extract highest GPU frequency from available sources
HIGHEST_FREQ=""
if [[ -f "/proc/gpufreqv2/gpu_working_opp_table" ]]; then
    HIGHEST_FREQ=$(awk -F '[: ]+' '/freq/ {gsub(",", "", $3); print $3}' /proc/gpufreqv2/gpu_working_opp_table 2>/dev/null | sort -nr | head -n 1)
elif [[ -f "/proc/gpufreq/gpufreq_opp_dump" ]]; then
    HIGHEST_FREQ=$(awk -F '[: ]+' '/freq/ {gsub(",", "", $3); print $3}' /proc/gpufreq/gpufreq_opp_dump 2>/dev/null | sort -nr | head -n 1)
fi

# Apply highest frequency if found
if [[ -n "$HIGHEST_FREQ" ]]; then
    tweak "$HIGHEST_FREQ" "/sys/module/ged/parameters/gpu_bottom_freq"
    tweak "$HIGHEST_FREQ" "/sys/module/ged/parameters/gpu_cust_boost_freq"
    tweak "$HIGHEST_FREQ" "/sys/module/ged/parameters/gpu_cust_upbound_freq"
fi

# Disable GPUFREQ Limit
if [[ -f "/proc/gpufreq/gpufreq_limit_table" ]]; then
    for i in {0..8}; do
        tweak "$i 0 0" "/proc/gpufreq/gpufreq_limit_table"
    done
fi

# Performance Manager - disable system limiter
tweak 1 /proc/perfmgr/syslimiter/syslimiter_force_disable

# Configure GED HAL settings
if [ -d /sys/kernel/ged/hal ]; then
    tweak 2  "/sys/kernel/ged/hal/loading_base_dvfs_step"
    tweak 1  "/sys/kernel/ged/hal/loading_stride_size"
    tweak 16  "/sys/kernel/ged/hal/loading_window_size"
fi

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
tweak 1  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 1  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 1  /sys/pnpmgr/install
tweak 100 /sys/kernel/ged/hal/gpu_boost_level
}

mtkvest_normal() {

# Reset GPU to auto frequency
if [[ -d "/proc/gpufreq" && -f "/proc/gpufreq/gpufreq_opp_freq" ]]; then
    write "0" "/proc/gpufreq/gpufreq_opp_freq"
elif [[ -d "/proc/gpufreqv2" && -f "/proc/gpufreqv2/fix_target_opp_index" ]]; then
    write "-1" "/proc/gpufreqv2/fix_target_opp_index"
fi

# Reset GPU power limits to normal
if [[ -f "/proc/gpufreq/gpufreq_power_limited" ]]; then
    chmod 644 "/proc/gpufreq/gpufreq_power_limited" 2>/dev/null
    for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
        echo "$setting 0" > /proc/gpufreq/gpufreq_power_limited 2>/dev/null
    done
    chmod 444 "/proc/gpufreq/gpufreq_power_limited" 2>/dev/null
fi

# Reset GPU frequency limits to normal
if [[ -f "/proc/gpufreq/gpufreq_limit_table" ]]; then
    for id in {0..8}; do
        write "$id 1 1" "/proc/gpufreq/gpufreq_limit_table"
    done
fi

# Performance manager settings for balanced operation
write "0" "/proc/perfmgr/syslimiter/syslimiter_force_disable"

# Configure GED HAL settings
if [ -d /sys/kernel/ged/hal ]; then
    tweak 4  "/sys/kernel/ged/hal/loading_base_dvfs_step"
    tweak 2  "/sys/kernel/ged/hal/loading_stride_size"
    tweak 8  "/sys/kernel/ged/hal/loading_window_size"
fi

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
tweak 0  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 0  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 0  /sys/pnpmgr/install
tweak -1 /sys/kernel/ged/hal/gpu_boost_level
}
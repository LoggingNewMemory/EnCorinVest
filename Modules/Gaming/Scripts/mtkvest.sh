MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"

# Complete Modify of MTKVest | Maintain fast execution
mtkvest_perf() {

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
tweak "1"  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 1  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 1  /sys/pnpmgr/install
}

mtkvest_normal() {

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
tweak "0"  /sys/pnpmgr/fpsgo_boost/boost_enable
tweak 0  /sys/pnpmgr/fpsgo_boost/boost_mode
tweak 0  /sys/pnpmgr/install
}
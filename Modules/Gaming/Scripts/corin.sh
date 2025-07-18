MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"

corin_perf() {
# Supposed Only Availabe in Transsion Devices 
if [ -e /proc/trans_scheduler/enable ]; then
tweak 0 /proc/trans_scheduler/enable
fi

# Not Every Device Have
if [ -e /proc/game_state ]; then
tweak 1 /proc/game_state
fi

# Memory Optimization | Older Kernel May Not Have
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    for memtweak in /sys/kernel/mm/transparent_hugepage; do
        tweak always "$memtweak/enabled"
        tweak always "$memtweak/shmem_enabled"
    done
fi

# RAM Tweaks | All Devices Have
for ramtweak in /sys/block/ram*/bdi;do
    tweak 2048 $ramtweak/read_ahead_kb
done

# Supposed Only Availabe in MTKS CPU
if [ -e /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode ]; then
    tweak 1 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode
fi

if [ -e /sys/class/misc/mali0/device/js_ctx_scheduling_mode ]; then
    tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
fi

if [ -e /sys/module/task_turbo/parameters/feats ]; then
    tweak -1 /sys/module/task_turbo/parameters/feats
fi

# Swappiness Tweaks | All Devices Have
for vim_mem in /dev/memcg; do
tweak 30 "$vim_mem/memory.swappiness"
tweak 30 "$vim_mem/apps/memory.swappiness"
tweak 55 "$vim_mem/system/memory.swappiness"
done 

# CPU Set & CTL Tweaks | All Devices Have
# To Do: Make CPU Universal

for cpuset_tweak in /dev/cpuset; do
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

for cpuctl_tweak in /dev/cpuctl; do 
    tweak 1 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
    tweak 1 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive
done

# From Celestial Tweaks
# Supoosed only Helio G series who use gpufreq
if [ -d /proc/gpufreq ]; then   
for celes_gpu in /proc/gpufreq
    do
    # tweak 1 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 1 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 1 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 1 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 0 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 0 $celes_gpu/gpufreq_opp_stress_test
    tweak 0 $celes_gpu/gpufreq_power_dump
    tweak 0 $celes_gpu/gpufreq_power_limited
done
fi

# Tweaks for kernel | Supposed All Devices Have
for celes_kernel in /proc/sys/kernel
    do
    tweak 1 $celes_kernel/sched_sync_hint_enable
done

# Render Tweaks (Celestial Render) 

# PowerVR Tweaks

if [ -d "/sys/module/pvrsrvkm/parameters" ]; then

    for powervr_tweaks in /sys/module/pvrsrvkm/parameters 
        do
    tweak 2 $powervr_tweaks/gpu_power
    tweak 256 $powervr_tweaks/HTBufferSizeInKB
    tweak 0 $powervr_tweaks/DisableClockGating
    tweak 2 $powervr_tweaks/EmuMaxFreq
    tweak 1 $powervr_tweaks/EnableFWContextSwitch
    tweak 0 $powervr_tweaks/gPVRDebugLevel
    tweak 1 $powervr_tweaks/gpu_dvfs_enable
    done
fi

if [ -d "/sys/kernel/debug/pvr/apphint" ]; then

    for powervr_apphint in /sys/kernel/debug/pvr/apphint
        do
    tweak 1 $powervr_apphint/CacheOpConfig
    tweak 512 $powervr_apphint/CacheOpUMKMThresholdSize
    tweak 0 $powervr_apphint/EnableFTraceGPU
    tweak 2 $powervr_apphint/HTBOperationMode
    tweak 1 $powervr_apphint/TimeCorrClock
    tweak 0 $powervr_apphint/0/DisableFEDLogging
    tweak 0 $powervr_apphint/0/EnableAPM
    done
fi

# Snapdragon Tweaks 

if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
    for kgsl_tweak in /sys/class/kgsl/kgsl-3d0
        do
    tweak 0 $kgsl_tweak/thermal_pwrlevel
    tweak 0 $kgsl_tweak/force_bus_on
    # tweak 0 $kgsl_tweak/force_clk_on (Disable duplicate)
    tweak 0 $kgsl_tweak/force_no_nap
    tweak 0 $kgsl_tweak/force_rail_on
    tweak 0 $kgsl_tweak/throttling
    done
fi

# Mediatek

if [ -d "/sys/kernel/debug/fpsgo/common" ]; then
    tweak "100 120 0" /sys/kernel/debug/fpsgo/common/gpu_block_boost
fi

# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 1 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# From MTKVest

cmd power set-adaptive-power-saver-enabled false

# From Corin 
cmd looper_stats disable

# Power Save Mode Off
settings put global low_power 0
}

corin_balanced() {
# Supposed Only Availabe in Transsion Devices 
if [ -e /proc/trans_scheduler/enable ]; then
tweak 1 /proc/trans_scheduler/enable
fi

# Not Every Device Have
if [ -e /proc/game_state ]; then
tweak 0 /proc/game_state
fi

# Memory Optimization | Older Kernel May Not Have
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    for memtweak in /sys/kernel/mm/transparent_hugepage; do
        tweak madvise "$memtweak/enabled"
        tweak madvise "$memtweak/shmem_enabled"
    done
fi

# RAM Tweaks | All Devices Have
for ramtweak in /sys/block/ram*/bdi;do
    tweak 1024 $ramtweak/read_ahead_kb
done

# Supposed Only Availabe in MTKS CPU
if [ -e /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode ]; then
    tweak 1 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode
fi

if [ -e /sys/class/misc/mali0/device/js_ctx_scheduling_mode ]; then
    tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
fi

if [ -e /sys/module/task_turbo/parameters/feats ]; then
    tweak -1 /sys/module/task_turbo/parameters/feats
fi

# Swappiness Tweaks | All Devices Have
for vim_mem in /dev/memcg; do
tweak 60 "$vim_mem/memory.swappiness"
tweak 60 "$vim_mem/apps/memory.swappiness"
tweak 60 "$vim_mem/system/memory.swappiness"
done 

# CPU Set & CTL Tweaks | All Devices Have
# To Do: Make CPU Universal

for cpuset_tweak in /dev/cpuset;do
        tweak 1 $cpuset_tweak/memory_pressure_enabled
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground/sched_load_balance
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground-l/sched_load_balance
        tweak 1 $cpuset_tweak/dex2oat/sched_load_balance
    done


for cpuctl_tweak in /dev/cpuctl; do 
        tweak 0 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive
    done
    
# From Celestial Tweaks
# Supoosed only Helio G series who use gpufreq

if [ -d "/proc/gpufreq" ]; then
for celes_gpu in /proc/gpufreq
    do
    # tweak 0 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 0 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 1 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 1 $celes_gpu/gpufreq_opp_stress_test
    tweak 1 $celes_gpu/gpufreq_power_dump
    tweak 1 $celes_gpu/gpufreq_power_limited
done
fi


# Tweaks for kernel | Supposed All Devices Have
for celes_kernel in /proc/sys/kernel
    do
    tweak 0 $celes_kernel/sched_sync_hint_enable
done

# Render Tweaks (Celestial Render) 

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
    tweak 1 $kgsl_tweak/throttling
    tweak 4 $kgsl_tweak/thermal_pwrlevel 
    # tweak 1 $kgsl_tweak/force_clk_on (Disable Duplicate)
    tweak 1 $kgsl_tweak/force_bus_on 
    tweak 1 $kgsl_tweak/force_rail_on 
    tweak 0 $kgsl_tweak/force_no_nap 
    done
fi

# Mediatek

if [ -d "/sys/kernel/debug/fpsgo/common" ]; then
    tweak "0 0 0" /sys/kernel/debug/fpsgo/common/gpu_block_boost
fi

# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 1 "$queue/rq_affinity"

# Switch GOV to Schedhorizon / Schedutil
for path in /sys/devices/system/cpu/cpufreq/policy*; do
    if grep -q 'schedhorizon' "$path/scaling_available_governors"; then
        tweak schedhorizon "$path/scaling_governor"
    else
        tweak schedutil "$path/scaling_governor"
    fi
done

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 1
settings put secure low_priority 0

# From MTKVest

cmd power set-adaptive-power-saver-enabled false

# From Corin 
cmd looper_stats enable

# Power Save Mode Off
settings put global low_power 0
}

corin_powersave_extra() {
# Supposed Only Availabe in Transsion Devices 
if [ -e /proc/trans_scheduler/enable ]; then
tweak 1 /proc/trans_scheduler/enable
fi

# Not Every Device Have
if [ -e /proc/game_state ]; then
tweak 0 /proc/game_state
fi

# Memory Optimization | Older Kernel May Not Have
if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    for memtweak in /sys/kernel/mm/transparent_hugepage; do
        tweak madvise "$memtweak/enabled"
        tweak madvise "$memtweak/shmem_enabled"
    done
fi

# RAM Tweaks | All Devices Have
for ramtweak in /sys/block/ram*/bdi;do
    tweak 1024 $ramtweak/read_ahead_kb
done

# Supposed Only Availabe in MTKS CPU
if [ -e /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode ]; then
    tweak 0 /sys/kernel/helio-dvfsrc/dvfsrc_qos_mode
fi

if [ -e /sys/class/misc/mali0/device/js_ctx_scheduling_mode ]; then
    tweak 0 /sys/class/misc/mali0/device/js_ctx_scheduling_mode
fi

if [ -e /sys/module/task_turbo/parameters/feats ]; then
    tweak 0 /sys/module/task_turbo/parameters/feats
fi

# Swappiness Tweaks | All Devices Have
for vim_mem in /dev/memcg; do
tweak 60 "$vim_mem/memory.swappiness"
tweak 60 "$vim_mem/apps/memory.swappiness"
tweak 60 "$vim_mem/system/memory.swappiness"
done 

# CPU Set & CTL Tweaks | All Devices Have
# To Do: Make CPU Universal

for cpuset_tweak in /dev/cpuset;do
        tweak 1 $cpuset_tweak/memory_pressure_enabled
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground/sched_load_balance
        tweak 1 $cpuset_tweak/sched_load_balance
        tweak 1 $cpuset_tweak/foreground-l/sched_load_balance
        tweak 1 $cpuset_tweak/dex2oat/sched_load_balance
    done

for cpuctl_tweak in /dev/cpuctl; do 
        tweak 0 $cpuctl_tweak/rt/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/nnapi-hal/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/dex2oat/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/top-app/cpu.uclamp.latency_sensitive
        tweak 0 $cpuctl_tweak/foreground-l/cpu.uclamp.latency_sensitive
    done

# From Celestial Tweaks
# Supoosed only Helio G series who use gpufreq

if [ -d "/proc/gpufreq" ]; then
for celes_gpu in /proc/gpufreq
    do
    # tweak 0 $celes_gpu/gpufreq_limited_thermal_ignore
    tweak 0 $celes_gpu/gpufreq_limited_oc_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volume_ignore
    tweak 0 $celes_gpu/gpufreq_limited_low_batt_volt_ignore
    tweak 1 $celes_gpu/gpufreq_fixed_freq_volt
    tweak 1 $celes_gpu/gpufreq_opp_stress_test
    tweak 1 $celes_gpu/gpufreq_power_dump
    tweak 1 $celes_gpu/gpufreq_power_limited
done
fi

# Tweaks for kernel | Supposed All Devices Have
for celes_kernel in /proc/sys/kernel
    do
    tweak 0 $celes_kernel/sched_sync_hint_enable
done

# Render Tweaks (Celestial Render) 

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
    tweak 1 $kgsl_tweak/throttling
    tweak 4 $kgsl_tweak/thermal_pwrlevel 
    # tweak 1 $kgsl_tweak/force_clk_on (Disable Duplicate)
    tweak 1 $kgsl_tweak/force_bus_on 
    tweak 1 $kgsl_tweak/force_rail_on 
    tweak 0 $kgsl_tweak/force_no_nap 
    done
fi

# Mediatek

if [ -d "/sys/kernel/debug/fpsgo/common" ]; then
    tweak "0 0 0" /sys/kernel/debug/fpsgo/common/gpu_block_boost
fi

# FreakZy Storage

tweak "deadline" "$deviceio/queue/scheduler"
tweak 2 "$queue/rq_affinity"

# Settings Set | Supposed All Devices Have

# Optimize Priority
settings put secure high_priority 0
settings put secure low_priority 1

# From MTKVest

cmd power set-adaptive-power-saver-enabled true

# From Corin 
cmd looper_stats enable

# Power Save Mode On
settings put global low_power 1
}
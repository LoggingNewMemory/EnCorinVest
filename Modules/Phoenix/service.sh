while [ -z "$(getprop sys.boot_completed)" ]; do
sleep 10
done

# Mali Scheduler Tweaks By: MiAzami

mali_dir=$(ls -d /sys/devices/platform/soc/*mali*/scheduling 2>/dev/null | head -n 1)
mali1_dir=$(ls -d /sys/devices/platform/soc/*mali* 2>/dev/null | head -n 1)

tweak() {
    if [ -e "$1" ]; then
        echo "$2" > "$1" && echo "Applied $2 to $1"
    fi
}

if [ -n "$mali_dir" ]; then
    tweak "$mali_dir/serialize_jobs" "full"
fi

if [ -n "$mali1_dir" ]; then
    tweak "$mali1_dir/js_ctx_scheduling_mode" "1"
fi

tweak 0 /sys/module/kernel/parameters/panic
tweak 0 /proc/sys/kernel/panic_on_oops
tweak 0 /sys/module/kernel/parameters/panic_on_warn
tweak 0 /sys/module/kernel/parameters/pause_on_oops
tweak 0 /proc/sys/vm/panic_on_oom

# Test 
# Sandevistan Boot

change_cpu_gov() {
	chmod 644 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo "$1" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	chmod 444 /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
}

change_cpu_gov performance

sleep 20

change_cpu_gov schedutil
change_cpu_gov schedhorizon

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
    *mt*|*mediatek*) 
        echo "- Implementing render for Mediatek"
        SOC_TYPE="mediatek"
        ;;
    *sm*|*qcom*|*qualcomm*|*snapdragon*) 
        echo "- Implementing render for Snapdragon"
        SOC_TYPE="qualcomm"
        ;;
    *exynos*|*universal*|*samsung*) 
        echo "- Implementing render for Exynos"
        SOC_TYPE="exynos"
        ;;
    *unisoc*|*ums*|*spreadtrum*) 
        echo "- Implementing render for Unisoc"
        SOC_TYPE="unisoc"
        ;;
    *) 
        echo "- Unknown chipset: $chipset"
        echo "- No tweaks applied."
        SOC_TYPE="unknown"
        ;;
esac

sleep 3

case "$SOC_TYPE" in
    "qualcomm")
        setprop debug.hwui.renderer skiaglthreaded
        setprop debug.renderengine.backend skiaglthreaded
        setprop debug.skia.threaded_mode true
        setprop persist.sys.gpu.boost 1
        setprop debug.sf.disable_client_composition_cache 1
        setprop persist.sys.angle.default_backend vulkan
        setprop persist.sys.angle.enable 1
        setprop debug.sf.enable_hwc_vds 1
        setprop persist.sys.vulkan.optimized true
        setprop debug.sf.hw 1
        ;;

    "mediatek")
        setprop debug.hwui.renderer skiaglthreaded
        setprop debug.renderengine.backend skiaglthreaded
        setprop debug.skia.threaded_mode true
        setprop persist.sys.gpu.performance 1
        setprop debug.sf.auto_latch_unsignaled 1
        setprop debug.sf.disable_client_composition_cache 1
        setprop ro.surface_flinger.use_content_detection_for_refresh_rate true
        setprop persist.sys.angle.default_backend vulkan
        setprop persist.sys.angle.enable 1
        setprop persist.sys.vulkan.optimized true
        ;;

    "exynos")
        setprop debug.hwui.renderer skiaglthreaded
        setprop debug.renderengine.backend skiaglthreaded
        setprop debug.skia.threaded_mode true
        setprop persist.sys.purgeable_assets 1
        setprop persist.sys.perf.topAppRenderThreadBoost.enable true
        setprop persist.sys.vulkan.optimized true
        setprop persist.sys.angle.default_backend vulkan
        setprop persist.sys.angle.enable 1
        setprop ro.surface_flinger.enable_layer_caching true
        setprop debug.sf.layer_caching_active_layer_timeout_ms 1000
        ;;

    "unisoc")
        setprop debug.hwui.renderer opengl
        setprop debug.renderengine.backend opengl
        setprop persist.sys.disable_skia_path_ops false
        setprop persist.sys.purgeable_assets 1
        setprop persist.sys.dalvik.multithread true
        setprop persist.sys.vulkan.optimized true
        setprop persist.sys.angle.default_backend opengl
        setprop persist.sys.angle.enable 1
        ;;

    *)
        setprop debug.hwui.renderer skiagl
        setprop debug.renderengine.backend skiagl
        setprop persist.sys.vulkan.optimized true
        setprop persist.sys.angle.default_backend opengl
        setprop persist.sys.angle.enable 1
        ;;
esac

sh /data/adb/modules/EnCorinVest/AnyaMelfissa/AnyaMelfissa.sh
sh /data/adb/modules/EnCorinVest/KoboKanaeru/KoboKanaeru.sh

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"

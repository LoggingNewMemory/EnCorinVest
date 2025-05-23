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

# EnCorinVest prop
setprop PERF_RES_NET_BT_AUDIO_LOW_LATENCY 1
setprop PERF_RES_NET_WIFI_LOW_LATENCY 1
setprop PERF_RES_NET_MD_WEAK_SIG_OPT 1
setprop PERF_RES_NET_NETD_BOOST_UID 1
setprop PERF_RES_NET_MD_HSR_MODE 1
setprop PERF_RES_THERMAL_POLICY -1

# Celestial Render
setprop debug.egl.force_msaa false
setprop ro.hwui.disable_scissor_opt false
setprop debug.hwui.use_gpu_pixel_buffers true
setprop debug.hwui.render_dirty_regions false
setprop debug.hwui.disable_vsync true
setprop debug.hwui.level 0
setprop ro.hwui.texture_cache_flushrate 0.4
setprop ro.hwui.texture_cache_size 72
setprop ro.hwui.layer_cache_size 48
setprop ro.hwui.r_buffer_cache_size 8
setprop ro.hwui.path_cache_size 32
setprop ro.hwui.gradient_cache_size 1
setprop ro.hwui.drop_shadow_cache_size 6

# Hyperthreading & Multithread
setprop persist.sys.dalvik.hyperthreading true
setprop persist.sys.dalvik.multithread true

# Smooth GUI
setprop persist.service.lgospd.enable 0
setprop persist.service.pcsync.enable 0
setprop persist.sys.lgospd.enable 0
setprop persist.sys.pcsync.enable 0

# Vendor perf
setprop ro.vendor.perf.scroll_opt 1
setprop vendor.perf.framepacing.enable 1

# For QCom
setprop sys.hwc.gpu_perf_mode 1

# Other
setprop debug.gr.numframebuffers 3

# Celestial Tweaks
setprop ro.iorapd.enable false
setprop iorapd.perfetto.enable false
setprop iorapd.readahead.enable false
setprop persist.device_config.runtime_native_boot.iorap_readahead_enable false
setprop persist.sys.purgeable_assets 1

setprop debug.cpurend.vsync false

# Audio Enhancer
setprop persist.audio.fluence.mode endfire
setprop persist.audio.vr.enable true
setprop persist.audio.handset.mic digital
setprop af.resampler.quality 255
setprop mpq.audio.decode true

# Disable Tombstoned
setprop tombstoned.max_tombstone_count 0

# Azenith Props
setprop dalvik.vm.dexopt.thermal-cutoff 0
setprop ro.vendor.sleep.state s2idle
setprop ro.config.low_ram false
setprop ro.config.hw_power_saving true
setprop ro.ril.sensor.sleep.control 1
setprop hwui.disable_vsync true
setprop persist.cpu.freq.boost 1
setprop persist.sys.ui.hw true

# Dalvik
setprop dalvik.vm.systemuicompilerfilter speed-profile
setprop dalvik.vm.systemservercompilerfilter speed-profile
setprop pm.dexopt.bg-dexopt speed
setprop pm.dexopt.install speed-profile
setprop pm.dexopt.shared speed

# Zygote
setprop persist.zygote.preload_threads 3
setprop ro.zygote.disable_gl_preload false
setprop ro.zygote.preload.enable 0
setprop ro.zygote.preload.disable 1

# MTK PERF
setprop ro.mtk_perf_fast_start_win 1
setprop ro.mtk_perf_response_time 1
setprop ro.mtk_perf_simple_start_win 1

# LMK
setprop ro.lmk.debug false
setprop ro.lmk.kill_heaviest_task true
setprop ro.lmk.use_psi true
setprop ro.lmk.use_minfree_levels false
setprop ro.lmk.thrashing_limit_decay 15
setprop ro.lmk.psi_partial_stall_ms 70
setprop ro.lmk.thrashing_limit 20
setprop ro.lmk.downgrade_pressure 35
setprop ro.lmk.swap_free_low_percentage 10

# GPU Optimization
setprop ro.vendor.gpu.optimize.level 5
setprop ro.vendor.gpu.optimize.load_level 3
setprop ro.vendor.gpu.optimize.driver_version 3
setprop ro.vendor.gpu.optimize.preload 1
setprop ro.vendor.gpu.optimize.purgeable_limit 128
setprop ro.vendor.gpu.optimize.retry_max 6
setprop ro.vendor.gpu.optimize.texture_control true
setprop ro.vendor.gpu.optimize.memory_compaction true
setprop ro.vendor.gpu.optimize.hires_preload true
setprop ro.vendor.gpu.optimize.fork_detector true
setprop ro.vendor.gpu.optimize.fork_detector_threshold 5
setprop ro.vendor.gpu.optimize.max_job_count 4
setprop ro.vendor.gpu.optimize.max_target_duration 10
setprop ro.vendor.gpu.optimize.min_target_size 200

# Surface Flinger Optimization
setprop debug.sf.use_phase_offsets_as_durations 1
setprop debug.sf.late.sf.duration 20000000
setprop debug.sf.late.app.duration 15000000
setprop debug.sf.early.sf.duration 20000000
setprop debug.sf.early.app.duration 15000000
setprop debug.sf.earlyGl.sf.duration 20000000
setprop debug.sf.earlyGl.app.duration 15000000
setprop debug.sf.hwc.min.duration 15000000

# Main Optimization
setprop dalvik.vm.dex2oat-minidebuginfo false
setprop dalvik.vm.minidebuginfo false

# Transsion Thermal
setprop ro.dar.thermal_core.support 0

# Disable 60FPS limit
setprop debug.graphics.game_default_frame_rate.disabled true

# Zeta 120 Hz
setprop view.touch_slop 3
setprop touch.deviceType touchScreen
setprop ro.min_pointer_dur 0.00000001
setprop ro.product.multi_touch_enabled true
setprop persist.sys.scrollingcache 3

setprop device.internal 1
setprop debug.performance.tuning 1
setprop view.scroll_friction 0.00001
setprop touch.pressure.scale 0.00001
setprop touch.size.calibration 100

sh /data/adb/modules/EnCorinVest/AnyaMelfissa/AnyaMelfissa.sh
sh /data/adb/modules/EnCorinVest/KoboKanaeru/KoboKanaeru.sh

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"

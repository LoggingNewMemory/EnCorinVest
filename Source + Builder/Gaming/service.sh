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
tweak 0 /sys/module/kernel/parameters/panic_on_warn
tweak 0 /sys/module/kernel/parameters/pause_on_oops
tweak 0 /proc/sys/vm/panic_on_oom
tweak 0 /proc/sys/kernel/softlockup_panic
tweak 0 /proc/sys/kernel/panic_on_warn
tweak 0 /proc/sys/kernel/panic_on_oops
tweak 0 /proc/sys/kernel/panic

# EnCorinVest prop
resetprop -n PERF_RES_NET_BT_AUDIO_LOW_LATENCY 1
resetprop -n PERF_RES_NET_WIFI_LOW_LATENCY 1
resetprop -n PERF_RES_NET_MD_WEAK_SIG_OPT 1
resetprop -n PERF_RES_NET_NETD_BOOST_UID 1
resetprop -n PERF_RES_NET_MD_HSR_MODE 1
resetprop -n PERF_RES_THERMAL_POLICY -1

# Celestial Render
resetprop -n debug.egl.force_msaa false
resetprop -n ro.hwui.disable_scissor_opt false
resetprop -n debug.hwui.use_gpu_pixel_buffers true
resetprop -n debug.hwui.render_dirty_regions false
resetprop -n debug.hwui.disable_vsync true
resetprop -n debug.hwui.level 0
resetprop -n ro.hwui.texture_cache_flushrate 0.4
resetprop -n ro.hwui.texture_cache_size 72
resetprop -n ro.hwui.layer_cache_size 48
resetprop -n ro.hwui.r_buffer_cache_size 8
resetprop -n ro.hwui.path_cache_size 32
resetprop -n ro.hwui.gradient_cache_size 1
resetprop -n ro.hwui.drop_shadow_cache_size 6

# Hyperthreading & Multithread
resetprop -n persist.sys.dalvik.hyperthreading true
resetprop -n persist.sys.dalvik.multithread true

# Smooth GUI
resetprop -n persist.service.lgospd.enable 0
resetprop -n persist.service.pcsync.enable 0
resetprop -n persist.sys.lgospd.enable 0
resetprop -n persist.sys.pcsync.enable 0

# Vendor perf
resetprop -n ro.vendor.perf.scroll_opt 1
resetprop -n vendor.perf.framepacing.enable 1

# For QCom
resetprop -n sys.hwc.gpu_perf_mode 1

# Other
resetprop -n debug.gr.numframebuffers 3

# Celestial Tweaks
resetprop -n ro.iorapd.enable false
resetprop -n iorapd.perfetto.enable false
resetprop -n iorapd.readahead.enable false
resetprop -n persist.device_config.runtime_native_boot.iorap_readahead_enable false
resetprop -n persist.sys.purgeable_assets 1

resetprop -n debug.cpurend.vsync false

# Audio Enhancer
resetprop -n persist.audio.fluence.mode endfire
resetprop -n persist.audio.vr.enable true
resetprop -n persist.audio.handset.mic digital
resetprop -n af.resampler.quality 255
resetprop -n mpq.audio.decode true

# Disable Tombstoned
resetprop -n tombstoned.max_tombstone_count 0

# Azenith Props
resetprop -n dalvik.vm.dexopt.thermal-cutoff 0
resetprop -n ro.vendor.sleep.state s2idle
resetprop -n ro.config.low_ram false
resetprop -n ro.config.hw_power_saving true
resetprop -n ro.ril.sensor.sleep.control 1
resetprop -n hwui.disable_vsync true
resetprop -n persist.cpu.freq.boost 1
resetprop -n persist.sys.ui.hw true

# Dalvik
resetprop -n dalvik.vm.systemuicompilerfilter speed-profile
resetprop -n dalvik.vm.systemservercompilerfilter speed-profile
resetprop -n pm.dexopt.bg-dexopt speed
resetprop -n pm.dexopt.install speed-profile
resetprop -n pm.dexopt.shared speed

# Zygote
resetprop -n persist.zygote.preload_threads 3
resetprop -n ro.zygote.disable_gl_preload false
resetprop -n ro.zygote.preload.enable 0
resetprop -n ro.zygote.preload.disable 1

# MTK PERF
resetprop -n ro.mtk_perf_fast_start_win 1
resetprop -n ro.mtk_perf_response_time 1
resetprop -n ro.mtk_perf_simple_start_win 1

# LMK
resetprop -n ro.lmk.debug false
resetprop -n ro.lmk.kill_heaviest_task true
resetprop -n ro.lmk.use_psi true
resetprop -n ro.lmk.use_minfree_levels false
resetprop -n ro.lmk.thrashing_limit_decay 15
resetprop -n ro.lmk.psi_partial_stall_ms 70
resetprop -n ro.lmk.thrashing_limit 20
resetprop -n ro.lmk.downgrade_pressure 35
resetprop -n ro.lmk.swap_free_low_percentage 10

# GPU Optimization
resetprop -n ro.vendor.gpu.optimize.level 5
resetprop -n ro.vendor.gpu.optimize.load_level 3
resetprop -n ro.vendor.gpu.optimize.driver_version 3
resetprop -n ro.vendor.gpu.optimize.preload 1
resetprop -n ro.vendor.gpu.optimize.purgeable_limit 128
resetprop -n ro.vendor.gpu.optimize.retry_max 6
resetprop -n ro.vendor.gpu.optimize.texture_control true
resetprop -n ro.vendor.gpu.optimize.memory_compaction true
resetprop -n ro.vendor.gpu.optimize.hires_preload true
resetprop -n ro.vendor.gpu.optimize.fork_detector true
resetprop -n ro.vendor.gpu.optimize.fork_detector_threshold 5
resetprop -n ro.vendor.gpu.optimize.max_job_count 4
resetprop -n ro.vendor.gpu.optimize.max_target_duration 10
resetprop -n ro.vendor.gpu.optimize.min_target_size 200

# Surface Flinger Optimization
resetprop -n debug.sf.use_phase_offsets_as_durations 1
resetprop -n debug.sf.late.sf.duration 20000000
resetprop -n debug.sf.late.app.duration 15000000
resetprop -n debug.sf.early.sf.duration 20000000
resetprop -n debug.sf.early.app.duration 15000000
resetprop -n debug.sf.earlyGl.sf.duration 20000000
resetprop -n debug.sf.earlyGl.app.duration 15000000
resetprop -n debug.sf.hwc.min.duration 15000000

# Main Optimization
resetprop -n dalvik.vm.dex2oat-minidebuginfo false
resetprop -n dalvik.vm.minidebuginfo false

# Transsion Thermal
resetprop -n ro.dar.thermal_core.support 0

# Disable 60FPS limit
resetprop -n debug.graphics.game_default_frame_rate.disabled true

# Zeta 120 Hz
resetprop -n view.touch_slop 3
resetprop -n touch.deviceType touchScreen
resetprop -n ro.min_pointer_dur 0.00000001
resetprop -n ro.product.multi_touch_enabled true
resetprop -n persist.sys.scrollingcache 3

resetprop -n device.internal 1
resetprop -n debug.performance.tuning 1
resetprop -n view.scroll_friction 0.00001
resetprop -n touch.pressure.scale 0.00001
resetprop -n touch.size.calibration 100

# ANGLE Driver Enable
resetprop -n ro.gfx.angle.supported true

# ANGLE For A15
resetprop -n debug.graphics.angle.developeroption.enable true

# Disable Low Battery FPS Drop
resetprop -n ro.tran_low_battery_60hz_refresh_rate.support 0
resetprop -n sys.surfaceflinger.idle_reduce_framerate_enable no


sh /data/adb/modules/EnCorinVest/AnyaMelfissa/AnyaMelfissa.sh
sh /data/adb/modules/EnCorinVest/KoboKanaeru/KoboKanaeru.sh

# Start HamadaAI (Default is Disabled)

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"

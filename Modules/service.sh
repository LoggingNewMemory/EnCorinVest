sleep 35
mount -t debugfs none /sys/kernel/debug

echo NO_GENTLE_FAIR_SLEEPERS > /sys/kernel/debug/sched_features
echo START_DEBIT > /sys/kernel/debug/sched_features
echo NEXT_BUDDY > /sys/kernel/debug/sched_features
echo LAST_BUDDY > /sys/kernel/debug/sched_features
echo STRICT_SKIP_BUDDY > /sys/kernel/debug/sched_features
echo CACHE_HOT_BUDDY > /sys/kernel/debug/sched_features
echo WAKEUP_PREEMPTION > /sys/kernel/debug/sched_features
echo NO_HRTICK > /sys/kernel/debug/sched_features
echo NO_DOUBLE_TICK > /sys/kernel/debug/sched_features
echo LB_BIAS > /sys/kernel/debug/sched_features
echo NONTASK_CAPACITY > /sys/kernel/debug/sched_features
echo NO_TTWU_QUEUE > /sys/kernel/debug/sched_features
echo NO_SIS_AVG_CPU > /sys/kernel/debug/sched_features
echo RT_PUSH_IPI > /sys/kernel/debug/sched_features
echo NO_FORCE_SD_OVERLAP > /sys/kernel/debug/sched_features
echo NO_RT_RUNTIME_SHARE > /sys/kernel/debug/sched_features
echo NO_LB_MIN > /sys/kernel/debug/sched_features
echo ATTACH_AGE_LOAD > /sys/kernel/debug/sched_features
echo ENERGY_AWARE > /sys/kernel/debug/sched_features
echo NO_MIN_CAPACITY_CAPPING > /sys/kernel/debug/sched_features
echo NO_FBT_STRICT_ORDER > /sys/kernel/debug/sched_features
echo EAS_USE_NEED_IDLE > /sys/kernel/debug/sched_features

# Reset Prop

resetprop -n persist.logd.size 0
resetprop -n ro.logd.size.stats 0
resetprop -n logd.logpersistd.enable false
resetprop -n tombstoned.max_tombstone_count 0
resetprop -n ro.lmk.debug false
resetprop -n ro.lmk.log_stats false
resetprop -n debug.sf.early.app.duration 800000
resetprop -n debug.sf.early.sf.duration 800000
resetprop -n debug.sf.earlyGl.app.duration 800000
resetprop -n debug.sf.earlyGl.sf.duration 800000
resetprop -n debug.sf.early_app_phase_offset_ns 800000
resetprop -n debug.sf.early_gl_app_phase_offset_ns 800000
resetprop -n debug.sf.early_phase_offset_ns 800000
resetprop -n debug.sf.high_fps.early.app.duration 800000
resetprop -n debug.sf.high_fps.early.sf.duration 800000
resetprop -n debug.sf.high_fps.earlyGl.app.duration 800000
resetprop -n debug.sf.high_fps.hwc.min.duration 1250000
resetprop -n debug.sf.high_fps.late.app.duration 1250000
resetprop -n debug.sf.high_fps.late.sf.duration 1250000
resetprop -n debug.sf.high_fps_early_app_phase_offset_ns 800000
resetprop -n debug.sf.high_fps_early_cpu_app_offset_ns 144
resetprop -n debug.sf.high_fps_early_gl_app_phase_offset_ns 800000
resetprop -n debug.sf.high_fps_early_gpu_app_offset_ns 144
resetprop -n debug.sf.high_fps_early_phase_offset_ns 800000
resetprop -n debug.sf.high_fps_late_app_phase_offset_ns 1250000
resetprop -n debug.sf.high_fps_late_gl_phase_offset_ns 1250000
resetprop -n debug.sf.high_fps_late_phase_offset_sleepns 1250000
resetprop -n debug.sf.high_fps_late_sf_phase_offset_ns 1250000
resetprop -n debug.sf.perf_fps_early_gl_phase_offset_ns 800000
resetprop -n debug.hwui.level high
resetprop -n debug.overlayui.enable 1
resetprop -n debug.performance.tuning 1
resetprop -n hwui.disable_vsync true
resetprop -n persist.cpu.freq.boost 1
resetprop -n ro.launcher.blur.appLaunch 0
resetprop -n ro.surface_flinger.supports_background_blur 0
resetprop -n ro.sf.blurs_are_expensive 0
resetprop -n persist.sys.sf.disable_blurs true
resetprop -n enable_blurs_on_windows 0
resetprop -n disableBlurs true
resetprop -n disableBackgroundBlur true
resetprop -n ro.sf.blurs_are_caro 1
resetprop -n ro.miui.has_real_blur 0
resetprop -n persist.sys.background_blur_supported false
su -c cmd window disable-blur 1
su -c wm disable-blur 1
resetprop -n persist.sys.background_blur_supported false
resetprop -n ro.surface_flinger.max_frame_buffer_acquired_buffers 120
resetprop -n ro.boottime.thermal_core 0

# SkiaVK

resetprop -n debug.hwui.renderer skiavk
resetprop -n debug.renderengine.backend skiavkthreaded
resetprop -n ro.hwui.use_vulkan 1
resetprop -n ro.hwui.hardware.vulkan true
resetprop -n ro.hwui.use_vulkan true
resetprop -n ro.hwui.skia.show_vulkan_pipeline true
resetprop -n persist.sys.disable_skia_path_ops false
resetprop -n ro.config.hw_high_perf true
resetprop -n debug.hwui.disable_scissor_opt true
resetprop -n debug.vulkan.layers.enable 1
resetprop -n debug.hwui.render_thread true

# Optimize GPU Cache (by. Evoloser)

resetprop -n ro.vendor.gpu.optimize.level 3
resetprop -n ro.vendor.gpu.optimize.load_level 3
resetprop -n ro.vendor.gpu.optimize.driver_version 2
resetprop -n ro.vendor.gpu.optimize.preload 1
resetprop -n ro.vendor.gpu.optimize.purgeable_limit 64
resetprop -n ro.vendor.gpu.optimize.retry_max 1
resetprop -n ro.vendor.gpu.optimize.texture_control true
resetprop -n ro.vendor.gpu.optimize.memory_compaction true
resetprop -n ro.vendor.gpu.optimize.hires_preload true
resetprop -n ro.vendor.gpu.optimize.fork_detector true
resetprop -n ro.vendor.gpu.optimize.fork_detector_threshold 20
resetprop -n ro.vendor.gpu.optimize.max_job_count 2
resetprop -n ro.vendor.gpu.optimize.max_target_duration 20
resetprop -n ro.vendor.gpu.optimize.min_target_size 100
resetprop -n ro.config.fifo_optimize true
resetprop -n ro.config.buffer_cache_size 2
resetprop -n ro.config.max_starting_cache_size 16
resetprop -n ro.config.min_chunk_cache_size 256

resetprop -n debug.hwui.level high
resetprop -n debug.overlayui.enable 1
resetprop -n debug.performance.tuning 1
resetprop -n hwui.render_dirty_regions false
resetprop -n hwui.disable_vsync true
resetprop -n persist.cpu.freq.boost 1
resetprop -n debug.hwui.render_dirty_regions false

# Composition and Performance Settings
resetprop -n persist.sys.composition.type mdp
resetprop -n debug.composition.type mdp
resetprop -n debug.hwui.show_dirty_regions false

# Additional Optimizations
resetprop -n debug.hwui.use_gpu_pixel_buffers false
resetprop -n debug.hwui.use_buffer_age false
resetprop -n persist.sys.perf.topAppRenderThreadBoost.enable true

# RenderScript
resetprop -n debug.rs.default-CPU-driver 1
resetprop -n debug.rs.forcecompat 1
resetprop -n debug.rs.max-threads 8
resetprop -n debug.rs.script 0
resetprop -n debug.rs.profile 0
resetprop -n debug.rs.shader 0
resetprop -n debug.rs.shader.attributes 0
resetprop -n debug.rs.shader.uniforms 0
resetprop -n debug.rs.visual 0
resetprop -n debug.rs.reduce 1
resetprop -n debug.rs.reduce-split-accum 1
resetprop -n debug.rs.reduce-accum 1
resetprop -n debug.rs.forcerecompile 0
resetprop -n debug.rs.debug 0
resetprop -n debug.rs.precision rs_fp_imprecise
resetprop -n debug.bcc.nocache true
resetprop -n vendor.debug.rs.script 0
resetprop -n vendor.debug.rs.profile 0
resetprop -n vendor.debug.rs.shader 0
resetprop -n vendor.debug.rs.shader.attributes 0
resetprop -n vendor.debug.rs.shader.uniforms 0
resetprop -n vendor.debug.rs.visual 0
resetprop -n vendor.debug.rs.forcerecompile 0
resetprop -n vendor.debug.rs.debug 0

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' TagWelcome 'EnCorinVest - オンライン'"

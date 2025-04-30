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

# Celestial Render

# Hyperthreading & Multithread

# Smooth GUI

# Vendor perf

# For QCom

# Other

# Celestial Tweaks


# Audio Enhancer

# Disable Tombstoned

# Azenith Props

# Dalvik

# Zygote

# MTK PERF

# LMK

# GPU Optimization

# Surface Flinger Optimization

# Main Optimization

# Transsion Thermal

# Disable 60FPS limit

# Zeta 120 Hz


# ANGLE Driver Enable
setprop ro.gfx.angle.supported true

# ANGLE For A15
setprop debug.graphics.angle.developeroption.enable true

# Disable Low Battery FPS Drop


sh /data/adb/modules/EnCorinVest/AnyaMelfissa/AnyaMelfissa.sh
sh /data/adb/modules/EnCorinVest/KoboKanaeru/KoboKanaeru.sh

# Start HamadaAI (Default is Disabled)

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"

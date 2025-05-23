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
        ;;

    "mediatek")
        ;;

    "exynos")
        ;;

    "unisoc")
        ;;

    *)
        ;;
esac

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


sh /data/adb/modules/EnCorinVest/AnyaMelfissa/AnyaMelfissa.sh
sh /data/adb/modules/EnCorinVest/KoboKanaeru/KoboKanaeru.sh

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"

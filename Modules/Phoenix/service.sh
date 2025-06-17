#!/system/bin/sh

# EnCorinVest Service Script with Real-time Crash Detection
LOG_FILE="/data/EnCorinVest/EnCorinVest.log"
LOG_DIR="/data/EnCorinVest"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to write log header
write_log_header() {
    echo "" >> "$LOG_FILE"
    echo "===============================" >> "$LOG_FILE"
    echo "        EnCorinVest Log" >> "$LOG_FILE"
    echo "===============================" >> "$LOG_FILE"
    echo "Device: $(getprop ro.product.model)" >> "$LOG_FILE"
    echo "Kernel: $(uname -r)" >> "$LOG_FILE"
    echo "Android Version: $(getprop ro.build.version.release)" >> "$LOG_FILE"
    echo "OS: $(getprop ro.build.display.id)" >> "$LOG_FILE"
    echo "Date: $(date '+%Y-%m-%d')" >> "$LOG_FILE"
    echo "Time: $(date '+%H:%M:%S')" >> "$LOG_FILE"
    echo "===============================" >> "$LOG_FILE"
}

# Function to log messages with timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to capture system state for crash analysis
capture_crash_details() {
    local crash_type="$1"
    local crash_line="$2"
    
    write_log_header
    log_message "=== $crash_type DETECTED ==="
    log_message "Trigger: $crash_line"
    
    # Capture recent kernel messages
    echo "" >> "$LOG_FILE"
    echo "[DMESG - Last 100 lines]" >> "$LOG_FILE"
    dmesg | tail -100 >> "$LOG_FILE" 2>/dev/null
    
    # Capture recent logcat context
    echo "" >> "$LOG_FILE"
    echo "[LOGCAT CONTEXT - Last 200 lines]" >> "$LOG_FILE"
    logcat -d -t 200 >> "$LOG_FILE" 2>/dev/null
    
    # Capture system info
    echo "" >> "$LOG_FILE"
    echo "[SYSTEM INFO]" >> "$LOG_FILE"
    echo "Memory: $(cat /proc/meminfo | grep MemAvailable)" >> "$LOG_FILE"
    echo "Load: $(cat /proc/loadavg)" >> "$LOG_FILE"
    echo "Uptime: $(cat /proc/uptime)" >> "$LOG_FILE"
    
    log_message "=== END CRASH CAPTURE ==="
    echo "" >> "$LOG_FILE"
}

# Real-time crash monitoring using logcat
monitor_crashes_realtime() {
    # Monitor logcat in real-time for crashes
    logcat -v time | while read -r line; do
        case "$line" in
            *"FATAL EXCEPTION"*|*"AndroidRuntime"*"FATAL"*|*"*** FATAL EXCEPTION"*)
                capture_crash_details "APPLICATION CRASH" "$line"
                ;;
            *"System.exit called"*|*"Process"*"died"*|*"system_server died"*)
                capture_crash_details "SYSTEM PROCESS CRASH" "$line"
                ;;
            *"tombstone"*|*"Tombstone written"*|*"*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***"*)
                capture_crash_details "NATIVE CRASH" "$line"
                ;;
            *"Kernel panic"*|*"Internal error"*|*"Oops"*)
                capture_crash_details "KERNEL CRASH" "$line"
                ;;
            *"lowmemorykiller"*|*"Out of memory"*|*"OOM"*)
                capture_crash_details "MEMORY CRASH" "$line"
                ;;
            *"Watchdog"*|*"SWT"*|*"SystemServer"*"Watchdog"*)
                capture_crash_details "WATCHDOG CRASH" "$line"
                ;;
        esac
    done &
}

# Monitor kernel messages in real-time
monitor_kernel_realtime() {
    # Monitor dmesg for kernel crashes
    dmesg -w | while read -r line; do
        case "$line" in
            *"panic"*|*"Oops"*|*"BUG:"*|*"Call Trace"*|*"segfault"*)
                capture_crash_details "KERNEL PANIC" "$line"
                ;;
            *"Out of memory"*|*"Killed process"*|*"oom-killer"*)
                capture_crash_details "KERNEL OOM" "$line"
                ;;
        esac
    done &
}

# Initialize crash logging
write_log_header
log_message "EnCorinVest Real-time Crash Monitor Initialized"

# Wait for boot completion
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 10
done

# Start real-time crash monitoring
log_message "Starting real-time crash monitoring..."
monitor_crashes_realtime
monitor_kernel_realtime

# Store current uptime for reboot detection
cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 > "$LOG_DIR/last_uptime"

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

tweak 0 /proc/sys/kernel/panic
tweak 0 /proc/sys/kernel/panic_on_oops
tweak 0 /proc/sys/kernel/panic_on_warn
tweak 0 /proc/sys/kernel/softlockup_panic

sh /data/adb/modules/EnCorinVest/AnyaMelfissa/AnyaMelfissa.sh
sh /data/adb/modules/EnCorinVest/KoboKanaeru/KoboKanaeru.sh

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"
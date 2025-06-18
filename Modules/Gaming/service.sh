#!/system/bin/sh

# EnCorinVest Service Script with Minimal Crash Detection
LOG_FILE="/data/EnCorinVest/EnCorinVest.log"
LOG_DIR="/data/EnCorinVest"
MAX_LOG_SIZE=5242880  # 5MB limit

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to rotate log if too large
rotate_log() {
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
        rm -f "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] New log created after size limit reached" > "$LOG_FILE"
    fi
}

# Function to log messages with timestamp
log_message() {
    rotate_log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

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

# Function to capture minimal crash details
capture_crash_minimal() {
    local crash_type="$1"
    local crash_line="$2"
    
    rotate_log
    write_log_header
    log_message "=== $crash_type ==="
    log_message "Details: $(echo "$crash_line" | head -c 200)"
    
    # Only capture critical system info (no full dumps)
    local mem_avail=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
    local load_avg=$(cat /proc/loadavg | awk '{print $1}')
    log_message "Memory: ${mem_avail}kB available, Load: $load_avg"
    
    log_message "=== END ==="
}

# Simplified crash monitoring - only critical crashes
monitor_crashes_realtime() {
    logcat -v brief | while read -r line; do
        case "$line" in
            *"FATAL EXCEPTION"*|*"AndroidRuntime"*"FATAL"*)
                capture_crash_minimal "APP_CRASH" "$line"
                ;;
            *"system_server died"*|*"SystemServer"*"died"*)
                capture_crash_minimal "SYSTEM_CRASH" "$line"
                ;;
            *"Kernel panic"*|*"Internal error"*)
                capture_crash_minimal "KERNEL_CRASH" "$line"
                ;;
            *"lowmemorykiller"*"killed"*)
                capture_crash_minimal "OOM_KILL" "$line"
                ;;
            *"System.exit called"*|*"Process"*"died"*)
                capture_crash_minimal "PROCESS_DIED" "$line"
                ;;
            *"Watchdog"*|*"SWT"*|*"SystemServer"*"Watchdog"*)
                capture_crash_minimal "WATCHDOG_FREEZE" "$line"
                ;;
        esac
    done &
}

# Minimal kernel monitoring - panics and freezes
monitor_kernel_realtime() {
    dmesg -w | while read -r line; do
        case "$line" in
            *"panic"*|*"Oops"*|*"BUG:"*)
                capture_crash_minimal "KERNEL_PANIC" "$line"
                ;;
            *"hung_task"*|*"blocked for more than"*|*"INFO: task"*)
                capture_crash_minimal "SYSTEM_HANG" "$line"
                ;;
            *"RCU stall"*|*"soft lockup"*|*"hard lockup"*)
                capture_crash_minimal "SYSTEM_LOCKUP" "$line"
                ;;
        esac
    done &
}

# Initialize with minimal logging
log_message "EnCorinVest Monitor Started - Device: $(getprop ro.product.model)"

# Wait for boot completion
while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 10
done

# Start monitoring
log_message "Crash monitoring active"
monitor_crashes_realtime
monitor_kernel_realtime

# Store uptime for reboot detection
cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1 > "$LOG_DIR/last_uptime"

##############################
# Main Service Script
##############################

# Mali Scheduler Tweaks By: MiAzami
mali_dir=$(ls -d /sys/devices/platform/soc/*mali*/scheduling 2>/dev/null | head -n 1)
mali1_dir=$(ls -d /sys/devices/platform/soc/*mali* 2>/dev/null | head -n 1)

tweak() {
    if [ -e "$1" ]; then
        echo "$2" > "$1"
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
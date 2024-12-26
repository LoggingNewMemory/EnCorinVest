sleep 30

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

# Kernel Tweaks by: PersonPenggoreng

echo '0' > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
echo '1' > /sys/module/zswap/parameters/enabled
echo '8' > /sys/block/zram0/max_comp_streams
echo '100' > /proc/sys/vm/overcommit_ratio
echo '20' > /proc/sys/vm/vfs_cache_pressure
echo '750' > /proc/sys/vm/extfrag_threshold
echo '27337' > /proc/sys/vm/extra_free_kbytes
echo '6422' > /proc/sys/vm/min_free_kbytes

# CPU and I/O Scheduler
echo 'deadline' > /sys/block/mmcblk0rpmb/queue/scheduler
echo 'deadline' > /sys/block/mmcblk0/queue/scheduler
echo 'deadline' > /sys/block/mmcblk1/queue/scheduler
echo '1024' > /sys/block/mmcblk0/queue/read_ahead_kb
echo '1024' > /sys/block/mmcblk1/queue/read_ahead_kb

# Cpuset Configuration
echo '0-2' > /dev/cpuset/background/cpus
echo '0-7' > /dev/cpuset/top-app/cpus
echo '3,4-6,7' > /dev/cpuset/foreground/cpus
echo '0-1' > /dev/cpuset/system-background/cpus

# Stune Configuration
for stune in /dev/stune/*; do
  echo '0' > ${stune}/schedtune.boost
done
echo '70' > /dev/stune/top-app/schedtune.boost

# Uclamp Configuration
for cpuset in /dev/cpuset/*; do
  echo 'max' > ${cpuset}/uclamp.max
  echo '10' > ${cpuset}/uclamp.min
done

# Misc Settings
echo '2048' > /proc/sys/kernel/random/read_wakeup_threshold
echo '2048' > /proc/sys/kernel/random/write_wakeup_threshold
echo '0' > /proc/sys/kernel/sysctl_writes_strict
echo '0' > /proc/sys/kernel/sched_tunable_scaling

# Apply all settings
sysctl -p
echo '3' > /proc/sys/vm/drop_caches

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagWelcome 'EnCorinVest - オンライン'"

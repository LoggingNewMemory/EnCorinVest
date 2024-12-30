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
TOTAL_RAM=8000

MODDIR=${0%/*}
UCLAMP_PATH="/dev/stune/top-app/uclamp.max"
CPUSET_PATH="/dev/cpuset"
MODULE_PATH="/sys/module"
KERNEL_PATH="/proc/sys/kernel"
IPV4_PATH="/proc/sys/net/ipv4"
MEMORY_PATH="/proc/sys/vm"
MGLRU_PATH="/sys/kernel/mm/lru_gen"
SCHEDUTIL2_PATH="/sys/devices/system/cpu/cpufreq/schedutil"
SCHEDUTIL_PATH="/sys/devices/system/cpu/cpu0/cpufreq/schedutil"

for path in /sys/module/kernel/parameters/panic /proc/sys/kernel/panic_on_oops /sys/module/kernel/parameters/panic_on_warn /sys/module/kernel/parameters/pause_on_oops /proc/sys/vm/panic_on_oom; do
  echo '0' > $path
done

if [ -d "$SCHEDUTIL2_PATH" ]; then
    tweak "$SCHEDUTIL2_PATH/up_rate_limit_us" 10000
    tweak "$SCHEDUTIL2_PATH/down_rate_limit_us" 20000
elif [ -e "$SCHEDUTIL_PATH" ]; then
    for cpu in /sys/devices/system/cpu/*/cpufreq/schedutil; do
        tweak "${cpu}/up_rate_limit_us" 10000
        tweak "${cpu}/down_rate_limit_us" 20000
    done
fi

tweak "/proc/sys/vm/overcommit_memory" 1
tweak "$KERNEL_PATH/sched_autogroup_enabled" 0
tweak "$KERNEL_PATH/sched_child_runs_first" 1
tweak "$MEMORY_PATH/vfs_cache_pressure" 50
tweak "$MEMORY_PATH/stat_interval" 30
tweak "$MEMORY_PATH/compaction_proactiveness" 0
tweak "$MEMORY_PATH/page-cluster" 0

if [ $TOTAL_RAM -lt 8000 ]; then
    tweak "$MEMORY_PATH/swappiness" 60
else
    tweak "$MEMORY_PATH/swappiness" 0
fi
tweak "$MEMORY_PATH/dirty_ratio" 60

if [ -d "$MGLRU_PATH" ]; then
    tweak "$MGLRU_PATH/min_ttl_ms" 5000
fi

tweak "$KERNEL_PATH/perf_cpu_time_max_percent" 10

if [ -e "$KERNEL_PATH/sched_schedstats" ]; then
    tweak "$KERNEL_PATH/sched_schedstats" 0
fi
tweak "$KERNEL_PATH/printk" "0        0 0 0"
tweak "$KERNEL_PATH/printk_devkmsg" "off"
for queue in /sys/block/*/queue; do
    tweak "$queue/iostats" 0
    tweak "$queue/nr_requests" 64
done

tweak "$KERNEL_PATH/sched_migration_cost_ns" 50000
tweak "$KERNEL_PATH/sched_min_granularity_ns" 1000000
tweak "$KERNEL_PATH/sched_wakeup_granularity_ns" 1500000

tweak "$KERNEL_PATH/timer_migration" 0

if [ -d "$UCLAMP_PATH" ]; then
    tweak "$CPUSET_PATH/top-app/uclamp.max" max
    tweak "$CPUSET_PATH/top-app/uclamp.min" 10
    tweak "$CPUSET_PATH/top-app/uclamp.boosted" 1
    tweak "$CPUSET_PATH/top-app/uclamp.latency_sensitive" 1
    tweak "$CPUSET_PATH/foreground/uclamp.max" 50
    tweak "$CPUSET_PATH/foreground/uclamp.min" 0
    tweak "$CPUSET_PATH/foreground/uclamp.boosted" 0
    tweak "$CPUSET_PATH/foreground/uclamp.latency_sensitive" 0
    tweak "$CPUSET_PATH/background/uclamp.max" max
    tweak "$CPUSET_PATH/background/uclamp.min" 20
    tweak "$CPUSET_PATH/background/uclamp.boosted" 0
    tweak "$CPUSET_PATH/background/uclamp.latency_sensitive" 0
    tweak "$CPUSET_PATH/system-background/uclamp.min" 0
    tweak "$CPUSET_PATH/system-background/uclamp.max" 40
    tweak "$CPUSET_PATH/system-background/uclamp.boosted" 0
    tweak "$CPUSET_PATH/system-background/uclamp.latency_sensitive" 0
    sysctl -w kernel.sched_util_clamp_min_rt_default=0
    sysctl -w kernel.sched_util_clamp_min=128
fi

tweak "$KERNEL_PATH/sched_min_task_util_for_colocation" 0

if [ -d "$MODULE_PATH/mmc_core" ]; then
    tweak "$MODULE_PATH/mmc_core/parameters/use_spi_crc" 0
fi

if [ -d "$MODULE_PATH/zswap" ]; then
    tweak "$MODULE_PATH/zswap/parameters/compressor" lz4
    tweak "$MODULE_PATH/zswap/parameters/zpool" zsmalloc
fi

tweak "$MODULE_PATH/workqueue/parameters/power_efficient" 1

tweak "$IPV4_PATH/tcp_timestamps" 0

tweak "$IPV4_PATH/tcp_low_latency" 1

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest - オンライン'"

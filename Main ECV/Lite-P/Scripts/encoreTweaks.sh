MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"

# All Encore Performance Script
encore_mediatek_perf() {
    # PPM policies
	if [ -d /proc/ppm ]; then
		grep -E "$PPM_POLICY" /proc/ppm/policy_status | while read -r row; do
			tweak "${row:1:1} 0" /proc/ppm/policy_status
		done
	fi

	# # Force off FPSGO (We Use FPSGo Here)
	# tweak 0 /sys/kernel/fpsgo/common/force_onoff

	# MTK Power and CCI mode
	tweak 1 /proc/cpufreq/cpufreq_cci_mode
	tweak 3 /proc/cpufreq/cpufreq_power_mode

	# DDR Boost mode
	tweak 1 /sys/devices/platform/boot_dramboost/dramboost/dramboost

	# EAS/HMP Switch
	tweak 0 /sys/devices/system/cpu/eas/enable

	# GPU Frequency
	if [ -d /proc/gpufreq ]; then
		gpu_freq=$(sed -n 's/.*freq = \([0-9]\{1,\}\).*/\1/p' /proc/gpufreq/gpufreq_opp_dump | sort -nr | head -n 1)
		tweak "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
	elif [ -d /proc/gpufreqv2 ]; then
		tweak 0 /proc/gpufreqv2/fix_target_opp_index
	fi

	# Disable GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			tweak "$setting 1" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Disable battery current limiter
	tweak "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# DRAM Frequency
	tweak 0 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
	tweak 0 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
	devfreq_max_perf /sys/class/devfreq/mtk-dvfsrc-devfreq

	# Eara Thermal
	tweak 0 /sys/kernel/eara_thermal/enable
}

encore_snapdragon_perf() {
    # Qualcomm CPU Bus and DRAM frequencies
	for path in /sys/class/devfreq/*cpu*-lat; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/*cpu*-bw; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/*llccbw*; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/*bus_llcc*; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/*bus_ddr*; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/*memlat*; do
		devfreq_max_perf "$path"
	done &
	for path in /sys/class/devfreq/*cpubw*; do
		devfreq_max_perf "$path"
	done &

	# GPU, memory and bus frequency tweak
	devfreq_max_perf /sys/class/kgsl/kgsl-3d0/devfreq

	# Commented due causing random reboot in Realme 5i
	#for path in /sys/class/devfreq/*gpubw*; do
	#	devfreq_max_perf "$path"
	#done &
	for path in /sys/class/devfreq/*kgsl-ddr-qos*; do
		devfreq_max_perf "$path"
	done &

	# Disable GPU Bus split (Temporary Disabled Until Dev Fix)
	tweak 0 /sys/class/kgsl/kgsl-3d0/bus_split

	# Force GPU clock on (Temporary Disabled Until Dev Fix)
	tweak 1 /sys/class/kgsl/kgsl-3d0/force_clk_on
}

encore_exynos_perf() {
    	# GPU Frequency
	gpu_path="/sys/kernel/gpu"

	if [ -d "$gpu_path" ]; then
		freq=$(which_maxfreq "$gpu_path/gpu_available_frequencies")
		tweak "$freq" "$gpu_path/gpu_max_clock"
		tweak "$freq" "$gpu_path/gpu_min_clock"
	fi

	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	tweak always_on "$mali_sysfs/power_policy"

	# DRAM and Buses Frequency
	for path in /sys/class/devfreq/*{bci,mif,dsu,int}; do
		devfreq_max_perf "$path"
	done &
}

encore_unisoc_perf() {
    # GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_max_perf "$gpu_path"
}

# All Encore Balanced Script

encore_mediatek_normal() {
	# PPM policies
	if [ -d /proc/ppm ]; then
		grep -E "$PPM_POLICY" /proc/ppm/policy_status | while read -r row; do
			tweak "${row:1:1} 1" /proc/ppm/policy_status
		done
	fi

	# FPSGO Still Used Here
	# # Free FPSGO
	# tweak 2 /sys/kernel/fpsgo/common/force_onoff

	# MTK Power and CCI mode
	tweak 0 /proc/cpufreq/cpufreq_cci_mode
	tweak 0 /proc/cpufreq/cpufreq_power_mode
	
	# DDR Boost mode
	tweak 0 /sys/devices/platform/boot_dramboost/dramboost/dramboost
	
	# EAS/HMP Switch
	tweak 1 /sys/devices/system/cpu/eas/enable

	# GPU Frequency
	if [ -d /proc/gpufreq ]; then
		write 0 /proc/gpufreq/gpufreq_opp_freq 2>/dev/null
	elif [ -d /proc/gpufreqv2 ]; then
		write -1 /proc/gpufreqv2/fix_target_opp_index
	fi

	# GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			tweak "$setting 0" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Enable Power Budget management for new 5.x mtk kernels
	tweak "stop 0" /proc/pbm/pbm_stop

	# Enable battery current limiter
	tweak "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# DRAM Frequency
	write -1 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
	write -1 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
	devfreq_unlock /sys/class/devfreq/mtk-dvfsrc-devfreq

	# Eara Thermal
	tweak 1 /sys/kernel/eara_thermal/enable
}

encore_snapdragon_normal() {
	# Qualcomm CPU Bus and DRAM frequencies
	for path in /sys/class/devfreq/*cpu*-lat; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/*cpu*-bw; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/*llccbw*; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/*bus_llcc*; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/*bus_ddr*; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/*memlat*; do
		devfreq_unlock "$path"
	done &
	for path in /sys/class/devfreq/*cpubw*; do
		devfreq_unlock "$path"
	done &

	# GPU, memory and bus frequency tweak
	devfreq_unlock /sys/class/kgsl/kgsl-3d0/devfreq

	# Commented due causing random reboot in Realme 5i
	#for path in /sys/class/devfreq/*gpubw*; do
	#	devfreq_unlock "$path"
	#done &
	for path in /sys/class/devfreq/*kgsl-ddr-qos*; do
		devfreq_unlock "$path"
	done &

	# Enable back GPU Bus split
	tweak 1 /sys/class/kgsl/kgsl-3d0/bus_split

	# Free GPU clock on/off
	tweak 0 /sys/class/kgsl/kgsl-3d0/force_clk_on
}


encore_exynos_normal() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"

	if [ -d "$gpu_path" ]; then
		max_freq=$(which_maxfreq "$gpu_path/gpu_available_frequencies")
		min_freq=$(which_minfreq "$gpu_path/gpu_available_frequencies")
		write "$max_freq" "$gpu_path/gpu_max_clock"
		write "$min_freq" "$gpu_path/gpu_min_clock"
	fi

	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	tweak coarse_demand "$mali_sysfs/power_policy"
}

encore_unisoc_normal() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_unlock "$gpu_path"
}

# All Encore Powersave Script

encore_mediatek_powersave() {
	# MTK CPU Power mode to low power
	tweak 1 /proc/cpufreq/cpufreq_power_mode

	# GPU Frequency
	if [ -d /proc/gpufreq ]; then
		gpu_freq=$(sed -n 's/.*freq = \([0-9]\{1,\}\).*/\1/p' /proc/gpufreq/gpufreq_opp_dump | sort -n | head -n 1)
		tweak "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
	elif [ -d /proc/gpufreqv2 ]; then
		min_gpufreq_index=$(awk -F'[][]' '{print $2}' /proc/gpufreqv2/gpu_working_opp_table | sort -n | tail -1)
		tweak "$min_gpufreq_index" /proc/gpufreqv2/fix_target_opp_index
	fi
}

encore_snapdragon_powersave() {
	# GPU Frequency
	devfreq_min_perf /sys/class/kgsl/kgsl-3d0/devfreq
}

encore_exynos_powersave() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"

	if [ -d "$gpu_path" ]; then
		freq=$(which_minfreq "$gpu_path/gpu_available_frequencies")
		tweak "$freq" "$gpu_path/gpu_min_clock"
		tweak "$freq" "$gpu_path/gpu_max_clock"
	fi
}

encore_unisoc_powersave() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_min_perf "$gpu_path"
}
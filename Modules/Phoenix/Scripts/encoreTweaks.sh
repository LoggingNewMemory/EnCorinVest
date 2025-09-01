MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"

# All Encore Performance Script
encore_mediatek_perf() {
	# PPM policies
	if [ -d /proc/ppm ]; then
		grep -E "$PPM_POLICY" /proc/ppm/policy_status | while read -r row; do
			apply "${row:1:1} 0" /proc/ppm/policy_status
		done
	fi

	# Force off FPSGO
	# apply 0 /sys/kernel/fpsgo/common/force_onoff

	# MTK Power and CCI mode
	apply 1 /proc/cpufreq/cpufreq_cci_mode
	apply 3 /proc/cpufreq/cpufreq_power_mode

	# DDR Boost mode
	apply 1 /sys/devices/platform/boot_dramboost/dramboost/dramboost

	# EAS/HMP Switch
	apply 0 /sys/devices/system/cpu/eas/enable

	# Disable GED KPI
	apply 0 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled

	# GPU Frequency
	if [ $LITE_MODE -eq 0 ]; then
		if [ -d /proc/gpufreqv2 ]; then
			apply 0 /proc/gpufreqv2/fix_target_opp_index
		else
			gpu_freq=$(sed -n 's/.*freq = \([0-9]\{1,\}\).*/\1/p' /proc/gpufreq/gpufreq_opp_dump | head -n 1)
			apply "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
		fi
	else
		apply 0 /proc/gpufreq/gpufreq_opp_freq
		apply -1 /proc/gpufreqv2/fix_target_opp_index

		# Set min freq via GED
		if [ -d /proc/gpufreqv2 ]; then
			mid_oppfreq=$(mtk_gpufreq_midfreq_index /proc/gpufreqv2/gpu_working_opp_table)
		else
			mid_oppfreq=$(mtk_gpufreq_midfreq_index /proc/gpufreq/gpufreq_opp_dump)
		fi

		apply $mid_oppfreq /sys/kernel/ged/hal/custom_boost_gpu_freq
	fi

	# Disable GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			apply "$setting 1" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Disable battery current limiter
	apply "stop 1" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# DRAM Frequency
	if [ $LITE_MODE -eq 0 ]; then
		apply 0 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
		apply 0 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
		devfreq_max_perf /sys/class/devfreq/mtk-dvfsrc-devfreq
	else
		apply -1 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
		apply -1 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
		devfreq_mid_perf /sys/class/devfreq/mtk-dvfsrc-devfreq
	fi

	# Eara Thermal
	apply 0 /sys/kernel/eara_thermal/enable
}

encore_snapdragon_perf() {
	# Qualcomm CPU Bus and DRAM frequencies
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*cpu*-lat \
			/sys/class/devfreq/*cpu*-bw \
			/sys/class/devfreq/*llccbw* \
			/sys/class/devfreq/*bus_llcc* \
			/sys/class/devfreq/*bus_ddr* \
			/sys/class/devfreq/*memlat* \
			/sys/class/devfreq/*cpubw* \
			/sys/class/devfreq/*kgsl-ddr-qos*; do

			[ $LITE_MODE -eq 1 ] &&
				devfreq_mid_perf "$path" ||
				devfreq_max_perf "$path"
		done &

		for component in DDR LLCC L3; do
			path="/sys/devices/system/cpu/bus_dcvs/$component"
			[ "$LITE_MODE" -eq 1 ] &&
				qcom_cpudcvs_mid_perf "$path" ||
				qcom_cpudcvs_max_perf "$path"
		done &
	}

	# GPU tweak
	gpu_path="/sys/class/kgsl/kgsl-3d0/devfreq"
	[ "$LITE_MODE" -eq 0 ] && devfreq_max_perf "$gpu_path" || devfreq_mid_perf "$gpu_path"

	# Disable GPU Bus split
	apply 0 /sys/class/kgsl/kgsl-3d0/bus_split

	# Force GPU clock on
	apply 1 /sys/class/kgsl/kgsl-3d0/force_clk_on
}

encore_exynos_perf() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"
	[ -d "$gpu_path" ] && {
		max_freq=$(which_maxfreq "$gpu_path/gpu_available_frequencies")
		apply "$max_freq" "$gpu_path/gpu_max_clock"

		if [ $LITE_MODE -eq 1 ]; then
			mid_freq=$(which_midfreq "$gpu_path/gpu_available_frequencies")
			apply "$mid_freq" "$gpu_path/gpu_min_clock"
		else
			apply "$max_freq" "$gpu_path/gpu_min_clock"
		fi
	}

	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	apply always_on "$mali_sysfs/power_policy"

	# DRAM and Buses Frequency
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*devfreq_mif*; do
			[ $LITE_MODE -eq 1 ] &&
				devfreq_mid_perf "$path" ||
				devfreq_max_perf "$path"
		done &
	}
}

encore_unisoc_perf() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && {
		if [ $LITE_MODE -eq 0 ]; then
			devfreq_max_perf "$gpu_path"
		else
			devfreq_mid_perf "$gpu_path"
		fi
	}
}

# All Encore Balanced Script

encore_mediatek_normal() {
	# PPM policies
	if [ -d /proc/ppm ]; then
		grep -E "$PPM_POLICY" /proc/ppm/policy_status | while read -r row; do
			apply "${row:1:1} 1" /proc/ppm/policy_status
		done
	fi

	# Free FPSGO
	# apply 2 /sys/kernel/fpsgo/common/force_onoff

	# MTK Power and CCI mode
	apply 0 /proc/cpufreq/cpufreq_cci_mode
	apply 0 /proc/cpufreq/cpufreq_power_mode

	# DDR Boost mode
	apply 0 /sys/devices/platform/boot_dramboost/dramboost/dramboost

	# EAS/HMP Switch
	apply 2 /sys/devices/system/cpu/eas/enable

	# Enable GED KPI
	apply 1 /sys/module/sspm_v3/holders/ged/parameters/is_GED_KPI_enabled

	# GPU Frequency
	write 0 /proc/gpufreq/gpufreq_opp_freq
	write -1 /proc/gpufreqv2/fix_target_opp_index

	# Reset min freq via GED
	if [ -d /proc/gpufreqv2 ]; then
		mid_oppfreq=$(mtk_gpufreq_minfreq_index /proc/gpufreqv2/gpu_working_opp_table)
	else
		min_oppfreq=$(mtk_gpufreq_minfreq_index /proc/gpufreq/gpufreq_opp_dump)
	fi

	apply $min_oppfreq /sys/kernel/ged/hal/custom_boost_gpu_freq

	# GPU Power limiter
	[ -f "/proc/gpufreq/gpufreq_power_limited" ] && {
		for setting in ignore_batt_oc ignore_batt_percent ignore_low_batt ignore_thermal_protect ignore_pbm_limited; do
			apply "$setting 0" /proc/gpufreq/gpufreq_power_limited
		done
	}

	# Enable battery current limiter
	apply "stop 0" /proc/mtk_batoc_throttling/battery_oc_protect_stop

	# DRAM Frequency
	write -1 /sys/devices/platform/10012000.dvfsrc/helio-dvfsrc/dvfsrc_req_ddr_opp
	write -1 /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
	devfreq_unlock /sys/class/devfreq/mtk-dvfsrc-devfreq

	# Eara Thermal
	apply 1 /sys/kernel/eara_thermal/enable
}

encore_snapdragon_normal() {
	# Qualcomm CPU Bus and DRAM frequencies
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*cpu*-lat \
			/sys/class/devfreq/*cpu*-bw \
			/sys/class/devfreq/*llccbw* \
			/sys/class/devfreq/*bus_llcc* \
			/sys/class/devfreq/*bus_ddr* \
			/sys/class/devfreq/*memlat* \
			/sys/class/devfreq/*cpubw* \
			/sys/class/devfreq/*kgsl-ddr-qos*; do

			devfreq_unlock "$path"
		done &

		for component in DDR LLCC L3; do
			qcom_cpudcvs_unlock /sys/devices/system/cpu/bus_dcvs/$component
		done
	}

	# Revert GPU tweak
	devfreq_unlock /sys/class/kgsl/kgsl-3d0/devfreq

	# Enable back GPU Bus split
	apply 1 /sys/class/kgsl/kgsl-3d0/bus_split

	# Free GPU clock on/off
	apply 0 /sys/class/kgsl/kgsl-3d0/force_clk_on
}


encore_exynos_normal() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"
	[ -d "$gpu_path" ] && {
		max_freq=$(which_maxfreq "$gpu_path/gpu_available_frequencies")
		min_freq=$(which_minfreq "$gpu_path/gpu_available_frequencies")
		write "$max_freq" "$gpu_path/gpu_max_clock"
		write "$min_freq" "$gpu_path/gpu_min_clock"
	}

	mali_sysfs=$(find /sys/devices/platform/ -iname "*.mali" -print -quit 2>/dev/null)
	apply coarse_demand "$mali_sysfs/power_policy"

	# DRAM frequency
	[ $DEVICE_MITIGATION -eq 0 ] && {
		for path in /sys/class/devfreq/*devfreq_mif*; do
			devfreq_unlock "$path"
		done &
	}
}

encore_unisoc_normal() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_unlock "$gpu_path"
}

# All Encore Powersave Script

encore_mediatek_powersave() {
	# MTK CPU Power mode to low power
	apply 1 /proc/cpufreq/cpufreq_power_mode

	# GPU Frequency
	if [ -d /proc/gpufreqv2 ]; then
		min_gpufreq_index=$(mtk_gpufreq_minfreq_index /proc/gpufreqv2/gpu_working_opp_table)
		apply "$min_gpufreq_index" /proc/gpufreqv2/fix_target_opp_index
	else
		gpu_freq=$(sed -n 's/.*freq = \([0-9]\{1,\}\).*/\1/p' /proc/gpufreq/gpufreq_opp_dump | tail -n 1)
		apply "$gpu_freq" /proc/gpufreq/gpufreq_opp_freq
	fi
}

encore_snapdragon_powersave() {
	# GPU Frequency
	devfreq_min_perf /sys/class/kgsl/kgsl-3d0/devfreq
}

encore_exynos_powersave() {
	# GPU Frequency
	gpu_path="/sys/kernel/gpu"
	[ -d "$gpu_path" ] && {
		freq=$(which_minfreq "$gpu_path/gpu_available_frequencies")
		apply "$freq" "$gpu_path/gpu_min_clock"
		apply "$freq" "$gpu_path/gpu_max_clock"
	}
}

encore_unisoc_powersave() {
	# GPU Frequency
	gpu_path=$(find /sys/class/devfreq/ -type d -iname "*.gpu" -print -quit 2>/dev/null)
	[ -n "$gpu_path" ] && devfreq_min_perf "$gpu_path"
}
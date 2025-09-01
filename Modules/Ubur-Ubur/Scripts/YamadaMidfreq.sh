#!/system/bin/sh
#
# Standalone script to set the minimum CPU frequency to the middle available frequency.
# It applies the setting via the PPM and cpufreq interfaces for maximum compatibility.
# This script should be run with root permissions.

# Function to apply a value to a system file and set permissions.
# It makes the file writable, echoes the value, and then makes it read-only.
apply() {
	# Check if the target file exists
	if [ ! -f "$2" ]; then
		echo "Error: File not found: $2"
		return 1
	fi

	# Temporarily change permissions to write the value
	chmod 644 "$2" >/dev/null 2>&1
	echo "$1" >"$2" 2>/dev/null

	# Set permissions back to read-only to prevent accidental changes
	chmod 444 "$2" >/dev/null 2>&1
}

# Function to find the middle frequency from a list of available frequencies.
# It reads the available frequencies, sorts them, and picks the one in the middle.
which_midfreq() {
	# Count the total number of available frequency steps
	total_opp=$(wc -w <"$1")

	# Calculate the middle position in the list
	mid_opp=$(((total_opp + 1) / 2))

	# Read frequencies, sort them numerically (highest first),
	# take the top half, and then select the last one from that half.
	tr ' ' '\n' <"$1" | grep -v '^[[:space:]]*$' | sort -nr | head -n $mid_opp | tail -n 1
}

# --- Main Script Logic ---

# Step 1: Apply settings via PPM interface if it exists (common on MediaTek)
if [ -d "/proc/ppm" ]; then
	echo "PPM interface detected. Setting minimum CPU frequencies via PPM..."

	# Initialize a counter for the CPU cluster/policy
	cluster=0

	# Loop through each CPU policy directory
	for path in /sys/devices/system/cpu/cpufreq/policy*; do
		# Ensure the directory and the scaling_available_frequencies file exist
		if [ -d "$path" ] && [ -f "$path/scaling_available_frequencies" ]; then
			mid_freq=$(which_midfreq "$path/scaling_available_frequencies")

			if [ -n "$mid_freq" ]; then
				# Apply the middle frequency to the PPM hard user limit
				apply "$cluster $mid_freq" "/proc/ppm/policy/hard_userlimit_min_cpu_freq"
				echo "  - PPM: Set min freq for cluster $cluster ($(basename "$path")) to: $mid_freq"
			else
				echo "  - PPM: Could not determine mid freq for cluster $cluster ($(basename "$path"))"
			fi
			# Increment the cluster counter for the next policy
			((cluster++))
		fi
	done
fi

# Step 2: Apply settings via the standard cpufreq interface for all cores
echo "Setting minimum CPU frequencies via standard cpufreq interface..."

# Loop through each CPU core's cpufreq directory
for path in /sys/devices/system/cpu/*/cpufreq; do
	# Ensure the directory and the scaling_available_frequencies file exist
	if [ -d "$path" ] && [ -f "$path/scaling_available_frequencies" ]; then
		mid_freq=$(which_midfreq "$path/scaling_available_frequencies")

		if [ -n "$mid_freq" ]; then
			# Apply the middle frequency as the new minimum frequency
			apply "$mid_freq" "$path/scaling_min_freq"
			echo "  - cpufreq: Set min freq for $(basename "$(dirname "$path")") to: $mid_freq"
		else
			echo "  - cpufreq: Could not determine mid freq for $(basename "$(dirname "$path")")"
		fi
	fi
done

echo "Script finished. Minimum CPU frequencies have been adjusted."
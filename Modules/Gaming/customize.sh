LATESTARTSERVICE=true
# Initialize SOC variable
SOC=0

soc_recognition_extra() {
	[ -d /sys/class/kgsl/kgsl-3d0/devfreq ] && {
		SOC=2
		ui_print "- Snapdragon"
		return 0
	}

	[ -d /sys/devices/platform/kgsl-2d0.0/kgsl ] && {
		SOC=2
		ui_print "- Snapdragon"
		return 0
	}

	[ -d /sys/kernel/ged/hal ] && {
		SOC=1
		ui_print "- MediaTek"
		return 0
	}

	[ -d /sys/kernel/tegra_gpu ] && {
		SOC=6
		ui_print "- Nvidia Tegra"
		return 0
	}

	return 1
}

get_soc_getprop() {
	local SOC_PROP="
ro.board.platform
ro.soc.model
ro.hardware
ro.chipname
ro.hardware.chipname
ro.vendor.soc.model.external_name
ro.vendor.qti.soc_name
ro.vendor.soc.model.part_name
ro.vendor.soc.model
"

	for prop in $SOC_PROP; do
		getprop "$prop"
	done
}

recognize_soc() {
	case "$1" in
	*mt* | *MT*) SOC=1 ;;
	*sm* | *qcom* | *SM* | *QCOM* | *Qualcomm*) SOC=2 ;;
	*exynos* | *Exynos* | *EXYNOS* | *universal* | *samsung* | *erd* | *s5e*) SOC=3 ;;
	*Unisoc* | *unisoc* | *ums*) SOC=4 ;;
	*gs* | *Tensor* | *tensor*) SOC=5 ;;
	*kirin*) SOC=7 ;;
	esac

	case "$SOC" in
	1) ui_print "- MediaTek" ;;
	2) ui_print "- Snapdragon" ;;
	3) ui_print "- Exynos" ;;
	4) ui_print "- Unisoc" ;;
	5) ui_print "- Google Tensor" ;;
	6) ui_print "- Nvidia Tegra" ;;
	7) ui_print "- Kirin" ;;
	0) return 1 ;;
	esac
}

ui_print "------------------------------------"
ui_print "             EnCorinVest            " 
ui_print "------------------------------------"
ui_print "         By: Kanagawa Yamada        "
ui_print "------------------------------------"
ui_print " "
sleep 1.5

ui_print "------------------------------------"
ui_print "      SNAPDRAGON | MEDIATEK         "
ui_print "          EXYNOS | UniSoc           "
ui_print "------------------------------------"
ui_print "DO NOT COMBINE WITH ANY PERF MODULE!"
ui_print "------------------------------------"
ui_print " "
sleep 1.5

ui_print "-----------------📱-----------------"
ui_print "            DEVICE INFO             "
ui_print "-----------------📱-----------------"
ui_print "DEVICE : $(getprop ro.build.product) "
ui_print "MODEL : $(getprop ro.product.model) "
ui_print "MANUFACTURE : $(getprop ro.product.system.manufacturer) "
ui_print "PROC : $(getprop ro.product.board) "
ui_print "CPU : $(getprop ro.hardware) "
ui_print "ANDROID VER : $(getprop ro.build.version.release) "
ui_print "KERNEL : $(uname -r) "
ui_print "RAM : $(free | grep Mem |  awk '{print $2}') "
ui_print " "
sleep 1.5

# =============================
# SOC Recognition and Configuration
# =============================
ui_print "------------------------------------"
ui_print "        RECOGNIZING CHIPSET         "
ui_print "------------------------------------"
# SOC CODE:
# 1 = MediaTek
# 2 = Qualcomm Snapdragon
# 3 = Exynos
# 4 = Unisoc
# 5 = Google Tensor
# 6 = Nvidia Tegra
# 7 = Kirin

# Recognize Chipset
soc_recognition_extra
[ $SOC -eq 0 ] && recognize_soc "$(get_soc_getprop)"
[ $SOC -eq 0 ] && recognize_soc "$(grep -E "Hardware|Processor" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')"
[ $SOC -eq 0 ] && recognize_soc "$(grep "model\sname" /proc/cpuinfo | uniq | cut -d ':' -f 2 | sed 's/^[ \t]*//')"
[ $SOC -eq 0 ] && {
	ui_print "! Unknown SoC, skipping some tweaks"
	ui_print "! If you think this is wrong, please report to maintainer"
}
ui_print " "
sleep 1.5

ui_print "------------------------------------"
ui_print "            MODULE INFO             "
ui_print "------------------------------------"
ui_print "Name : EnCorinVest"
ui_print "Version : 29.2"
ui_print "Variant: Gaming"
ui_print "Support Root : Magisk / KernelSU / APatch"
ui_print " "
sleep 1.5

ui_print "       INSTALLING EnCorinVest       "
ui_print " "
sleep 1.5

# Ensure encorin.txt exists and update it with the detected SOC
CONFIG_FILE="$MODPATH/encorin.txt"
ui_print "- Extracting configuration file..."
unzip -o "$ZIPFILE" 'encorin.txt' -d $MODPATH >&2
if [ -f "$CONFIG_FILE" ]; then
    ui_print "- Writing SOC Code ($SOC) to $CONFIG_FILE"
    sed -i "s/^SOC=.*/SOC=$SOC/" "$CONFIG_FILE"
else
    ui_print "! encorin.txt not found, cannot write SOC value."
fi
ui_print " "

# Check if game.txt exists in the new location, skip copy operations if it does
if [ -f "/data/EnCorinVest/game.txt" ]; then
    ui_print "- game.txt found, skipping file copy operations"
    ui_print " "
else
    ui_print "- game.txt not found, proceeding with file copy"
    # Create the target directory if it doesn't exist
    mkdir -p /data/EnCorinVest
    unzip -o "$ZIPFILE" 'Scripts/*' -d $MODPATH >&2
    # Copy game.txt to the new location
    cp -r "$MODPATH"/game.txt /data/EnCorinVest/ >/dev/null 2>&1
    cp -r "$MODPATH"/logo.png /data/local/tmp >/dev/null 2>&1
    cp -r "$MODPATH"/Anya.png /data/local/tmp >/dev/null 2>&1
fi

set_perm_recursive $MODPATH 0 0 0755 0755
set_perm_recursive $MODPATH/Scripts 0 0 0777 0755

sleep 1.5

ui_print " "
ui_print "     INSTALLING EnCorinVest APK       "
ui_print " "

# Check if EnCorinVest is already installed
if pm list packages | grep -q "com.kanagawa.yamada.encorinvest"; then
    pm uninstall --user 0 com.kanagawa.yamada.encorinvest >/dev/null 2>&1
fi

cp "$MODPATH"/EnCorinVest.apk /data/local/tmp >/dev/null 2>&1
pm install /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1
rm /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1

ui_print " "
ui_print "         INSTALLING HAMADA AI         "
ui_print " "

# Define paths and target binary name
BIN_PATH=$MODPATH/system/bin
TARGET_BIN_NAME=HamadaAI
TARGET_BIN_PATH=$BIN_PATH/$TARGET_BIN_NAME
TEMP_EXTRACT_DIR=$TMPDIR/hamada_extract # Use a temporary directory for extraction

# Create necessary directories
mkdir -p $BIN_PATH
mkdir -p $TEMP_EXTRACT_DIR

# Detect architecture
ARCH=$(getprop ro.product.cpu.abi)

# Determine which binary to extract based on architecture
if [[ "$ARCH" == *"arm64"* ]]; then
  # 64-bit architecture
  ui_print "- Detected 64-bit ARM architecture ($ARCH)"
  SOURCE_BIN_ZIP_PATH='HamadaAI/hamadaAI_arm64' # Path inside the zip file
  SOURCE_BIN_EXTRACTED_PATH=$TEMP_EXTRACT_DIR/HamadaAI/hamadaAI_arm64 # Path after extraction to temp dir
  ui_print "- Extracting $SOURCE_BIN_ZIP_PATH..."
  unzip -o "$ZIPFILE" "$SOURCE_BIN_ZIP_PATH" -d $TEMP_EXTRACT_DIR >&2
else
  # Assume 32-bit architecture (or non-arm64)
  ui_print "- Detected 32-bit ARM architecture or other ($ARCH)"
  SOURCE_BIN_ZIP_PATH='HamadaAI/hamadaAI_arm32' # Path inside the zip file
  SOURCE_BIN_EXTRACTED_PATH=$TEMP_EXTRACT_DIR/HamadaAI/hamadaAI_arm32 # Path after extraction to temp dir
  ui_print "- Extracting $SOURCE_BIN_ZIP_PATH..."
  unzip -o "$ZIPFILE" "$SOURCE_BIN_ZIP_PATH" -d $TEMP_EXTRACT_DIR >&2
fi

# Check if extraction was successful and the source file exists
if [ -f "$SOURCE_BIN_EXTRACTED_PATH" ]; then
  ui_print "- Moving and renaming binary to $TARGET_BIN_PATH"
  # Move the extracted binary to the final destination and rename it
  mv "$SOURCE_BIN_EXTRACTED_PATH" "$TARGET_BIN_PATH"

  # Check if the final binary exists
  if [ -f "$TARGET_BIN_PATH" ]; then
    ui_print "- Setting permissions for $TARGET_BIN_NAME"
    set_perm $TARGET_BIN_PATH 0 0 0755 0755
  else
    ui_print "! ERROR: Failed to move binary to $TARGET_BIN_PATH"
  fi
else
  ui_print "! ERROR: Failed to extract binary from $SOURCE_BIN_ZIP_PATH"
fi

# Clean up temporary extraction directory
rm -rf $TEMP_EXTRACT_DIR

ui_print " "
ui_print "There's A Wallpaper Souvenir In The Github    "
ui_print "Go Check it Out!                              "
ui_print " "

sleep 2
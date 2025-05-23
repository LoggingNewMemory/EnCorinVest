LATESTARTSERVICE=true

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

ui_print "------------------------------------"
ui_print "            MODULE INFO             "
ui_print "------------------------------------"
ui_print "Name : EnCorinVest"
ui_print "Version : 23.0"
ui_print "Variant: Lite-C"
ui_print "Support Root : Magisk / KernelSU / APatch"
ui_print " "
sleep 1.5

ui_print "       INSTALLING EnCorinVest       "
ui_print " "
sleep 1.5

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

ui_print "     INSTALLING EnCorinVest APK       "
ui_print " "

cp "$MODPATH"/EnCorinVest.apk /data/local/tmp >/dev/null 2>&1
pm install /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1
rm /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1

ui_print " "
ui_print "    INSTALLING HAMADA AI NEXT GEN     "
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

sleep 1.5

ui_print " "
case "$((RANDOM % 14 + 1))" in
1) ui_print "- Wooly's Fairy Tale [Rem01 Gaming]" ;;
2) ui_print "- Sheep-counting Lullaby [Rem01 Gaming]" ;;
3) ui_print "- Fog? The Black Shores! [Rem01 Gaming]" ;;
4) ui_print "- Adventure? Let's go! [Rem01 Gaming]" ;;
5) ui_print "- Hero Takes the Stage! [Rem01 Gaming]" ;;
6) ui_print "- Woolies Save the World! [Rem01 Gaming]" ;;
7) ui_print "- I Cast Testicular Torsion!!! [Nazephyrus]" ;;
8) ui_print "- We Are KLC! [Kanagawa Yamada]" ;;
9) ui_print "- Gacor Kang [Nazephyrus]" ;;
10) ui_print "- Don't look back with regret, look forward with hope [Kentarou]" ;;
11) ui_print "- Go Beyond - Plus Ultra! [Momin]" ;;
12) ui_print "- Cheeki Breeki IV Damke [Ody]" ;;
13) ui_print "- Hope You Hydrated Well ❤️ [Ody]" ;;
14) ui_print "- The List Is Not Even 20 Yet [Kanagawa Yamada]" ;;
esac
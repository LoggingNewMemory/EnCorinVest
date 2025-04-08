#!/bin/bash

# Define the source and target directories
SOURCE_DIR="Gaming"
TARGET_DIRS=("Core" "Phoenix" "Ubur-Ubur" "Gaming" "Lite" "Lite-P" "Lite-U" "Lite-C")
BUILD_DIR="Build"

# Create the Build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

welcome() {
    clear
    echo "---------------------------------"
    echo "      EnCorinVest Builder        "
    echo "      By: Kanagawa Yamada        "
    echo "---------------------------------"
    echo ""
}

success() {
    echo "---------------------------------"
    echo " EnCorinVest Builded Sucessfully "
    printf "     Ambatublow : %s seconds\n" "$SECONDS"
    echo "---------------------------------"
}

# Function to sync files
sync_files() {
    # Clear the Build directory
    rm -rf "$BUILD_DIR"/*

    # Ask for build type
    read -p "Choose build type (RELEASE or LAB): " BUILD_TYPE
    BUILD_TYPE=${BUILD_TYPE^^}  # Convert to uppercase
    while [[ "$BUILD_TYPE" != "RELEASE" && "$BUILD_TYPE" != "LAB" ]]; do
        echo "Invalid choice. Please choose either RELEASE or LAB."
        read -p "Choose build type (RELEASE or LAB): " BUILD_TYPE
        BUILD_TYPE=${BUILD_TYPE^^}  # Convert to uppercase
    done

    # Ask for version
    read -p "Enter Version (e.g., V 1.0): " VERSION

    # Copy Wallpaper.png to Build folder
    cp -f "Wallpaper.png" "$BUILD_DIR/Wallpaper.png"
    
    # Copy EnCorinVest.apk to Build folder
    cp -f "$SOURCE_DIR/EnCorinVest.apk" "$BUILD_DIR/EnCorinVest.apk"

    # Suppress most of the output, only show essential information
    for TARGET_DIR in "${TARGET_DIRS[@]}"; do
        # Create directory if it doesn't exist
        mkdir -p "$TARGET_DIR"
        
        # Sync Scripts folder
        rsync -a --delete "$SOURCE_DIR/Scripts/" "$TARGET_DIR/Scripts/" > /dev/null 2>&1

        # Sync customize.sh
        cp -f "$SOURCE_DIR/customize.sh" "$TARGET_DIR/customize.sh"
        
        # Sync service.sh with special handling for Lite variants
        cp -f "$SOURCE_DIR/service.sh" "$TARGET_DIR/service.sh"
        
        # For Lite variants, remove resetprop -n lines from service.sh
        if [[ "$TARGET_DIR" == "Lite"* ]]; then
            # Remove resetprop -n lines while preserving other content
            sed -i '/resetprop -n/d' "$TARGET_DIR/service.sh"
        fi

        # Sync system.prop for all variants
        cp -f "$SOURCE_DIR/system.prop" "$TARGET_DIR/system.prop"
        
        # Sync logo.png to all variants
        cp -f "$SOURCE_DIR/logo.png" "$TARGET_DIR/logo.png"

        # Replace the Variant and Version lines
        sed -i 's/^ui_print "Variant: .*$/ui_print "Variant: '"$(basename "$TARGET_DIR")"'"/' "$TARGET_DIR/customize.sh"
        sed -i 's/^ui_print "Version : .*$/ui_print "Version : '"$VERSION"'"/' "$TARGET_DIR/customize.sh"

        # Copy module.prop and update version with correct package name
        cp -f "$SOURCE_DIR/module.prop" "$TARGET_DIR/module.prop"
        TARGET_NAME=$(basename "$TARGET_DIR")
        sed -i "s/^version=.*$/version=$VERSION-$TARGET_NAME/" "$TARGET_DIR/module.prop"

        # Copy remaining files
        cp -f "$SOURCE_DIR/EnCorinVest.apk" "$TARGET_DIR/EnCorinVest.apk"

        # Create zip file without parent folder
        ZIP_NAME="EnCorinVest-$(basename "$TARGET_DIR")-$VERSION-$BUILD_TYPE.zip"
        (cd "$TARGET_DIR" && zip -q -r "../$BUILD_DIR/$ZIP_NAME" *)

        # Show only the zip creation confirmation
        echo "Created: $ZIP_NAME"
    done
}

# Run the sync function
welcome
sync_files
success

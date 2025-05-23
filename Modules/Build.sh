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
    echo " EnCorinVest Builded Successfully "
    printf "     Ambatublow : %s seconds\n" "$SECONDS"
    echo "---------------------------------"
}

# Function to sync files
sync_files() {
    # Clear the Build directory
    rm -rf "$BUILD_DIR"/*

    # Make sure source directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "Error: Source directory '$SOURCE_DIR' does not exist!"
        exit 1
    fi

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

    # Check if required files exist
    if [ ! -f "Wallpaper.png" ]; then
        echo "Error: Wallpaper.png not found in current directory!"
        exit 1
    fi

    if [ ! -f "$SOURCE_DIR/EnCorinVest.apk" ]; then
        echo "Error: EnCorinVest.apk not found in $SOURCE_DIR directory!"
        exit 1
    fi

    # Copy Wallpaper.png to Build folder
    cp -f "Wallpaper.png" "$BUILD_DIR/Wallpaper.png"

    # Copy EnCorinVest.apk to Build folder
    cp -f "$SOURCE_DIR/EnCorinVest.apk" "$BUILD_DIR/EnCorinVest.apk"

    # Process each target directory
    for TARGET_DIR in "${TARGET_DIRS[@]}"; do
        echo "Processing: $TARGET_DIR"

        # Create directory if it doesn't exist
        mkdir -p "$TARGET_DIR"

        # Copy game.txt to all output folders
        if [ -f "$SOURCE_DIR/game.txt" ]; then
            cp -f "$SOURCE_DIR/game.txt" "$TARGET_DIR/game.txt"
        else
            echo "Warning: game.txt not found in $SOURCE_DIR"
        fi

        # Sync Scripts folder
        if [ -d "$SOURCE_DIR/Scripts" ]; then
            mkdir -p "$TARGET_DIR/Scripts"
            rsync -a --delete "$SOURCE_DIR/Scripts/" "$TARGET_DIR/Scripts/" > /dev/null 2>&1
        else
            echo "Warning: Scripts directory not found in $SOURCE_DIR"
        fi

        # Sync HamadaAI folder
        if [ -d "$SOURCE_DIR/HamadaAI" ]; then
            mkdir -p "$TARGET_DIR/HamadaAI"
            rsync -a --delete "$SOURCE_DIR/HamadaAI/" "$TARGET_DIR/HamadaAI/" > /dev/null 2>&1
        else
            echo "Warning: HamadaAI directory not found in $SOURCE_DIR"
        fi

        # Sync AnyaMelfissa folder only if target already has it
        if [ -d "$SOURCE_DIR/AnyaMelfissa" ] && [ -d "$TARGET_DIR/AnyaMelfissa" ]; then
            rsync -a --delete "$SOURCE_DIR/AnyaMelfissa/" "$TARGET_DIR/AnyaMelfissa/" > /dev/null 2>&1
        fi

        # Sync KoboKanaeru folder only if target already has it
        if [ -d "$SOURCE_DIR/KoboKanaeru" ] && [ -d "$TARGET_DIR/KoboKanaeru" ]; then
            rsync -a --delete "$SOURCE_DIR/KoboKanaeru/" "$TARGET_DIR/KoboKanaeru/" > /dev/null 2>&1
        fi

        # Sync customize.sh
        if [ -f "$SOURCE_DIR/customize.sh" ]; then
            cp -f "$SOURCE_DIR/customize.sh" "$TARGET_DIR/customize.sh"

            # Replace the Variant line - using temp file instead of in-place editing
            TARGET_NAME=$(basename "$TARGET_DIR")
            sed "s/^ui_print \"Variant: .*\"/ui_print \"Variant: $TARGET_NAME\"/" "$TARGET_DIR/customize.sh" > "$TARGET_DIR/customize.sh.tmp"
            mv "$TARGET_DIR/customize.sh.tmp" "$TARGET_DIR/customize.sh"

            # Replace the Version line - using temp file instead of in-place editing
            sed "s/^ui_print \"Version : .*\"/ui_print \"Version : $VERSION\"/" "$TARGET_DIR/customize.sh" > "$TARGET_DIR/customize.sh.tmp"
            mv "$TARGET_DIR/customize.sh.tmp" "$TARGET_DIR/customize.sh"
        else
            echo "Error: customize.sh not found in $SOURCE_DIR!"
            exit 1
        fi

        # Sync service.sh
        if [ -f "$SOURCE_DIR/service.sh" ]; then
            cp -f "$SOURCE_DIR/service.sh" "$TARGET_DIR/service.sh"

            # For Lite variants, remove resetprop -n lines from service.sh
            if [[ "$TARGET_DIR" == Lite* ]]; then
                grep -v "setprop" "$TARGET_DIR/service.sh" > "$TARGET_DIR/service.sh.tmp"
                mv "$TARGET_DIR/service.sh.tmp" "$TARGET_DIR/service.sh"
            fi
        else
            echo "Error: service.sh not found in $SOURCE_DIR!"
            exit 1
        fi

        # Sync logo.png
        if [ -f "$SOURCE_DIR/logo.png" ]; then
            cp -f "$SOURCE_DIR/logo.png" "$TARGET_DIR/logo.png"
        else
            echo "Warning: logo.png not found in $SOURCE_DIR"
        fi

        # Copy module.prop and update version
        if [ -f "$SOURCE_DIR/module.prop" ]; then
            cp -f "$SOURCE_DIR/module.prop" "$TARGET_DIR/module.prop"

            # Update version in module.prop - using temp file instead of in-place editing
            TARGET_NAME=$(basename "$TARGET_DIR")
            sed "s/^version=.*$/version=$VERSION-$TARGET_NAME/" "$TARGET_DIR/module.prop" > "$TARGET_DIR/module.prop.tmp"
            mv "$TARGET_DIR/module.prop.tmp" "$TARGET_DIR/module.prop"
        else
            echo "Error: module.prop not found in $SOURCE_DIR!"
            exit 1
        fi

        # Copy EnCorinVest.apk
        cp -f "$SOURCE_DIR/EnCorinVest.apk" "$TARGET_DIR/EnCorinVest.apk"

        # Add special files for Lite-P variant
        if [[ "$TARGET_DIR" == "Lite-P" ]]; then
            cp -f "$SOURCE_DIR/encorin.txt" "$TARGET_DIR/encorin.txt"
            cp -f "$SOURCE_DIR/Anya.png" "$TARGET_DIR/Anya.png"
        fi

        # Create zip file without parent folder
        ZIP_NAME="EnCorinVest-$(basename "$TARGET_DIR")-$VERSION-$BUILD_TYPE.zip"
        (cd "$TARGET_DIR" && zip -q -r "../$BUILD_DIR/$ZIP_NAME" *)

        # Show only the zip creation confirmation
        echo "Created: $ZIP_NAME"
    done
}

# Run the sync function
welcome
SECONDS=0  # Start timing
sync_files
success

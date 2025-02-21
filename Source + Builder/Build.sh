#!/bin/bash

# Define the source and target directories
SOURCE_DIR="Gaming"
TARGET_DIRS=("Core" "Phoenix" "Ubur-Ubur" "Gaming")
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

    # Suppress most of the output, only show essential information
    for TARGET_DIR in "${TARGET_DIRS[@]}"; do
        # Sync Scripts folder
        rsync -a --delete "$SOURCE_DIR/Scripts/" "$TARGET_DIR/Scripts/" > /dev/null 2>&1

        # Sync customize.sh
        cp -f "$SOURCE_DIR/customize.sh" "$TARGET_DIR/customize.sh"

        # Replace the Variant and Version lines
        sed -i 's/^ui_print "Variant: .*$/ui_print "Variant: '"$(basename "$TARGET_DIR")"'"/' "$TARGET_DIR/customize.sh"
        sed -i 's/^ui_print "Version : .*$/ui_print "Version : '"$VERSION"'"/' "$TARGET_DIR/customize.sh"

        # Copy module.prop and update version with correct package name
        cp -f "$SOURCE_DIR/module.prop" "$TARGET_DIR/module.prop"
        TARGET_NAME=$(basename "$TARGET_DIR")
        sed -i "s/^version=.*$/version=$VERSION-$TARGET_NAME/" "$TARGET_DIR/module.prop"

        # Copy remaining files
        cp -f "$SOURCE_DIR/EnCorinVest.apk" "$TARGET_DIR/EnCorinVest.apk"
        # Copy EnCorinVest.apk to Build folder
        cp -f "$SOURCE_DIR/EnCorinVest.apk" "$BUILD_DIR/EnCorinVest.apk"

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

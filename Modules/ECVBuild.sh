#!/bin/bash

# Define the source and target directories
SOURCE_DIR="Gaming"
TARGET_DIRS=("Core" "Phoenix" "Ubur-Ubur" "Gaming")
BUILD_DIR="Build"

# Check if megumi.sh exists and load configuration
TELEGRAM_ENABLED=false
if [ -f "megumi.sh" ]; then
    source megumi.sh
    TELEGRAM_ENABLED=true
fi

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

# Function to send file to Telegram
send_to_telegram() {
    local file_path="$1"
    local caption="$2"
    local chat_id="$3"

    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        echo "Error: TELEGRAM_BOT_TOKEN is not set in megumi.sh!"
        return 1
    fi

    if [ -z "$chat_id" ]; then
        echo "Error: Chat ID is empty!"
        return 1
    fi

    echo "Uploading $(basename "$file_path") to chat ID: $chat_id..."

    # Send document to Telegram
    response=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendDocument" \
        -F "chat_id=$chat_id" \
        -F "document=@$file_path" \
        -F "caption=$caption")

    # Check if upload was successful
    if echo "$response" | grep -q '"ok":true'; then
        echo "✓ Successfully uploaded $(basename "$file_path") to $chat_id"
        return 0
    else
        echo "✗ Failed to upload $(basename "$file_path") to $chat_id"
        echo "Response: $response"
        return 1
    fi
}

# Function to send message to Telegram
send_message_to_telegram() {
    local message="$1"
    local chat_id="$2"

    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$chat_id" ]; then
        return 1
    fi

    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$message" \
        -d "parse_mode=Markdown" > /dev/null
}

# Function to display available groups and get selection
select_telegram_groups() {
    local available_groups=()
    local group_names=()
    
    # Parse TELEGRAM_GROUPS array
    if [ ${#TELEGRAM_GROUPS[@]} -eq 0 ]; then
        echo "No Telegram groups configured in megumi.sh"
        return 1
    fi
    
    echo ""
    echo "Available Telegram groups:"
    echo "--------------------------"
    
    local index=1
    for group in "${TELEGRAM_GROUPS[@]}"; do
        # Parse group entry: "GROUP_NAME:CHAT_ID"
        local group_name=$(echo "$group" | cut -d':' -f1)
        local chat_id=$(echo "$group" | cut -d':' -f2)
        
        available_groups+=("$chat_id")
        group_names+=("$group_name")
        
        echo "$index. $group_name ($chat_id)"
        ((index++))
    done
    
    echo "a. All groups"
    echo "0. Cancel"
    echo ""
    
    while true; do
        read -p "Select groups (comma-separated numbers, 'a' for all, or '0' to cancel): " selection
        selection=${selection,,}  # Convert to lowercase
        
        if [[ "$selection" == "0" ]]; then
            return 1
        elif [[ "$selection" == "a" || "$selection" == "all" ]]; then
            SELECTED_GROUPS=("${available_groups[@]}")
            SELECTED_GROUP_NAMES=("${group_names[@]}")
            return 0
        else
            # Parse comma-separated selections
            SELECTED_GROUPS=()
            SELECTED_GROUP_NAMES=()
            IFS=',' read -ra SELECTIONS <<< "$selection"
            
            local valid=true
            for sel in "${SELECTIONS[@]}"; do
                sel=$(echo "$sel" | tr -d '[:space:]')  # Remove whitespace
                if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#available_groups[@]} ]; then
                    local idx=$((sel-1))
                    SELECTED_GROUPS+=("${available_groups[$idx]}")
                    SELECTED_GROUP_NAMES+=("${group_names[$idx]}")
                else
                    echo "Invalid selection: $sel"
                    valid=false
                    break
                fi
            done
            
            if [ "$valid" = true ] && [ ${#SELECTED_GROUPS[@]} -gt 0 ]; then
                return 0
            fi
        fi
        
        echo "Please enter valid selections."
    done
}

# Function to select variants for upload
select_variants() {
    local available_variants=()
    
    # Find all zip files in Build directory
    for zip_file in "$BUILD_DIR"/*.zip; do
        if [ -f "$zip_file" ]; then
            local filename=$(basename "$zip_file")
            local variant=$(echo "$filename" | sed 's/EnCorinVest-\(.*\)-.*-.*.zip/\1/')
            available_variants+=("$variant")
        fi
    done
    
    if [ ${#available_variants[@]} -eq 0 ]; then
        echo "No variants found in Build directory!"
        return 1
    fi
    
    echo ""
    echo "Available variants:"
    echo "-------------------"
    
    local index=1
    for variant in "${available_variants[@]}"; do
        echo "$index. $variant"
        ((index++))
    done
    
    echo "a. All variants"
    echo "0. Cancel"
    echo ""
    
    while true; do
        read -p "Select variants to upload (comma-separated numbers, 'a' for all, or '0' to cancel): " selection
        selection=${selection,,}  # Convert to lowercase
        
        if [[ "$selection" == "0" ]]; then
            return 1
        elif [[ "$selection" == "a" || "$selection" == "all" ]]; then
            SELECTED_VARIANTS=("${available_variants[@]}")
            return 0
        else
            # Parse comma-separated selections
            SELECTED_VARIANTS=()
            IFS=',' read -ra SELECTIONS <<< "$selection"
            
            local valid=true
            for sel in "${SELECTIONS[@]}"; do
                sel=$(echo "$sel" | tr -d '[:space:]')  # Remove whitespace
                if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#available_variants[@]} ]; then
                    local idx=$((sel-1))
                    SELECTED_VARIANTS+=("${available_variants[$idx]}")
                else
                    echo "Invalid selection: $sel"
                    valid=false
                    break
                fi
            done
            
            if [ "$valid" = true ] && [ ${#SELECTED_VARIANTS[@]} -gt 0 ]; then
                return 0
            fi
        fi
        
        echo "Please enter valid selections."
    done
}

# Function to prompt for changelog
prompt_changelog() {
    echo ""
    read -p "Give changelog? (Y/N): " ADD_CHANGELOG
    ADD_CHANGELOG=${ADD_CHANGELOG,,}  # Convert to lowercase

    if [[ "$ADD_CHANGELOG" == "y" || "$ADD_CHANGELOG" == "yes" ]]; then
        echo ""
        echo "Enter changelog (press Ctrl+D or type 'END' on a new line when finished):"
        echo "---"

        CHANGELOG=""
        while IFS= read -r line; do
            if [[ "$line" == "END" ]]; then
                break
            fi
            if [ -n "$CHANGELOG" ]; then
                CHANGELOG+=$'\n'
            fi
            CHANGELOG+="$line"
        done

        if [ -n "$CHANGELOG" ]; then
            echo "---"
            echo "Changelog captured successfully!"
            return 0
        else
            echo "No changelog entered."
            return 1
        fi
    else
        return 1
    fi
}

# Function to prompt for Telegram posting
prompt_telegram_post() {
    echo ""
    read -p "Post to Telegram groups? (y/N): " POST_TO_TELEGRAM
    POST_TO_TELEGRAM=${POST_TO_TELEGRAM,,}  # Convert to lowercase
    
    if [[ "$POST_TO_TELEGRAM" == "y" || "$POST_TO_TELEGRAM" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to upload builds to Telegram
upload_to_telegram() {
    local version="$1"
    local build_type="$2"
    
    if prompt_telegram_post; then
        # Select variants to upload
        if ! select_variants; then
            echo "Variant selection cancelled."
            return 1
        fi
        
        echo ""
        echo "Selected variants: ${SELECTED_VARIANTS[*]}"
        
        # Prompt for changelog
        HAS_CHANGELOG=false
        if prompt_changelog; then
            HAS_CHANGELOG=true
        fi
        
        if select_telegram_groups; then
            echo ""
            echo "Uploading to selected Telegram groups..."
            
            # Create a summary message
            SUMMARY_MESSAGE="🚀 *EnCorinVest Build Complete*%0A%0A"
            SUMMARY_MESSAGE+="📦 *Project:* EnCorinVest%0A"
            SUMMARY_MESSAGE+="🏷️ *Version:* $version%0A"
            SUMMARY_MESSAGE+="🔧 *Build Type:* $build_type%0A"
            SUMMARY_MESSAGE+="📄 *Variants:* ${#SELECTED_VARIANTS[@]} variants selected%0A"
            SUMMARY_MESSAGE+="📋 *Selected:* $(IFS=', '; echo "${SELECTED_VARIANTS[*]}")%0A"
            
            # Add changelog if provided
            if [ "$HAS_CHANGELOG" = true ] && [ -n "$CHANGELOG" ]; then
                # URL encode the changelog for Telegram
                ENCODED_CHANGELOG=$(echo "$CHANGELOG" | sed 's/%/%25/g; s/ /%20/g; s/!/%21/g; s/"/%22/g; s/#/%23/g; s/\$/%24/g; s/&/%26/g; s/'\''/%27/g; s/(/%28/g; s/)/%29/g; s/\*/%2A/g; s/+/%2B/g; s/,/%2C/g; s/-/%2D/g; s/\./%2E/g; s/\//%2F/g; s/:/%3A/g; s/;/%3B/g; s/</%3C/g; s/=/%3D/g; s/>/%3E/g; s/?/%3F/g; s/@/%40/g; s/\[/%5B/g; s/\\/%5C/g; s/\]/%5D/g; s/\^/%5E/g; s/_/%5F/g; s/`/%60/g; s/{/%7B/g; s/|/%7C/g; s/}/%7D/g; s/~/%7E/g')
                # Replace newlines with %0A for Telegram
                ENCODED_CHANGELOG=$(echo "$ENCODED_CHANGELOG" | tr '\n' ' ' | sed 's/ /%0A/g')
                SUMMARY_MESSAGE+=%0A%0A"📝 *Changelog:*%0A$ENCODED_CHANGELOG"
            fi
            
            SUMMARY_MESSAGE+=%0A%0A"Files uploading below... ⬇️"
            
            # Loop through selected groups
            for i in "${!SELECTED_GROUPS[@]}"; do
                local chat_id="${SELECTED_GROUPS[$i]}"
                local group_name="${SELECTED_GROUP_NAMES[$i]}"
                
                echo ""
                echo "📤 Posting to: $group_name"
                
                # Send summary message first
                send_message_to_telegram "$SUMMARY_MESSAGE" "$chat_id"
                
                local upload_success=0
                local upload_total=0
                
                # Upload only selected variants
                for variant in "${SELECTED_VARIANTS[@]}"; do
                    # Find the corresponding zip file
                    for zip_file in "$BUILD_DIR"/*.zip; do
                        if [ -f "$zip_file" ]; then
                            local filename=$(basename "$zip_file")
                            local file_variant=$(echo "$filename" | sed 's/EnCorinVest-\(.*\)-.*-.*.zip/\1/')
                            
                            if [[ "$file_variant" == "$variant" ]]; then
                                ((upload_total++))
                                caption="📱 EnCorinVest - $variant - $version ($build_type)"
                                
                                if send_to_telegram "$zip_file" "$caption" "$chat_id"; then
                                    ((upload_success++))
                                fi
                                break
                            fi
                        fi
                    done
                done
                
                # Send completion message
                if [ $upload_success -eq $upload_total ]; then
                    COMPLETION_MESSAGE="✅ *Upload Complete!*%0A%0AAll $upload_total selected variants uploaded successfully to $group_name."
                    send_message_to_telegram "$COMPLETION_MESSAGE" "$chat_id"
                else
                    COMPLETION_MESSAGE="⚠️ *Upload Partially Complete*%0A%0A$upload_success/$upload_total selected variants uploaded to $group_name."
                    send_message_to_telegram "$COMPLETION_MESSAGE" "$chat_id"
                fi
                
                echo "📊 Upload to $group_name: $upload_success/$upload_total files"
            done
            
            echo ""
            echo "📊 Overall Upload Summary Complete"
            
        else
            echo "Telegram upload cancelled."
        fi
    else
        echo "Skipping Telegram upload."
    fi
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

         # Copy encorin.txt to all output folders
        if [ -f "$SOURCE_DIR/encorin.txt" ]; then
            cp -f "$SOURCE_DIR/encorin.txt" "$TARGET_DIR/encorin.txt"
        else
            echo "Warning: encorin.txt not found in $SOURCE_DIR"
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
        else
            echo "Error: service.sh not found in $SOURCE_DIR!"
            exit 1
        fi

        # Sync system.prop
        if [ -f "$SOURCE_DIR/system.prop" ]; then
            cp -f "$SOURCE_DIR/system.prop" "$TARGET_DIR/system.prop"
        else
            echo "Error: system.prop not found in $SOURCE_DIR!"
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

        # Create zip file without parent folder
        ZIP_NAME="EnCorinVest-$(basename "$TARGET_DIR")-$VERSION-$BUILD_TYPE.zip"
        (cd "$TARGET_DIR" && zip -q -r "../$BUILD_DIR/$ZIP_NAME" *)

        # Show only the zip creation confirmation
        echo "Created: $ZIP_NAME"
    done

    # Check if Telegram is enabled and offer upload
    if [ "$TELEGRAM_ENABLED" = true ]; then
        upload_to_telegram "$VERSION" "$BUILD_TYPE"
    else
        echo ""
        echo "Post to telegram disabled, please setup megumi.sh and configure TELEGRAM_GROUPS array"
    fi
}

# Run the sync function
welcome
SECONDS=0  # Start timing
sync_files
success

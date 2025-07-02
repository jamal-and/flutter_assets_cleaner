#!/bin/bash

echo "🧼 Flutter Assets Cleanup Tool"
echo "=============================="
echo ""

# Configuration
PROJECT_DIR="lib"
ASSET_DIR="./assets"
CODE_DIR="./lib"
YAML_FILES=$(find . -maxdepth 1 -name "*.yaml")

# Function to automatically detect Assets file
detect_assets_file() {
    echo "🔍 Auto-detecting Assets class file..."
    
    local potential_files=()
    
    # Search for files containing "class Assets" or similar patterns
    while IFS= read -r -d '' file; do
        if grep -l "class.*Assets\|abstract.*class.*Assets\|final.*class.*Assets" "$file" > /dev/null 2>&1; then
            # Additional check for static const String declarations
            if grep -l "static.*const.*String" "$file" > /dev/null 2>&1; then
                potential_files+=("$file")
            fi
        fi
    done < <(find "$PROJECT_DIR" -name "*.dart" -print0 2>/dev/null)
    
    # Also search by common filenames
    local common_names=("assets.dart" "app_assets.dart" "asset_paths.dart" "constants.dart" "resources.dart")
    for name in "${common_names[@]}"; do
        while IFS= read -r -d '' file; do
            if grep -l "static.*const.*String" "$file" > /dev/null 2>&1; then
                # Check if not already in potential_files
                local already_exists=false
                for existing in "${potential_files[@]}"; do
                    if [[ "$existing" == "$file" ]]; then
                        already_exists=true
                        break
                    fi
                done
                if [[ "$already_exists" == false ]]; then
                    potential_files+=("$file")
                fi
            fi
        done < <(find "$PROJECT_DIR" -name "$name" -print0 2>/dev/null)
    done
    
    # If no files found, return empty
    if [[ ${#potential_files[@]} -eq 0 ]]; then
        echo "⚠️  No Assets class file detected automatically"
        return 1
    fi
    
    # If only one file found, use it
    if [[ ${#potential_files[@]} -eq 1 ]]; then
        ASSETS_FILE="${potential_files[0]}"
        echo "✅ Auto-detected Assets file: $ASSETS_FILE"
        return 0
    fi
    
    # If multiple files found, let user choose
    echo ""
    echo "🔍 Multiple potential Assets files detected:"
    for i in "${!potential_files[@]}"; do
        echo "  $((i+1)). ${potential_files[i]}"
        # Show a preview of the file content
        local const_count=$(grep -c "static.*const.*String" "${potential_files[i]}" 2>/dev/null || echo "0")
        echo "     └─ Contains $const_count static const String declarations"
    done
    
    echo ""
    read -p "📝 Enter the number (1-${#potential_files[@]}) or 's' to skip constants cleanup: " choice
    
    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
        echo "⏭️  Skipping constants cleanup"
        return 1
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#potential_files[@]} ]; then
        ASSETS_FILE="${potential_files[$((choice-1))]}"
        echo "✅ Selected Assets file: $ASSETS_FILE"
        return 0
    else
        echo "❌ Invalid selection. Skipping constants cleanup."
        return 1
    fi
}

# Function to clean unused static const variables
cleanup_unused_constants() {
    echo "🔍 STEP 1: Scanning for unused static consts..."
    
    # Auto-detect Assets file
    if ! detect_assets_file; then
        echo "⏭️  Skipping constants cleanup"
        return
    fi
    
    if [ ! -f "$ASSETS_FILE" ]; then
        echo "⚠️  Assets file not found at $ASSETS_FILE - skipping constant cleanup"
        return
    fi
    
    echo "📁 Using Assets file: $ASSETS_FILE"

    unused_assets=()

    while read -r line; do
        if [[ $line =~ static\ const\ String\ ([a-zA-Z0-9_]+)\ *= ]]; then
            var_name="${BASH_REMATCH[1]}"
            usage_count=$(grep -r -o "\b$var_name\b" $PROJECT_DIR | wc -l)

            if [[ $usage_count -le 1 ]]; then
                # Only found in the definition file
                unused_assets+=("$var_name")
            fi
        fi
    done < "$ASSETS_FILE"

    if [[ ${#unused_assets[@]} -eq 0 ]]; then
        echo "✅ All asset constants are used."
        return
    fi

    echo ""
    echo "🚨 Unused static const variables found:"
    for asset in "${unused_assets[@]}"; do
        echo " - $asset"
    done

    echo ""
    read -p "❓ Do you want to delete these unused constants? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create backup
        # backup_file="${ASSETS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        # cp "$ASSETS_FILE" "$backup_file"
        # echo "📦 Backup created: $backup_file"
        
        # Create a temporary file for the cleaned content
        temp_file=$(mktemp)
        
        # Process the file and remove lines with unused variables
        in_unused_declaration=false
        current_unused_var=""
        
        while IFS= read -r line; do
            skip_line=false
            
            # Check if this line starts a new static const declaration
            if [[ $line =~ static\ const\ String\ ([a-zA-Z0-9_]+)\ *= ]]; then
                var_name="${BASH_REMATCH[1]}"
                in_unused_declaration=false
                current_unused_var=""
                
                # Check if this variable is in our unused list
                for unused in "${unused_assets[@]}"; do
                    if [[ "$var_name" == "$unused" ]]; then
                        echo "🗑️  Deleting declaration: $var_name"
                        in_unused_declaration=true
                        current_unused_var="$var_name"
                        skip_line=true
                        break
                    fi
                done
            elif [[ $in_unused_declaration == true ]]; then
                # We're in the middle of an unused variable declaration
                # Skip this line and check if it ends the declaration
                skip_line=true
                
                # Check if this line ends with a semicolon (end of declaration)
                if [[ $line =~ \;[[:space:]]*$ ]]; then
                    echo "🗑️  End of declaration for: $current_unused_var"
                    in_unused_declaration=false
                    current_unused_var=""
                fi
            fi
            
            # Write line to temp file if not skipping
            if [[ $skip_line == false ]]; then
                echo "$line" >> "$temp_file"
            fi
        done < "$ASSETS_FILE"
        
        # Replace original file with cleaned content
        mv "$temp_file" "$ASSETS_FILE"
        
        echo "🗑️  Deleted ${#unused_assets[@]} unused constant(s) from $ASSETS_FILE"
        echo "✅ Constants cleanup completed successfully!"
        
        echo ""
        echo "📋 Summary of deleted constants:"
        for asset in "${unused_assets[@]}"; do
            echo " - $asset"
        done
        
    else
        echo "❌ Constants deletion cancelled. No changes made."
    fi
}

# Function to auto-detect assets directory

# Function to clean unused asset files
cleanup_unused_files() {
    echo ""
    echo "🔍 STEP 2: Scanning for unused asset files..."
    
    # # Auto-detect assets directory
    # if ! detect_assets_directory; then
    #     echo "⏭️  Skipping file cleanup"
    #     return
    # fi
    
    if [ ! -d "$ASSET_DIR" ]; then
        echo "⚠️  Assets directory not found at $ASSET_DIR - skipping file cleanup"
        return
    fi
    
    echo "📁 Using assets directory: $ASSET_DIR"

    asset_files=$(find "$ASSET_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.json" -o -iname "*.jpeg" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.ttf" -o -iname "*.otf" \))

    if [ -z "$asset_files" ]; then
        echo "⚠️  No asset files found in $ASSET_DIR"
        return
    fi

    unused_files=()

    echo "🔎 Searching Dart and YAML files for asset file references..."
    for file in $asset_files; do
        filename=$(basename "$file")

        # Look inside lib/ and *.yaml at root
        if ! grep -r "$filename" "$CODE_DIR" > /dev/null && ! grep -q "$filename" $YAML_FILES; then
            unused_files+=("$file")
        fi
    done

    if [ ${#unused_files[@]} -eq 0 ]; then
        echo "✅ No unused asset files found!"
        return
    fi

    echo ""
    echo "🚫 Unused asset files detected:"
    for asset in "${unused_files[@]}"; do
        echo " - $asset"
    done

    echo ""
    read -p "🗑️  Do you want to delete these unused files? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        for asset in "${unused_files[@]}"; do
            rm "$asset"
            echo "🗑️  Deleted $asset"
        done
        echo "✅ File cleanup complete!"
        
        echo ""
        echo "📋 Summary of deleted files:"
        for asset in "${unused_files[@]}"; do
            echo " - $(basename "$asset")"
        done
    else
        echo "❌ No files were deleted."
    fi
}

# Main execution
main() {
    echo "This script will:"
    echo "1. 🔍 Find and optionally remove unused static const variables from your Assets class"
    echo "2. 🔍 Find and optionally remove unused asset files from your assets directory"
    echo ""
    
    read -p "🚀 Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled."
        exit 0
    fi
    
    echo ""
    
    # Run both cleanup functions
    cleanup_unused_constants
    cleanup_unused_files
    
    echo ""
    echo "🎉 Flutter Assets Cleanup completed!"
    echo "=================================="
}

# Run the main function
main
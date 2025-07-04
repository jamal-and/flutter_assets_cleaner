#!/bin/bash

# Flutter Assets Cleanup Tool
# Version: 1.0.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="lib"
ASSET_DIR="./assets"
CODE_DIR="./lib"
YAML_FILES=$(find . -maxdepth 1 -name "*.yaml" 2>/dev/null)

# Global variables
SKIP_CONSTANTS=false
SKIP_FILES=false
AUTO_CONFIRM=false
VERBOSE=false

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🧼 Flutter Assets Cleanup Tool v1.0.0                     ║"
    echo "║                                                                              ║"
    echo "║  🔍 Smart detection of unused assets and constants                           ║"
    echo "║  🛡️  Safe cleanup with interactive confirmations                              ║"
    echo "║  ⚡ Boost your Flutter app performance & reduce bundle size                  ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${PURPLE}[VERBOSE]${NC} $1"
    fi
}

# Function to automatically detect Assets file
detect_assets_file() {
    log_verbose "Auto-detecting Assets class file..."
    
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
        log_warning "No Assets class file detected automatically"
        return 1
    fi
    
    # If only one file found, use it
    if [[ ${#potential_files[@]} -eq 1 ]]; then
        ASSETS_FILE="${potential_files[0]}"
        log_success "Auto-detected Assets file: $ASSETS_FILE"
        return 0
    fi
    
    # If multiple files found, let user choose (unless auto-confirm is enabled)
    if [ "$AUTO_CONFIRM" = true ]; then
        ASSETS_FILE="${potential_files[0]}"
        log_success "Auto-selected first Assets file: $ASSETS_FILE"
        return 0
    fi
    
    echo ""
    log_info "Multiple potential Assets files detected:"
    for i in "${!potential_files[@]}"; do
        echo -e "  ${YELLOW}$((i+1)).${NC} ${potential_files[i]}"
        # Show a preview of the file content
        local const_count=$(grep -c "static.*const.*String" "${potential_files[i]}" 2>/dev/null || echo "0")
        echo -e "     ${CYAN}└─${NC} Contains ${GREEN}$const_count${NC} static const String declarations"
    done
    
    echo ""
    clear_input_buffer 
    read -p "📝 Enter the number (1-${#potential_files[@]}) or 's' to skip constants cleanup: " choice
    
    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
        #log_info "Skipping constants cleanup"
        return 1
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#potential_files[@]} ]; then
        ASSETS_FILE="${potential_files[$((choice-1))]}"
        log_success "Selected Assets file: $ASSETS_FILE"
        return 0
    else
        log_error "Invalid selection. Skipping constants cleanup."
        return 1
    fi
}

# Function to clean unused static const variables
cleanup_unused_constants() {
    if [ "$SKIP_CONSTANTS" = true ]; then
        log_info "Skipping constants cleanup (--skip-constants flag)"
        return
    fi
    
    log_info "STEP 1: Scanning for unused static consts..."
    
    # Auto-detect Assets file
    if ! detect_assets_file; then
        log_info "Skipping constants cleanup"
        return
    fi
    
    if [ ! -f "$ASSETS_FILE" ]; then
        log_warning "Assets file not found at $ASSETS_FILE - skipping constant cleanup"
        return
    fi
    
    log_info "Using Assets file: $ASSETS_FILE"

    unused_assets=()

    while read -r line; do
        if [[ $line =~ static\ const\ String\ ([a-zA-Z0-9_]+)\ *= ]]; then
            var_name="${BASH_REMATCH[1]}"
            usage_count=$(grep -r -o "\b$var_name\b" $PROJECT_DIR | wc -l)

            if [[ $usage_count -le 1 ]]; then
                # Only found in the definition file
                unused_assets+=("$var_name")
                log_verbose "Found unused constant: $var_name"
            fi
        fi
    done < "$ASSETS_FILE"

    if [[ ${#unused_assets[@]} -eq 0 ]]; then
        log_success "All asset constants are used."
        return
    fi

    echo ""
    log_warning "Unused static const variables found:"
    for asset in "${unused_assets[@]}"; do
        echo -e " ${RED}•${NC} $asset"
    done

    echo ""
    local confirm_delete=false
    if [ "$AUTO_CONFIRM" = true ]; then
        confirm_delete=true
        log_info "Auto-confirming deletion of unused constants (--auto-confirm flag)"
    else
        clear_input_buffer 
        read -p "❓ Do you want to delete these unused constants? (y/N): " -n 1 -r
        
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            confirm_delete=true
        fi
    fi

    if [ "$confirm_delete" = true ]; then
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
                        log_verbose "Deleting declaration: $var_name"
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
                    log_verbose "End of declaration for: $current_unused_var"
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
        
        log_success "Deleted ${#unused_assets[@]} unused constant(s) from $ASSETS_FILE"
        
        echo ""
        log_info "📋 Summary of deleted constants:"
        for asset in "${unused_assets[@]}"; do
            echo -e " ${GREEN}✓${NC} $asset"
        done
        
    else
        log_info "Constants deletion cancelled. No changes made."
    fi
}

# Function to clean unused asset files
cleanup_unused_files() {
    if [ "$SKIP_FILES" = true ]; then
        log_info "Skipping file cleanup (--skip-files flag)"
        return
    fi
    
    echo ""
    log_info "STEP 2: Scanning for unused asset files..."
    
    if [ ! -d "$ASSET_DIR" ]; then
        log_warning "Assets directory not found at $ASSET_DIR - skipping file cleanup"
        return
    fi
    
    log_info "Using assets directory: $ASSET_DIR"

    asset_files=$(find "$ASSET_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.json" -o -iname "*.jpeg" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.ttf" -o -iname "*.otf" \))

    if [ -z "$asset_files" ]; then
        log_warning "No asset files found in $ASSET_DIR"
        return
    fi

    unused_files=()

    log_verbose "Searching Dart and YAML files for asset file references..."
    for file in $asset_files; do
        filename=$(basename "$file")
        log_verbose "Checking: $filename"

        # Look inside lib/ and *.yaml at root
        if ! grep -r "$filename" "$CODE_DIR" > /dev/null && ! grep -q "$filename" $YAML_FILES 2>/dev/null; then
            unused_files+=("$file")
            log_verbose "Found unused file: $filename"
        fi
    done

    if [ ${#unused_files[@]} -eq 0 ]; then
        log_success "No unused asset files found!"
        return
    fi

    echo ""
    log_warning "Unused asset files detected:"
    for asset in "${unused_files[@]}"; do
        echo -e " ${RED}•${NC} $asset"
    done

    echo ""
    local confirm_delete=false
    if [ "$AUTO_CONFIRM" = true ]; then
        confirm_delete=true
        log_info "Auto-confirming deletion of unused files (--auto-confirm flag)"
    else
        clear_input_buffer 
        read -p "🗑️  Do you want to delete these unused files? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            confirm_delete=true
        fi
    fi

    if [ "$confirm_delete" = true ]; then
        for asset in "${unused_files[@]}"; do
            rm "$asset"
            log_verbose "Deleted $asset"
        done
        log_success "File cleanup complete!"
        
        echo ""
        log_info "📋 Summary of deleted files:"
        for asset in "${unused_files[@]}"; do
            echo -e " ${GREEN}✓${NC} $(basename "$asset")"
        done
    else
        log_info "No files were deleted."
    fi
}

# Show help message
show_help() {
    echo -e "${YELLOW}USAGE:${NC}"
    echo -e "  ${GREEN}flutter-assets-cleaner${NC} [OPTIONS]"
    echo ""
    echo -e "${YELLOW}OPTIONS:${NC}"
    echo -e "  ${GREEN}--help, -h${NC}              Show this help message"
    echo -e "  ${GREEN}--version, -v${NC}           Show version information"
    echo -e "  ${GREEN}--skip-constants${NC}        Skip cleanup of unused static const variables"
    echo -e "  ${GREEN}--skip-files${NC}            Skip cleanup of unused asset files"
    echo -e "  ${GREEN}--constants-only${NC}        Only clean unused constants (skip files)"
    echo -e "  ${GREEN}--files-only${NC}            Only clean unused files (skip constants)"
    echo -e "  ${GREEN}--auto-confirm, -y${NC}      Automatically confirm all deletions"
    echo -e "  ${GREEN}--verbose${NC}               Enable verbose output"
    echo -e "  ${GREEN}--asset-dir DIR${NC}         Specify assets directory (default: ./assets)"
    echo -e "  ${GREEN}--lib-dir DIR${NC}           Specify lib directory (default: ./lib)"
    echo ""
    echo -e "${YELLOW}EXAMPLES:${NC}"
    echo -e "  ${PURPLE}flutter-assets-cleaner${NC}                      Interactive cleanup (default)"
    echo -e "  ${PURPLE}flutter-assets-cleaner${NC} --constants-only     Only clean unused constants"
    echo -e "  ${PURPLE}flutter-assets-cleaner${NC} --files-only         Only clean unused files"
    echo -e "  ${PURPLE}flutter-assets-cleaner${NC} --auto-confirm       Clean everything without prompts"
    echo -e "  ${PURPLE}flutter-assets-cleaner${NC} --verbose            Show detailed output"
    echo -e "  ${PURPLE}flutter-assets-cleaner${NC} --asset-dir assets/images --lib-dir src"
    echo ""
    echo -e "${YELLOW}WHAT THIS TOOL DOES:${NC}"
    echo -e "  ${BLUE}1.${NC} 🔍 Finds and optionally removes unused static const variables from your Assets class"
    echo -e "  ${BLUE}2.${NC} 🔍 Finds and optionally removes unused asset files from your assets directory"
    echo ""
    echo -e "${YELLOW}AUTO-DETECTION FEATURES:${NC}"
    echo -e "  ${CYAN}•${NC} Assets class files (with static const String declarations)"
    echo -e "  ${CYAN}•${NC} Asset directories containing images, fonts, and other resources"
    echo -e "  ${CYAN}•${NC} Usage patterns in Dart code and YAML configuration files"
    echo ""
    echo -e "${YELLOW}💡 TIP:${NC} Run this tool regularly to keep your Flutter project clean and optimized!"
}

# Show version information
show_version() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🧼 Flutter Assets Cleanup Tool v1.0.0                     ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}📋 ABOUT:${NC}"
    echo -e "  A powerful tool to automatically detect and clean unused Flutter assets and constants."
    echo -e "  Helps reduce bundle size and improve app performance by removing dead code."
    echo ""
    echo -e "${YELLOW}🌟 FEATURES:${NC}"
    echo -e "  ${GREEN}•${NC} Smart auto-detection of Assets classes and directories"
    echo -e "  ${GREEN}•${NC} Interactive selection for multiple matches"
    echo -e "  ${GREEN}•${NC} Safe cleanup with confirmation prompts"
    echo -e "  ${GREEN}•${NC} Verbose logging for detailed operation tracking"
    echo -e "  ${GREEN}•${NC} Flexible command-line options for different workflows"
    echo ""
    echo -e "${YELLOW}🔗 LINKS:${NC}"
    echo -e "  ${BLUE}Repository:${NC} https://github.com/jamal-and/flutter_assets_cleaner"
    echo -e "  ${BLUE}License:${NC}    MIT"
    echo -e "  ${BLUE}Issues:${NC}     https://github.com/jamal-and/flutter_assets_cleaner/issues"
    echo ""
    echo -e "${GREEN}Made with ❤️ for the Flutter community${NC}"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --skip-constants)
                SKIP_CONSTANTS=true
                shift
                ;;
            --skip-files)
                SKIP_FILES=true
                shift
                ;;
            --constants-only)
                SKIP_FILES=true
                shift
                ;;
            --files-only)
                SKIP_CONSTANTS=true
                shift
                ;;
            --auto-confirm|-y)
                AUTO_CONFIRM=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --asset-dir)
                ASSET_DIR="$2"
                shift 2
                ;;
            --lib-dir)
                PROJECT_DIR="$2"
                CODE_DIR="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                echo -e "${YELLOW}💡 TIP:${NC} Use ${GREEN}flutter-assets-cleaner --help${NC} for usage information."
                exit 1
                ;;
        esac
    done
}

# Validate directories
validate_directories() {
    log_verbose "Validating directories..."
    
    # Check if we're in a Flutter project
    if [ ! -f "pubspec.yaml" ]; then
        echo ""
        log_error "No pubspec.yaml found in current directory!"
        echo -e "${YELLOW}💡 TIP:${NC} Please navigate to your Flutter project root directory and try again."
        echo -e "${CYAN}Example:${NC} cd /path/to/your/flutter/project && flutter-assets-cleaner"
        exit 1
    fi
    
    # Check lib directory
    if [ ! -d "$PROJECT_DIR" ]; then
        echo ""
        log_error "Lib directory not found: $PROJECT_DIR"
        echo -e "${YELLOW}💡 TIP:${NC} Use ${GREEN}--lib-dir${NC} to specify a custom lib directory."
        exit 1
    fi
    
    # Asset directory check is done in cleanup_unused_files function
    log_verbose "Directory validation complete"
}

# Main execution
main() {
    print_banner
    
    # Parse arguments first
    parse_arguments "$@"
    
    # Validate environment
    validate_directories
    
    # Update YAML_FILES with current directory
    YAML_FILES=$(find . -maxdepth 1 -name "*.yaml" 2>/dev/null)
    
    if [ "$SKIP_CONSTANTS" = false ] && [ "$SKIP_FILES" = false ]; then
        echo -e "${YELLOW}🎯 OPERATION OVERVIEW:${NC}"
        echo -e "  ${BLUE}1.${NC} 🔍 Find and optionally remove unused static const variables from your Assets class"
        echo -e "  ${BLUE}2.${NC} 🔍 Find and optionally remove unused asset files from your assets directory"
        echo ""
        
        if [ "$AUTO_CONFIRM" = false ]; then
            read -p "🚀 Ready to start cleanup? (y/N): " -n 1 -r
            echo ""
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}❌ Operation cancelled by user.${NC}"
                echo -e "${CYAN}💡 TIP:${NC} Use ${GREEN}flutter-assets-cleaner --help${NC} to see all available options."
                exit 0
            fi
        else
            log_info "Running in auto-confirm mode - no prompts will be shown"
        fi
    fi
    
    echo ""
    
    # Run cleanup functions based on flags
    cleanup_unused_constants
    cleanup_unused_files
    
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                          🎉 Cleanup Complete!                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}✨ Your Flutter project is now cleaner and more optimized!${NC}"
    echo -e "${YELLOW}💡 TIP:${NC} Run this tool regularly to maintain a clean codebase."
}
clear_input_buffer() {
    while read -r -s -t 1 -n 1000 discard 2>/dev/null; do
        continue
    done
}
# Run the main function with all arguments
main "$@"
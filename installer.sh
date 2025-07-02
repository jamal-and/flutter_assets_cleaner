#!/bin/bash

# Flutter Assets Cleanup Tool Installer
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="flutter-cleanup"
SCRIPT_FILE="flutter_cleanup.sh"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/your-repo/flutter-cleanup/main/flutter_cleanup.sh"

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                      Flutter Assets Cleanup Tool Installer                   ║"
    echo "║                                                                               ║"
    echo "║  🧼 Automatically detect and clean unused Flutter assets & constants         ║"
    echo "║  🔍 Smart detection of Assets classes and asset directories                  ║"
    echo "║  🛡️  Safe cleanup with backups and confirmations                             ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    log_step "Checking system requirements..."
    
    # Check if bash is available
    if ! command_exists bash; then
        log_error "Bash is required but not installed."
        exit 1
    fi
    
    # Check if curl or wget is available
    if ! command_exists curl && ! command_exists wget; then
        log_error "Either curl or wget is required for downloading."
        exit 1
    fi
    
    # Check if grep is available
    if ! command_exists grep; then
        log_error "grep is required but not installed."
        exit 1
    fi
    
    # Check if find is available
    if ! command_exists find; then
        log_error "find is required but not installed."
        exit 1
    fi
    
    log_success "All requirements satisfied!"
}

# Create installation directory
create_install_dir() {
    log_step "Creating installation directory..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        log_success "Created directory: $INSTALL_DIR"
    else
        log_info "Directory already exists: $INSTALL_DIR"
    fi
}

# Download or copy the script
install_script() {
    log_step "Installing Flutter Assets Cleanup Tool..."
    
    local script_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    # Check if we're installing from a local file or need to download
    if [ -f "$SCRIPT_FILE" ]; then
        log_info "Installing from local file: $SCRIPT_FILE"
        cp "$SCRIPT_FILE" "$script_path"
    else
        log_info "Downloading from: $SCRIPT_URL"
        if command_exists curl; then
            curl -fsSL "$SCRIPT_URL" -o "$script_path"
        elif command_exists wget; then
            wget -q "$SCRIPT_URL" -O "$script_path"
        else
            log_error "Cannot download script. Please install curl or wget."
            exit 1
        fi
    fi
    
    # Make script executable
    chmod +x "$script_path"
    
    log_success "Script installed to: $script_path"
}

# Create the embedded script (fallback if download fails)
create_embedded_script() {
    log_step "Creating embedded script..."
    
    local script_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    cat > "$script_path" << 'EOF'
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
        backup_file="${ASSETS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ASSETS_FILE" "$backup_file"
        echo "📦 Backup created: $backup_file"
        
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
detect_assets_directory() {
    echo "🔍 Auto-detecting assets directory..."
    
    local potential_dirs=()
    
    # Common asset directory names
    local common_names=("assets" "asset" "resources" "res" "images" "fonts")
    
    for name in "${common_names[@]}"; do
        if [ -d "./$name" ]; then
            # Check if directory contains actual asset files
            local asset_count=$(find "./$name" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.json" -o -iname "*.jpeg" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.ttf" -o -iname "*.otf" \) | wc -l)
            if [ "$asset_count" -gt 0 ]; then
                potential_dirs+=("./$name")
            fi
        fi
    done
    
    # Also check for any directory containing asset files
    while IFS= read -r -d '' dir; do
        local dirname=$(basename "$dir")
        # Skip common non-asset directories
        if [[ ! "$dirname" =~ ^(lib|test|android|ios|web|windows|macos|linux|build|\.dart_tool|\.git)$ ]]; then
            local asset_count=$(find "$dir" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.json" -o -iname "*.jpeg" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.ttf" -o -iname "*.otf" \) | wc -l)
            if [ "$asset_count" -gt 0 ]; then
                # Check if not already in potential_dirs
                local already_exists=false
                for existing in "${potential_dirs[@]}"; do
                    if [[ "$existing" == "$dir" ]]; then
                        already_exists=true
                        break
                    fi
                done
                if [[ "$already_exists" == false ]]; then
                    potential_dirs+=("$dir")
                fi
            fi
        fi
    done < <(find . -maxdepth 2 -type d -print0 2>/dev/null)
    
    # If no directories found, return default
    if [[ ${#potential_dirs[@]} -eq 0 ]]; then
        echo "⚠️  No asset directories detected"
        return 1
    fi
    
    # If only one directory found, use it
    if [[ ${#potential_dirs[@]} -eq 1 ]]; then
        ASSET_DIR="${potential_dirs[0]}"
        echo "✅ Auto-detected assets directory: $ASSET_DIR"
        return 0
    fi
    
    # If multiple directories found, let user choose
    echo ""
    echo "🔍 Multiple potential asset directories detected:"
    for i in "${!potential_dirs[@]}"; do
        local asset_count=$(find "${potential_dirs[i]}" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.json" -o -iname "*.jpeg" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.ttf" -o -iname "*.otf" \) | wc -l)
        echo "  $((i+1)). ${potential_dirs[i]} ($asset_count files)"
    done
    
    echo ""
    read -p "📝 Enter the number (1-${#potential_dirs[@]}) or 's' to skip file cleanup: " choice
    
    if [[ "$choice" == "s" || "$choice" == "S" ]]; then
        echo "⏭️  Skipping file cleanup"
        return 1
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#potential_dirs[@]} ]; then
        ASSET_DIR="${potential_dirs[$((choice-1))]}"
        echo "✅ Selected assets directory: $ASSET_DIR"
        return 0
    else
        echo "❌ Invalid selection. Skipping file cleanup."
        return 1
    fi
}

# Function to clean unused asset files
cleanup_unused_files() {
    echo ""
    echo "🔍 STEP 2: Scanning for unused asset files..."
    
    # Auto-detect assets directory
    if ! detect_assets_directory; then
        echo "⏭️  Skipping file cleanup"
        return
    fi
    
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
EOF
    
    chmod +x "$script_path"
    log_success "Embedded script created at: $script_path"
}

# Update PATH
update_path() {
    log_step "Updating PATH..."
    
    # Check if directory is already in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        log_info "Directory already in PATH: $INSTALL_DIR"
        return
    fi
    
    # Add to various shell config files
    local shell_configs=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local path_export="export PATH=\"\$PATH:$INSTALL_DIR\""
    local updated=false
    
    for config in "${shell_configs[@]}"; do
        if [ -f "$config" ]; then
            # Check if the path is already in the file
            if ! grep -q "$INSTALL_DIR" "$config"; then
                echo "" >> "$config"
                echo "# Added by Flutter Assets Cleanup Tool installer" >> "$config"
                echo "$path_export" >> "$config"
                log_success "Updated $config"
                updated=true
            else
                log_info "Path already exists in $config"
            fi
        fi
    done
    
    if [ "$updated" = true ]; then
        log_warning "Please restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
    fi
}

# Create uninstaller
create_uninstaller() {
    log_step "Creating uninstaller..."
    
    local uninstaller_path="$INSTALL_DIR/flutter-cleanup-uninstall"
    
    cat > "$uninstaller_path" << EOF
#!/bin/bash

echo "🗑️  Flutter Assets Cleanup Tool Uninstaller"
echo "============================================"

read -p "Are you sure you want to uninstall Flutter Assets Cleanup Tool? (y/N): " -n 1 -r
echo ""

if [[ \$REPLY =~ ^[Yy]\$ ]]; then
    # Remove main script
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        rm "$INSTALL_DIR/$SCRIPT_NAME"
        echo "✅ Removed main script"
    fi
    
    # Remove uninstaller
    rm "$uninstaller_path"
    echo "✅ Removed uninstaller"
    
    echo ""
    echo "🎉 Flutter Assets Cleanup Tool has been uninstalled!"
    echo "Note: You may need to manually remove the PATH entry from your shell config files."
else
    echo "❌ Uninstallation cancelled."
fi
EOF
    
    chmod +x "$uninstaller_path"
    log_success "Uninstaller created at: $uninstaller_path"
}

# Installation summary
print_summary() {
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                           🎉 Installation Complete!                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📦 Installation Details:${NC}"
    echo -e "   • Script installed to: ${YELLOW}$INSTALL_DIR/$SCRIPT_NAME${NC}"
    echo -e "   • Uninstaller available: ${YELLOW}flutter-cleanup-uninstall${NC}"
    echo ""
    echo -e "${CYAN}🚀 Usage:${NC}"
    echo -e "   1. Navigate to your Flutter project directory"
    echo -e "   2. Run: ${YELLOW}flutter-cleanup${NC}"
    echo ""
    echo -e "${CYAN}💡 Features:${NC}"
    echo -e "   • 🔍 Auto-detects Assets class files"
    echo -e "   • 🔍 Auto-detects asset directories"
    echo -e "   • 🛡️  Creates backups before cleanup"
    echo -e "   • 🎯 Interactive selection for multiple matches"
    echo -e "   • 🧹 Cleans both unused constants and files"
    echo ""
    echo -e "${CYAN}📚 Documentation:${NC}"
    echo -e "   • Run ${YELLOW}flutter-cleanup --help${NC} for more options"
    echo -e "   • Check GitHub for updates and documentation"
    echo ""
    echo -e "${GREEN}Happy cleaning! 🧼✨${NC}"
}

# Main installation function
main() {
    print_banner
    
    log_info "Starting Flutter Assets Cleanup Tool installation..."
    echo ""
    
    # Check if already installed
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        log_warning "Flutter Assets Cleanup Tool is already installed!"
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled."
            exit 0
        fi
    fi
    
    # Run installation steps
    check_requirements
    create_install_dir
    
    # Try to install script (fallback to embedded if download fails)
    if ! install_script 2>/dev/null; then
        log_warning "Download failed, using embedded script..."
        create_embedded_script
    fi
    
    update_path
    create_uninstaller
    
    print_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Flutter Assets Cleanup Tool Installer"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --uninstall    Uninstall the tool"
        echo "  --version      Show version information"
        echo ""
        echo "This installer will:"
        echo "  1. Download and install the Flutter Assets Cleanup Tool"
        echo "  2. Add it to your PATH for global access"
        echo "  3. Create an uninstaller for easy removal"
        ;;
    --uninstall)
        if [ -f "$INSTALL_DIR/flutter-cleanup-uninstall" ]; then
            exec "$INSTALL_DIR/flutter-cleanup-uninstall"
        else
            log_error "Uninstaller not found. Tool may not be installed."
            exit 1
        fi
        ;;
    --version)
        echo "Flutter Assets Cleanup Tool Installer v1.0.0"
        ;;
    *)
        main
        ;;
esac
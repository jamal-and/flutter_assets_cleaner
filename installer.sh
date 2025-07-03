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
SCRIPT_NAME="flutter-assets-cleaner"
SCRIPT_FILE="flutter_assets_cleaner.sh"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/jamal-and/flutter_assets_cleaner/refs/heads/main/flutter_assets_cleaner.sh"

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                      Flutter Assets Cleanup Tool Installer                    ║"
    echo "║                                                                               ║"
    echo "║  🧼 Automatically detect and clean unused Flutter assets & constants          ║"
    echo "║  🔍 Smart detection of Assets classes and asset directories                   ║"
    echo "║  🛡️  Safe cleanup with backups and confirmations                               ║"
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
        log_success "Script copied from local file"
    else
        log_info "Downloading from: $SCRIPT_URL"
        if command_exists curl; then
            if curl -fsSL "$SCRIPT_URL" -o "$script_path"; then
                log_success "Script downloaded successfully"
            else
                log_error "Failed to download script from $SCRIPT_URL"
                return 1
            fi
        elif command_exists wget; then
            if wget -q "$SCRIPT_URL" -O "$script_path"; then
                log_success "Script downloaded successfully"
            else
                log_error "Failed to download script from $SCRIPT_URL"
                return 1
            fi
        else
            log_error "Cannot download script. Please install curl or wget."
            return 1
        fi
    fi
    
    # Make script executable
    chmod +x "$script_path"
    log_success "Script installed to: $script_path"
    return 0
}

# Create a minimal fallback script (only if both download and local copy fail)
create_fallback_script() {
    log_step "Creating minimal fallback script..."
    
    local script_path="$INSTALL_DIR/$SCRIPT_NAME"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash

echo "❌ Flutter Assets Cleanup Tool - Installation Error"
echo "=================================================="
echo ""
echo "The installer could not download or copy the main script."
echo ""
echo "Please try one of the following:"
echo "1. Check your internet connection and run the installer again"
echo "2. Download flutter_assets_cleaner.sh manually and run the installer from the same directory"
echo "3. Visit the GitHub repository for manual installation instructions"
echo ""
echo "Repository: https://github.com/jamal-and/flutter_assets_cleaner"
echo ""
exit 1
EOF
    
    chmod +x "$script_path"
    log_warning "Fallback script created - manual intervention required"
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
    
    local uninstaller_path="$INSTALL_DIR/flutter-assets-cleaner-uninstall"
    
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
    echo -e "   • Uninstaller available: ${YELLOW}flutter-assets-cleaner-uninstall${NC}"
    echo ""
    echo -e "${CYAN}🚀 Usage:${NC}"
    echo -e "   1. Navigate to your Flutter project directory"
    echo -e "   2. Run: ${YELLOW}flutter-assets-cleaner${NC}"
    echo ""
    echo -e "${CYAN}💡 Features:${NC}"
    echo -e "   • 🔍 Auto-detects Assets class files"
    echo -e "   • 🔍 Auto-detects asset directories"
    echo -e "   • 🎯 Interactive selection for multiple matches"
    echo -e "   • 🧹 Cleans both unused constants and files"
    echo ""
    echo -e "${CYAN}📚 Documentation:${NC}"
    echo -e "   • Run ${YELLOW}flutter-assets-cleaner --help${NC} for more options"
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
    
    # Try to install script
    if install_script; then
        update_path
        create_uninstaller
        print_summary
    else
        log_error "Installation failed!"
        log_info "Attempting to create fallback script..."
        create_fallback_script
        echo ""
        log_error "Installation completed with errors. Please check the fallback script for instructions."
        exit 1
    fi
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
        if [ -f "$INSTALL_DIR/flutter-assets-cleaner-uninstall" ]; then
            exec "$INSTALL_DIR/flutter-assets-cleaner-uninstall"
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
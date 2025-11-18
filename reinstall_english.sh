#!/bin/bash

set -e

# Define color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define log functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get shell configuration file
get_shell_profile() {
    local current_shell=$(basename "$SHELL")
    case "$current_shell" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Clean npm configuration conflicts
clean_npmrc_conflict() {
    local npmrc="$HOME/.npmrc"
    if [[ -f "$npmrc" ]]; then
        log_info "Cleaning npmrc conflicts..."
        grep -Ev '^(prefix|globalconfig) *= *' "$npmrc" > "${npmrc}.tmp" && mv -f "${npmrc}.tmp" "$npmrc" || true
    fi
}

# Comprehensive uninstall of all iFlow CLI installations
comprehensive_uninstall_iflow() {
    log_info "=============================================="
    log_info "  Removing all existing iFlow CLI installations"
    log_info "=============================================="
    echo ""
    
    local found_installation=false
    
    # Check if iflow command exists
    if command_exists iflow; then
        found_installation=true
        log_warning "Existing iFlow CLI installation detected"
        
        # Try to get current version
        local current_version=$(iflow --version 2>/dev/null || echo "unknown")
        log_info "Current version: $current_version"
    fi
    
    # 1. Try npm global uninstall (all possible package names)
    log_info "Checking npm global installations..."
    
    local npm_packages=(
        "@iflow-ai/iflow-cli"
        "iflow-cli"
        "iflow"
    )
    
    for package in "${npm_packages[@]}"; do
        if npm list -g "$package" >/dev/null 2>&1; then
            found_installation=true
            log_info "Uninstalling $package via npm..."
            npm uninstall -g "$package" 2>/dev/null && log_success "Removed $package" || log_warning "Could not remove $package via npm"
        fi
    done
    
    # 2. Remove binaries from npm global directories
    log_info "Removing iflow binaries from npm directories..."
    
    local npm_prefix=$(npm config get prefix 2>/dev/null || echo "$HOME/.npm-global")
    local npm_paths=(
        "$npm_prefix/bin/iflow"
        "$npm_prefix/lib/node_modules/@iflow-ai/iflow-cli"
        "$npm_prefix/lib/node_modules/iflow-cli"
        "$npm_prefix/lib/node_modules/iflow"
    )
    
    for path in "${npm_paths[@]}"; do
        if [ -e "$path" ]; then
            found_installation=true
            log_info "Removing $path"
            rm -rf "$path" && log_success "Removed $path" || log_warning "Could not remove $path"
        fi
    done
    
    # 3. Remove from common system locations
    log_info "Checking common installation locations..."
    
    local common_paths=(
        "/usr/local/bin/iflow"
        "/usr/bin/iflow"
        "$HOME/.npm-global/bin/iflow"
        "$HOME/.local/bin/iflow"
        "$HOME/.nvm/versions/node/*/bin/iflow"
        "/opt/iflow"
        "/opt/iflow-cli"
    )
    
    for path in "${common_paths[@]}"; do
        # Use glob expansion for paths with wildcards
        for expanded_path in $path; do
            if [ -e "$expanded_path" ]; then
                found_installation=true
                log_info "Removing $expanded_path"
                rm -rf "$expanded_path" && log_success "Removed $expanded_path" || log_warning "Could not remove $expanded_path"
            fi
        done
    done
    
    # 4. Check for Debian/Ubuntu package installations (apt/dpkg)
    log_info "Checking for system package installations (apt/dpkg)..."
    
    if command_exists dpkg; then
        if dpkg -l | grep -i iflow >/dev/null 2>&1; then
            found_installation=true
            log_warning "Found iflow package installed via dpkg"
            
            # Try to remove with apt if available
            if command_exists apt-get; then
                log_info "Attempting to remove via apt-get..."
                sudo apt-get remove -y iflow iflow-cli 2>/dev/null && log_success "Removed via apt-get" || log_warning "Could not remove via apt-get"
                sudo apt-get autoremove -y 2>/dev/null || true
            fi
            
            # Fallback to dpkg
            log_info "Attempting to remove via dpkg..."
            sudo dpkg --remove iflow 2>/dev/null && log_success "Removed iflow via dpkg" || true
            sudo dpkg --remove iflow-cli 2>/dev/null && log_success "Removed iflow-cli via dpkg" || true
            sudo dpkg --purge iflow iflow-cli 2>/dev/null || true
        fi
    fi
    
    # 5. Remove configuration and cache directories
    log_info "Checking for configuration and cache directories..."
    
    local config_paths=(
        "$HOME/.iflow"
        "$HOME/.config/iflow"
        "$HOME/.cache/iflow"
        "$HOME/.local/share/iflow"
    )
    
    for path in "${config_paths[@]}"; do
        if [ -d "$path" ]; then
            log_warning "Found configuration directory: $path"
            read -p "Do you want to remove configuration directory $path? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$path" && log_success "Removed $path" || log_warning "Could not remove $path"
            else
                log_info "Keeping $path"
            fi
        fi
    done
    
    # 6. Final verification - check if iflow command still exists
    if command_exists iflow; then
        found_installation=true
        log_warning "iFlow CLI command still exists after cleanup"
        
        # Find the iflow executable
        local iflow_path=$(which iflow 2>/dev/null)
        if [ -n "$iflow_path" ] && [ -f "$iflow_path" ]; then
            log_info "Found iflow executable at: $iflow_path"
            log_info "Attempting to remove..."
            rm -f "$iflow_path" && log_success "Removed $iflow_path" || log_warning "Could not remove $iflow_path (may need sudo)"
            
            # Try with sudo if regular rm failed
            if [ -f "$iflow_path" ]; then
                log_info "Attempting to remove with sudo..."
                sudo rm -f "$iflow_path" && log_success "Removed $iflow_path with sudo" || log_error "Failed to remove $iflow_path"
            fi
        fi
    fi
    
    # Final check
    if command_exists iflow; then
        log_warning "iFlow CLI command still exists at: $(which iflow)"
        log_warning "Manual intervention may be required"
        log_info "Continuing with installation anyway..."
    else
        if [ "$found_installation" = true ]; then
            log_success "Successfully removed all existing iFlow CLI installations"
        else
            log_info "No existing iFlow CLI installation found"
        fi
    fi
    
    echo ""
}

# Install uv
install_uv() {
    if command_exists uv; then
        log_success "uv is already installed"
        log_info "uv version: $(uv --version 2>/dev/null || echo 'version info not available')"
        return 0
    fi
    
    log_info "Installing uv..."
    
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        log_success "uv installed successfully"
        # Add uv to PATH for current session
        export PATH="$HOME/.cargo/bin:$PATH"
        return 0
    else
        log_error "Failed to install uv"
        log_warning "Continuing without uv installation..."
        return 1
    fi
}

# Download nvm offline package
download_nvm_offline() {
    local VERSION=${1:-v0.40.3}
    local OUT_DIR=${2:-"/tmp/nvm-offline-${VERSION}"}
    local PACKAGE_URL="https://github.com/nvm-sh/nvm/archive/refs/tags/${VERSION}.tar.gz"
    local TEMP_FILE="/tmp/nvm-${VERSION}.tar.gz"
    
    log_info "Downloading nvm ${VERSION} package"
    mkdir -p "${OUT_DIR}"
    
    log_info "Downloading from: ${PACKAGE_URL}"
    if curl -sSL --connect-timeout 10 --max-time 60 "${PACKAGE_URL}" -o "${TEMP_FILE}"; then
        log_info "Package downloaded successfully, extracting..."
        
        if tar -xzf "${TEMP_FILE}" -C "${OUT_DIR}" --strip-components=1; then
            rm -f "${TEMP_FILE}"
            
            if [ -f "${OUT_DIR}/nvm-exec" ]; then
                chmod +x "${OUT_DIR}/nvm-exec"
            fi
            
            log_success "nvm downloaded and extracted successfully"
            return 0
        else
            log_error "Failed to extract nvm package"
            rm -f "${TEMP_FILE}"
            return 1
        fi
    else
        log_error "Failed to download nvm package"
        return 1
    fi
}

# Install nvm
install_nvm() {
    local NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    local NVM_VERSION="${NVM_VERSION:-v0.40.3}"
    local TMP_OFFLINE_DIR="/tmp/nvm-offline-${NVM_VERSION}"
    
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        log_info "nvm is already installed at $NVM_DIR"
        return 0
    fi
    
    # Download nvm
    if ! download_nvm_offline "${NVM_VERSION}" "${TMP_OFFLINE_DIR}"; then
        log_error "Failed to download nvm"
        return 1
    fi
    
    # Install nvm
    log_info "Installing nvm to ${NVM_DIR}"
    mkdir -p "${NVM_DIR}"
    cp "${TMP_OFFLINE_DIR}/"{nvm.sh,nvm-exec,bash_completion} "${NVM_DIR}/" || {
        log_error "Failed to copy nvm files"
        return 1
    }
    chmod +x "${NVM_DIR}/nvm-exec"
    
    # Configure shell profile
    local PROFILE_FILE=$(get_shell_profile)
    local current_shell=$(basename "$SHELL")
    
    if [ "$current_shell" = "fish" ]; then
        mkdir -p "$(dirname "$PROFILE_FILE")"
    fi
    
    # Add nvm to profile
    if [ "$current_shell" = "fish" ]; then
        local FISH_NVM_CONFIG='
# NVM configuration for fish shell
set -gx NVM_DIR "'${NVM_DIR}'"
if test -s "$NVM_DIR/nvm.sh"
    bass source "$NVM_DIR/nvm.sh"
end'
        
        if ! grep -q 'NVM_DIR' "${PROFILE_FILE}" 2>/dev/null; then
            if ! fish -c "type -q bass" 2>/dev/null; then
                log_warning "bass is not installed. Installing bass for fish shell nvm support..."
                fish -c "curl -sL https://raw.githubusercontent.com/edc/bass/master/functions/bass.fish | source && fisher install edc/bass" || {
                    log_warning "Failed to install bass. You may need to install it manually."
                    log_info "Visit: https://github.com/edc/bass"
                }
            fi
            echo "${FISH_NVM_CONFIG}" >> "${PROFILE_FILE}"
            log_info "Added nvm to ${PROFILE_FILE}"
        fi
    else
        local SOURCE_STR='
export NVM_DIR="'${NVM_DIR}'"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
        
        if ! grep -q 'NVM_DIR' "${PROFILE_FILE}" 2>/dev/null; then
            echo "${SOURCE_STR}" >> "${PROFILE_FILE}"
            log_info "Added nvm to ${PROFILE_FILE}"
        fi
    fi
    
    rm -rf "${TMP_OFFLINE_DIR}"
    
    log_success "nvm installed successfully"
    return 0
}

# Install Node.js with nvm
install_nodejs_with_nvm() {
    local NODE_VERSION="${NODE_VERSION:-22}"
    local NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    
    export NVM_DIR="${NVM_DIR}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command_exists nvm; then
        log_error "nvm not loaded properly"
        return 1
    fi
    
    # Check if xz needs to be installed (required for Node.js)
    if ! command_exists xz; then
        log_warning "xz not found, installing xz-utils..."
        sudo apt-get update && sudo apt-get install -y xz-utils || log_warning "Failed to install xz-utils, continuing anyway..."
    fi
    
    # Clear cache
    log_info "Clearing nvm cache..."
    nvm cache clear || true
    
    # Install Node.js
    log_info "Installing Node.js v${NODE_VERSION}..."
    if nvm install ${NODE_VERSION}; then
        nvm alias default ${NODE_VERSION}
        nvm use default
        log_success "Node.js v${NODE_VERSION} installed successfully"
        
        log_info "Node.js version: $(node -v)"
        log_info "npm version: $(npm -v)"
        
        clean_npmrc_conflict
        
        # Set npm registry to default (npmjs.org for English version)
        npm config set registry https://registry.npmjs.org
        log_info "npm registry set to npmjs.org (official registry)"
        
        return 0
    else
        log_error "Failed to install Node.js"
        return 1
    fi
}

# Check Node.js version
check_node_version() {
    if ! command_exists node; then
        return 1
    fi
    
    local current_version=$(node -v | sed 's/v//')
    local major_version=$(echo $current_version | cut -d. -f1)
    
    if [ "$major_version" -ge 20 ]; then
        log_success "Node.js v$current_version is already installed (>= 20)"
        return 0
    else
        log_warning "Node.js v$current_version is installed but version < 20"
        return 1
    fi
}

# Install Node.js
install_nodejs() {
    log_info "Installing Node.js..."
    
    if ! install_nvm; then
        log_error "Failed to install nvm"
        return 1
    fi
    
    export NVM_DIR="${HOME}/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! install_nodejs_with_nvm; then
        log_error "Failed to install Node.js"
        return 1
    fi
}

# Check and install Node.js
check_and_install_nodejs() {
    if check_node_version; then
        log_info "Using existing Node.js installation"
        clean_npmrc_conflict
        # Ensure registry is set to default for English version
        npm config set registry https://registry.npmjs.org
    else
        log_warning "Installing or upgrading Node.js..."
        install_nodejs
    fi
}

# Install iFlow CLI (English version)
install_iflow_cli_english() {
    log_info "=============================================="
    log_info "  Installing iFlow CLI (English Version)"
    log_info "=============================================="
    echo ""
    
    log_info "Installing iFlow CLI from @iflow-ai/iflow-cli@latest..."
    
    if npm i -g @iflow-ai/iflow-cli@latest; then
        log_success "iFlow CLI installed successfully!"
        
        # Verify installation
        if command_exists iflow; then
            local version=$(iflow --version 2>/dev/null || echo 'version info not available')
            log_info "iFlow CLI version: $version"
        else
            log_warning "iFlow CLI installed but command not found. You may need to reload your shell or add npm global bin to PATH."
            log_info "Try running: export PATH=\"\$PATH:$(npm config get prefix)/bin\""
        fi
    else
        log_error "Failed to install iFlow CLI!"
        exit 1
    fi
}

# Main function
main() {
    echo "=========================================================="
    echo "   iFlow CLI Reinstall Script (English Version)"
    echo "   Optimized for Pop!_OS / Ubuntu / Debian"
    echo "=========================================================="
    echo ""
    
    # Check system
    log_info "System: $(uname -s) $(uname -r)"
    log_info "Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
    log_info "Shell: $(basename "$SHELL")"
    echo ""
    
    # Verify this is a Debian-based system
    if [ ! -f /etc/debian_version ]; then
        log_warning "This script is optimized for Debian-based systems (Ubuntu, Pop!_OS, etc.)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
    fi
    
    # Step 1: Comprehensive uninstall
    comprehensive_uninstall_iflow
    
    # Step 2: Install uv (optional, continue if fails)
    install_uv || log_warning "UV installation failed, but continuing with the rest of the installation..."
    
    # Step 3: Check and install Node.js
    check_and_install_nodejs
    
    # Ensure npm command is available
    if ! command_exists npm; then
        log_error "npm command not found after Node.js installation!"
        log_info "Please run: source $(get_shell_profile)"
        exit 1
    fi
    
    # Step 4: Install iFlow CLI (English version)
    install_iflow_cli_english
    
    echo ""
    echo "=========================================================="
    log_success "Reinstallation completed successfully!"
    echo "=========================================================="
    echo ""
    
    log_info "To start using iFlow CLI, run:"
    local current_shell=$(basename "$SHELL")
    case "$current_shell" in
        bash)
            echo "  source ~/.bashrc"
            ;;
        zsh) 
            echo "  source ~/.zshrc"
            ;;
        fish)
            echo "  source ~/.config/fish/config.fish"
            ;;
        *)
            echo "  source ~/.profile  # or reload your shell"
            ;;
    esac
    echo "  iflow"
    echo ""
    
    log_info "iFlow CLI has been installed in English mode"
    log_info "npm registry: $(npm config get registry)"
    echo ""
}

# Error handling
trap 'log_error "An error occurred. Installation aborted."; exit 1' ERR

# Run main function
main

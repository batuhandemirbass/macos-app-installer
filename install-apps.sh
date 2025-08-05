#!/bin/bash

# macOS Automatic App Installer Script
# This script uses Homebrew to install Asana, Slack, Pritunl and Google Chrome

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logo and title
echo -e "${BLUE}"
echo "================================================"
echo "    macOS Automatic App Installer Script"
echo "================================================"
echo -e "${NC}"

# Stop script on error
set -e

# Log functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Connectivity check
check_connectivity() {
    log "Checking internet connection..."
    
    # Test basic internet connectivity
    if ! ping -c 1 -W 5000 8.8.8.8 &> /dev/null; then
        error "No internet connection found!"
        exit 1
    fi
    
    # Test Homebrew API access
    info "Testing Homebrew API access..."
    if ! curl -Is --connect-timeout 15 --max-time 30 https://formulae.brew.sh &> /dev/null; then
        warning "Access issue detected with formulae.brew.sh!"
        warning "Please check the following:"
        echo "  • Check your VPN connection"
        echo "  • Check your firewall settings"
        echo "  • Try changing DNS settings manually"
        
        info "Continuing with installation, some operations may fail..."
    else
        log "Homebrew API access successful ✓"
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    log "Checking for Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        warning "Homebrew not found. Installing..."
        
        # Install Homebrew (with retry mechanism)
        local max_attempts=3
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            info "Homebrew installation attempt $attempt/$max_attempts"
            
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                break
            else
                if [[ $attempt -eq $max_attempts ]]; then
                    error "Homebrew installation failed after $max_attempts attempts!"
                    exit 1
                fi
                warning "Installation failed, retrying in 10 seconds..."
                sleep 10
                ((attempt++))
            fi
        done
        
        # Add to PATH (for Apple Silicon Macs)
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            # For Intel Macs
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log "Homebrew successfully installed!"
    else
        log "Homebrew already installed ✓"
    fi
}

# Check Homebrew health
check_homebrew_health() {
    log "Checking Homebrew health..."
    
    if command -v brew &> /dev/null; then
        # Run Homebrew doctor
        info "Running Homebrew doctor..."
        brew doctor || warning "Homebrew doctor gave some warnings, but continuing..."
        
        # Check Homebrew config
        info "Checking Homebrew configuration..."
        brew config > /dev/null 2>&1 || warning "Homebrew config check failed"
        
        log "Homebrew health check completed ✓"
    fi
}

# Update Homebrew
update_homebrew() {
    log "Updating Homebrew..."
    
    # First update taps
    info "Updating Homebrew taps..."
    brew tap --repair || warning "Tap repair failed"
    
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        info "Homebrew update attempt $attempt/$max_attempts"
        
        # Use HOMEBREW_NO_AUTO_UPDATE=1 to disable automatic updates
        if HOMEBREW_NO_AUTO_UPDATE=1 brew update --quiet; then
            log "Homebrew updated ✓"
            return 0
        else
            if [[ $attempt -eq $max_attempts ]]; then
                warning "Homebrew update failed!"
                info "Trying alternative method..."
                
                # Clean Homebrew cache
                brew cleanup --prune=all
                rm -rf "$(brew --cache)"
                
                # Manual repo update
                info "Trying manual repo update..."
                if command -v git &> /dev/null; then
                    brew_repo_path=$(brew --repository)
                    if [[ -d "$brew_repo_path/.git" ]]; then
                        cd "$brew_repo_path" && git fetch --all && git reset --hard origin/master
                        log "Manual update completed ✓"
                        return 0
                    fi
                fi
                
                warning "Skipping update, continuing with installation..."
                return 0
            fi
            warning "Update failed, retrying in 10 seconds..."
            sleep 10
            ((attempt++))
        fi
    done
}

# Install cask applications
install_cask_apps() {
    local apps=("asana" "slack" "pritunl" "google-chrome")
    
    log "Installing cask applications..."
    
    # Check cask tap
    info "Checking Homebrew Cask..."
    if ! brew tap | grep -q "homebrew/cask"; then
        info "Adding Homebrew Cask tap..."
        brew tap homebrew/cask || warning "Could not add cask tap"
    fi
    
    for app in "${apps[@]}"; do
        info "Installing: $app"
        
        # Check if app is already installed
        if brew list --cask 2>/dev/null | grep -q "^${app}$"; then
            warning "$app is already installed, skipping..."
            continue
        fi
        
        # Install app (with retry mechanism)
        local max_attempts=3
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            info "$app installation attempt $attempt/$max_attempts"
            
            # Install with disabled auto-update
            if HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask "$app" --no-quarantine 2>/dev/null; then
                log "$app successfully installed ✓"
                break
            else
                if [[ $attempt -eq $max_attempts ]]; then
                    error "$app installation failed! (All attempts failed)"
                    warning "This app can be installed manually: brew install --cask $app"
                    continue 2
                fi
                warning "$app installation failed, retrying in 10 seconds..."
                
                # Clean cache
                brew cleanup
                sleep 10
                ((attempt++))
            fi
        done
    done
}

# Post-installation cleanup
cleanup() {
    log "Performing post-installation cleanup..."
    brew cleanup
    log "Cleanup completed ✓"
}

# List installed apps
list_installed_apps() {
    info "Installed cask applications:"
    echo ""
    brew list --cask | grep -E "(asana|slack|pritunl|google-chrome)" || warning "None of the specified apps are installed"
    echo ""
}

# Main function
main() {
    log "Starting installation..."
    echo ""
    
    # System information
    info "System: $(sw_vers -productName) $(sw_vers -productVersion)"
    info "Architecture: $(uname -m)"
    echo ""
    
    # Get user confirmation
    echo -e "${YELLOW}This script will install the following applications:"
    echo "• Asana (Project management)"
    echo "• Slack (Communication)"
    echo "• Pritunl (VPN client)"
    echo "• Google Chrome (Web browser)"
    echo ""
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Installation cancelled."
        exit 0
    fi
    
    echo ""
    
    # Installation steps
    check_connectivity
    check_homebrew
    check_homebrew_health
    update_homebrew
    install_cask_apps
    cleanup
    
    echo ""
    log "Installation completed! 🎉"
    echo ""
    
    list_installed_apps
    
    info "Applications can be found in Launchpad or Applications folder."
    info "Some apps may request additional permissions on first launch."
}

# Check if script is being executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

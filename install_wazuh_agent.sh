#!/bin/bash

# Wazuh Agent Installation Script for macOS and Linux
# Usage: ./install_wazuh_agent.sh [AGENT_NAME] [PASSWORD]

set -e  # Exit on any error

# Configuration
WAZUH_MANAGER='wazuh.kasha.io'
WAZUH_AGENT_GROUP='default'
WAZUH_VERSION='4.12.0-1'

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root/sudo
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root. This is fine for installation."
    else
        log_info "Will use sudo for privileged operations."
    fi
}

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS"
        
        # Detect architecture
        ARCH=$(uname -m)
        if [[ "$ARCH" == "arm64" ]]; then
            PKG_ARCH="arm64"
        elif [[ "$ARCH" == "x86_64" ]]; then
            PKG_ARCH="x86_64"
        else
            log_error "Unsupported macOS architecture: $ARCH"
            exit 1
        fi
        log_info "Architecture: $PKG_ARCH"
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_info "Detected Linux"
        
        # Detect Linux distribution
        if command -v rpm >/dev/null 2>&1; then
            PKG_TYPE="rpm"
            log_info "RPM-based distribution detected"
        elif command -v dpkg >/dev/null 2>&1; then
            PKG_TYPE="deb"
            log_info "DEB-based distribution detected"
        else
            log_error "Unsupported Linux distribution (no rpm or dpkg found)"
            exit 1
        fi
        
        # Detect architecture
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            PKG_ARCH="x86_64"
        elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
            PKG_ARCH="arm64"
        else
            log_error "Unsupported Linux architecture: $ARCH"
            exit 1
        fi
        log_info "Architecture: $PKG_ARCH"
        
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# Function to get agent name and password
get_credentials() {
    # Check command line arguments first
    if [[ $# -ge 1 ]]; then
        NAME="$1"
    else
        # Get hostname as default name
        DEFAULT_NAME=$(hostname)
        read -p "Enter agent name [$DEFAULT_NAME]: " NAME
        NAME=${NAME:-$DEFAULT_NAME}
    fi
    
    if [[ $# -ge 2 ]]; then
        PASSWORD="$2"
    else
        read -s -p "Enter registration password: " PASSWORD
        echo
        if [[ -z "$PASSWORD" ]]; then
            log_error "Password cannot be empty"
            exit 1
        fi
    fi
    
    log_info "Agent name: $NAME"
}

# Function to install Wazuh agent on macOS
install_macos() {
    log_info "Installing Wazuh agent on macOS..."
    
    # Download the package
    PACKAGE_URL="https://packages.wazuh.com/4.x/macos/wazuh-agent-${WAZUH_VERSION}.${PKG_ARCH}.pkg"
    log_info "Downloading from: $PACKAGE_URL"
    
    curl -so wazuh-agent.pkg "$PACKAGE_URL"
    
    # Create environment file
    log_info "Setting up environment variables..."
    echo "WAZUH_MANAGER='$WAZUH_MANAGER'" > /tmp/wazuh_envs
    echo "WAZUH_AGENT_GROUP='$WAZUH_AGENT_GROUP'" >> /tmp/wazuh_envs
    echo "WAZUH_AGENT_NAME='$NAME'" >> /tmp/wazuh_envs
    echo "WAZUH_REGISTRATION_PASSWORD='$PASSWORD'" >> /tmp/wazuh_envs
    
    # Install the package
    log_info "Installing Wazuh agent package..."
    sudo installer -pkg ./wazuh-agent.pkg -target /
    
    # Configure SCA remote commands
    log_info "Configuring SCA remote commands..."
    echo "sca.remote_commands=1" | sudo tee -a /Library/Ossec/etc/local_internal_options.conf > /dev/null
    
    # Start the service
    log_info "Starting Wazuh agent service..."
    sudo /Library/Ossec/bin/wazuh-control start
    
    # Cleanup
    rm -f wazuh-agent.pkg
    rm -f /tmp/wazuh_envs
    
    log_info "macOS installation completed successfully!"
}

# Function to install Wazuh agent on Linux (RPM)
install_linux_rpm() {
    log_info "Installing Wazuh agent on Linux (RPM)..."
    
    # Download the package
    PACKAGE_URL="https://packages.wazuh.com/4.x/yum/wazuh-agent-${WAZUH_VERSION}.${PKG_ARCH}.rpm"
    log_info "Downloading from: $PACKAGE_URL"
    
    curl -o wazuh-agent.rpm "$PACKAGE_URL"
    
    # Install with environment variables
    log_info "Installing Wazuh agent package..."
    sudo WAZUH_MANAGER="$WAZUH_MANAGER" \
         WAZUH_REGISTRATION_PASSWORD="$PASSWORD" \
         WAZUH_AGENT_GROUP="$WAZUH_AGENT_GROUP" \
         WAZUH_AGENT_NAME="$NAME" \
         rpm -ihv wazuh-agent.rpm
    
    # Configure SCA remote commands
    log_info "Configuring SCA remote commands..."
    echo "sca.remote_commands=1" | sudo tee -a /var/ossec/etc/local_internal_options.conf > /dev/null
    
    # Start and enable the service
    log_info "Starting and enabling Wazuh agent service..."
    sudo systemctl daemon-reload
    sudo systemctl enable wazuh-agent
    sudo systemctl start wazuh-agent
    
    # Cleanup
    rm -f wazuh-agent.rpm
    
    log_info "Linux (RPM) installation completed successfully!"
}

# Function to install Wazuh agent on Linux (DEB)
install_linux_deb() {
    log_info "Installing Wazuh agent on Linux (DEB)..."
    
    # Download the package
    PACKAGE_URL="https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_${WAZUH_VERSION}_${PKG_ARCH}.deb"
    log_info "Downloading from: $PACKAGE_URL"
    
    curl -o wazuh-agent.deb "$PACKAGE_URL"
    
    # Set environment variables and install
    log_info "Installing Wazuh agent package..."
    export WAZUH_MANAGER="$WAZUH_MANAGER"
    export WAZUH_REGISTRATION_PASSWORD="$PASSWORD"
    export WAZUH_AGENT_GROUP="$WAZUH_AGENT_GROUP"
    export WAZUH_AGENT_NAME="$NAME"
    
    sudo -E dpkg -i wazuh-agent.deb
    
    # Configure SCA remote commands
    log_info "Configuring SCA remote commands..."
    echo "sca.remote_commands=1" | sudo tee -a /var/ossec/etc/local_internal_options.conf > /dev/null
    
    # Start and enable the service
    log_info "Starting and enabling Wazuh agent service..."
    sudo systemctl daemon-reload
    sudo systemctl enable wazuh-agent
    sudo systemctl start wazuh-agent
    
    # Cleanup
    rm -f wazuh-agent.deb
    
    log_info "Linux (DEB) installation completed successfully!"
}

# Function to verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    if [[ "$OS" == "macos" ]]; then
        if sudo /Library/Ossec/bin/wazuh-control status | grep -q "wazuh-agentd is running"; then
            log_info "✓ Wazuh agent is running"
        else
            log_warn "⚠ Wazuh agent may not be running properly"
        fi
    else
        if sudo systemctl is-active --quiet wazuh-agent; then
            log_info "✓ Wazuh agent service is active"
        else
            log_warn "⚠ Wazuh agent service may not be running properly"
        fi
    fi
}

# Main function
main() {
    log_info "=== Wazuh Agent Installation Script ==="
    
    # Check system requirements
    check_privileges
    detect_os
    get_credentials "$@"
    
    # Install based on OS
    case "$OS" in
        "macos")
            install_macos
            ;;
        "linux")
            if [[ "$PKG_TYPE" == "rpm" ]]; then
                install_linux_rpm
            else
                install_linux_deb
            fi
            ;;
    esac
    
    # Verify the installation
    verify_installation
    
    log_info "=== Installation Complete ==="
    log_info "Manager: $WAZUH_MANAGER"
    log_info "Agent Name: $NAME"
    log_info "Group: $WAZUH_AGENT_GROUP"
}

# Run main function with all arguments
main "$@"
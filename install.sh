#!/bin/bash

# Constants
PYTHON_SCRIPT_URL="https://github.com/khaledagn/AGN-SSH-Websocket-VPN/raw/main/agn_websocket.py"
INSTALL_DIR="/opt/agn_websocket"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/agn-websocket.service"
PYTHON_BIN=$(command -v python3)  # Ensure python3 is available
AGN_MANAGER_SCRIPT="agnws_manager.sh"
AGN_MANAGER_PATH="$INSTALL_DIR/$AGN_MANAGER_SCRIPT"
AGN_MANAGER_LINK="/usr/local/bin/websocket"

# Function to install required packages
install_required_packages() {
    echo "Installing required packages..."
    apt-get update
    apt-get install -y python3-pip dos2unix curl
    pip3 install --upgrade pip
    pip3 install websocket-client  # Adjust with other required packages as needed
}

# Function to download Python proxy script
download_agn_websocket() {
    echo "Downloading Python proxy script from $PYTHON_SCRIPT_URL..."
    curl -o "$INSTALL_DIR/agn_websocket.py" "$PYTHON_SCRIPT_URL"
}

# Function to install agnws_manager.sh script and set it as executable
install_agnws_manager() {
    echo "Installing $AGN_MANAGER_SCRIPT..."
    curl -o "$AGN_MANAGER_PATH" "https://github.com/khaledagn/AGN-SSH-Websocket-VPN/raw/main/agnws_manager.sh"
    chmod +x "$AGN_MANAGER_PATH"
    ln -sf "$AGN_MANAGER_PATH" "$AGN_MANAGER_LINK"
    convert_to_unix_line_endings "$AGN_MANAGER_PATH"
}

# Function to convert script to Unix line endings
convert_to_unix_line_endings() {
    local file="$1"
    echo "Converting $file to Unix line endings..."
    dos2unix "$file"
}

# Function to start systemd service
start_systemd_service() {
    echo "Starting agn-websocket service..."
    systemctl start agn-websocket
    systemctl status agn-websocket --no-pager
}

# Function to install systemd service
install_systemd_service() {
    echo "Creating systemd service file..."
    cat > "$SYSTEMD_SERVICE_FILE" <<EOF
[Unit]
Description=Python Proxy Service
After=network.target

[Service]
ExecStart=$PYTHON_BIN $INSTALL_DIR/agn_websocket.py 8098
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    echo "Enabling agn-websocket service..."
    systemctl enable agn-websocket
}

# Function to display banner
display_banner() {
    cat << "EOF"
**********************************************
*                                            *
*                Khaled AGN                  *
*      Visit me on Telegram: @khaledagn      *
*                                            *
**********************************************
EOF
    echo
}

# Function to display installation summary
display_installation_summary() {
    echo "Installation completed successfully!"
    echo
    echo "Installed agn_websocket.py in: $INSTALL_DIR"
    echo "Installed $AGN_MANAGER_SCRIPT in: $AGN_MANAGER_PATH"
    echo "You can now manage the WebSocket service using 'websocket menu' command."
}

# Main function
main() {
    display_banner

    # Install required packages
    install_required_packages

    # Check if python3 is available
    if [ -z "$PYTHON_BIN" ]; then
        echo "Error: Python 3 is not installed or not found in PATH. Please install Python 3."
        exit 1
    fi

    # Create installation directory
    echo "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"

    # Download Python proxy script
    download_agn_websocket

    # Install agnws_manager.sh script
    install_agnws_manager

    # Install systemd service
    install_systemd_service
    
    # Start systemd service
    start_systemd_service

    # Display installation summary
    display_installation_summary
}

# Run main function
main

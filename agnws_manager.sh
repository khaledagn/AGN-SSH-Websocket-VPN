#!/bin/bash

# Constants
AGN_WEBSOCKET_SERVICE="agn-websocket"
PYTHON_SCRIPT_PATH="/opt/agn_websocket/agn_websocket.py"

# Function to display banner
display_banner() {
   cat << "EOF"
*************************************************
*                                               *
*                  Khaled AGN                   *
*        Visit me on Telegram: @khaledagn       *
*                                               *
*************************************************
EOF
}

# Function to show menu
show_menu() {
   clear
   display_banner
   echo "Websocket VPN Manager Menu"
   echo "1. Check Server Status"
   echo "2. Manage SSH Users"
   echo "3. Change Listening Port"
   echo "4. Restart WebSocket Service"
   echo "5. Uninstall Websocket"
   echo "6. Server Information"
   echo "7. Exit"
}

# Function to check server status
check_server_status() {
   echo "Server Status:"
   systemctl is-active $AGN_WEBSOCKET_SERVICE
}

# Function to add SSH user
add_ssh_user() {
    read -p "Enter username to add: " username
    read -p "Enter password for $username: " -s password
    echo

    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "Error: Username or password cannot be empty."
        return 1
    fi

    if id "$username" &>/dev/null; then
        echo "Error: User $username already exists."
        return 1
    fi

    useradd -m -s /bin/bash -G ssh "$username"
    echo "$username:$password" | chpasswd

    echo "User $username added with SSH access."
}

# Function to remove SSH user
remove_ssh_user() {
   read -p "Enter username to remove: " username

   if ! id "$username" &>/dev/null; then
       echo "Error: User $username does not exist."
       return 1
   fi

   userdel -r "$username"
   echo "User $username removed."
}

# Function to list SSH users
list_ssh_users() {
   echo "SSH Users:"
   awk -F: '$7 ~ /(\/bin\/bash|\/bin\/sh)/ && $1 != "root" { print $1 }' /etc/passwd
}

# Function to manage SSH users
manage_ssh_users() {
   while true; do
       clear
       echo -e "SSH User Management\n"
       echo "1. Add SSH User"
       echo "2. Remove SSH User"
       echo "3. List SSH Users"
       echo "4. Back to Main Menu"

       read -p "Enter your choice: " choice

       case $choice in
           1) add_ssh_user ;;
           2) remove_ssh_user ;;
           3) list_ssh_users ;;
           4) break ;;
           *) echo "Invalid choice. Please enter a valid option." ;;
       esac

       read -n 1 -s -r -p "Press any key to continue..."
       echo
   done
}

# Function to change listening port
change_listening_port() {
   read -p "Enter new Websocket listening port: " new_port

   if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
       echo "Error: Please enter a valid integer port number."
       return
   fi

   if [ -f "$PYTHON_SCRIPT_PATH" ]; then
       sed -i "s/^LISTENING_PORT = .*/LISTENING_PORT = $new_port/" "$PYTHON_SCRIPT_PATH"
       echo "Websocket listening port changed to $new_port."

       # Restart WebSocket service
       restart_websocket_service
   else
       echo "Error: File $PYTHON_SCRIPT_PATH not found."
   fi
}

# Function to restart WebSocket service
restart_websocket_service() {
   echo "Restarting $AGN_WEBSOCKET_SERVICE service..."
   systemctl restart $AGN_WEBSOCKET_SERVICE
   systemctl status $AGN_WEBSOCKET_SERVICE --no-pager  # Optionally, show status after restarting
}

# Function to uninstall proxy script
uninstall_proxy_script() {
   echo "Stopping $AGN_WEBSOCKET_SERVICE service..."
   systemctl stop $AGN_WEBSOCKET_SERVICE

   echo "Disabling $AGN_WEBSOCKET_SERVICE service..."
   systemctl disable $AGN_WEBSOCKET_SERVICE

   echo "Removing Python proxy files..."
   rm -rf "/opt/agn_websocket"
   rm /usr/local/bin/websocket

   echo "Removing systemd service file..."
   rm -f "/etc/systemd/system/$AGN_WEBSOCKET_SERVICE.service"

   echo "Python proxy script uninstalled."
}

# Function to display server information
server_information() {
   echo "Server Information:"
   echo

   # Check if service is active
   if systemctl is-active --quiet $AGN_WEBSOCKET_SERVICE; then
       echo "WebSocket Service Status: Active"
   else
       echo "WebSocket Service Status: Inactive"
   fi

   # Display current listening port if script file exists
   if [ -f "$PYTHON_SCRIPT_PATH" ]; then
       current_port=$(grep -oP '(?<=LISTENING_PORT = )[0-9]+' "$PYTHON_SCRIPT_PATH")
       echo "Current Listening Port: $current_port"
   else
       echo "Current Listening Port: Not available (Script file not found)"
   fi
}

# Main function
main() {
   if [ "$1" = "menu" ]; then
       while true; do
           show_menu
           read -p "Enter your choice: " choice

           case $choice in
               1) check_server_status ;;
               2) manage_ssh_users ;;
               3) change_listening_port ;;
               4) restart_websocket_service ;;
               5) uninstall_proxy_script; break ;;
               6) server_information ;;
               7) echo "Exiting..."; break ;;
               *) echo "Invalid choice. Please enter a valid option." ;;
           esac

           read -n 1 -s -r -p "Press any key to continue..."
           echo
       done
   else
       echo "Usage: $0 menu"
   fi
}

# Run main function with arguments
main "$@"

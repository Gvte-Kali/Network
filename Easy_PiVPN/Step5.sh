# Define colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
NC="\033[0m"              # Reset color

# Step 5: Network Configuration
step5() {
  echo -e "\n${GRAY_BLUE}=== Step 5: Network Configuration ===${NC}"

  # Check which network manager is being used
  if systemctl is-active --quiet dhcpcd; then
    echo "Using dhcpcd for network management."
    echo "Current dhcpcd configuration:"
    cat /etc/dhcpcd.conf
  elif systemctl is-active --quiet NetworkManager; then
    echo "Using NetworkManager for network management."
    echo "Current NetworkManager configuration:"
    nmcli device show
  else
    echo "No recognized network management service is running."
    return 1  # Exit the function if no service is found
  fi

  # Prompt to modify network configuration
  read -p "Do you want to modify the network configuration? (Y/n): " modify_choice

  if [[ "$modify_choice" =~ ^[Yy]$ ]] || [ -z "$modify_choice" ]; then
    echo "Proceeding to modify the network configuration..."
    
    # Example modification: Ask for new IP address and netmask
    read -p "Enter new IP address (e.g., 192.168.1.100): " new_ip
    read -p "Enter new netmask (e.g., 255.255.255.0): " new_netmask
    read -p "Enter new gateway (e.g., 192.168.1.1): " new_gateway

    # Modify the configuration based on the network manager in use
    if systemctl is-active --quiet dhcpcd; then
      echo "Modifying dhcpcd configuration..."
      # Here you would typically modify /etc/dhcpcd.conf
      echo -e "\n# Custom configuration added by script" >> /etc/dhcpcd.conf
      echo "interface eth0" >> /etc/dhcpcd.conf  # Change 'eth0' to your actual interface name
      echo "static ip_address=$new_ip/$new_netmask" >> /etc/dhcpcd.conf
      echo "static routers=$new_gateway" >> /etc/dhcpcd.conf
      echo "Configuration updated. Restarting dhcpcd service..."
      sudo systemctl restart dhcpcd
    elif systemctl is-active --quiet NetworkManager; then
      echo "Modifying NetworkManager configuration..."
      # Here you would typically use nmcli to modify the connection
      connection_name=$(nmcli -t -f NAME con show | head -n 1)  # Get the first connection name
      nmcli con mod "$connection_name" ipv4.addresses "$new_ip/$new_netmask"
      nmcli con mod "$connection_name" ipv4.gateway "$new_gateway"
      nmcli con up "$connection_name"
      echo "Configuration updated."
    else
      echo "No recognized network management service is running. Cannot modify configuration."
    fi
  else
    echo "No changes made to the network configuration."
  fi

  echo "Network configuration process completed."
  echo
}

# Call the step5 function to test it
step5

# Define colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
NC="\033[0m"              # Reset color

# Step 5: IP Configuration
step5() {
  echo -e "\n${GRAY_BLUE}=== Step 5: IP Configuration ===${NC}"

  # Ask if the network configuration has already been done
  read -p "Has the network configuration already been done? (Y/n): " config_done
  config_done=${config_done,,}  # Normalize to lowercase

  if [[ "$config_done" == "y" || "$config_done" == "yes" ]]; then
    echo "Network configuration has already been completed. Exiting step 5."
    return 0
  fi

  # Proceed to ask for IP configuration details
  echo "You will now enter the IP configuration details."

  read -p "Network interface (e.g., eth0): " IP_Interface
  read -p "IP Address (e.g., 192.168.1.100): " IP_Address
  read -p "Netmask (e.g., /24): " Netmask
  read -p "Gateway: " Gateway
  read -p "Primary DNS: " DNS_Primary
  read -p "Secondary DNS: " DNS_Secondary

  # Simple validation of user input
  if ! [[ "$IP_Interface" =~ ^[a-z0-9]+$ && "$IP_Address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid entries, please try again."
    return 1
  fi

  echo "Configuration details:"
  echo "Interface: $IP_Interface"
  echo "IP Address: $IP_Address"
  echo "Netmask: $Netmask"
  echo "Gateway: $Gateway"
  echo "Primary DNS: $DNS_Primary"
  echo "Secondary DNS: $DNS_Secondary"

  # Here you can add the logic to apply the configuration to dhcpcd.conf or other relevant files
  echo "Applying the configuration..."
  echo -e "\n# Custom configuration added by script" >> /etc/dhcpcd.conf
  echo "interface $IP_Interface" >> /etc/dhcpcd.conf
  echo "static ip_address=$IP_Address$Netmask" >> /etc/dhcpcd.conf
  echo "static routers=$Gateway" >> /etc/dhcpcd.conf
  echo "static domain_name_servers=$DNS_Primary $DNS_Secondary" >> /etc/dhcpcd.conf

  # Restart dhcpcd service to apply changes
  echo "Restarting dhcpcd service..."
  sudo systemctl restart dhcpcd

  echo "IP configuration process completed."
  echo
}

# Call the step5 function to test it
step5

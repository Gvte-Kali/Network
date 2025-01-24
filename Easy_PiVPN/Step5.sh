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

  # Offer to detect current configuration or enter manually
  read -p "Do you want to detect the current network configuration? (Y/n): " detect_choice
  detect_choice=${detect_choice,,}  # Normalize to lowercase

  if [[ "$detect_choice" == "y" || "$detect_choice" == "yes" ]]; then
    echo "Detecting current network configuration..."
    # Here you can implement logic to detect the current configuration
    # For demonstration, we will just prompt for manual input
  fi

  # Prompt for manual input
  while true; do
    read -p "Enter IP Address (e.g., 192.168.1.100): " IP_Address
    if [[ "$IP_Address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
    else
      echo "Invalid IP address format. Please try again."
    fi
  done

  while true; do
    read -p "Enter Netmask (e.g., /24): " Netmask
    if [[ "$Netmask" =~ ^/[0-9]+$ ]]; then
      break
    else
      echo "Invalid netmask format. Please use the format /N (e.g., /24)."
    fi
  done

  while true; do
    read -p "Enter Gateway (e.g., 192.168.1.1): " Gateway
    if [[ "$Gateway" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
    else
      echo "Invalid gateway format. Please try again."
    fi
  done

  while true; do
    read -p "Enter Primary DNS (e.g., 8.8.8.8): " DNS_Primary
    if [[ "$DNS_Primary" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
    else
      echo "Invalid DNS format. Please try again."
    fi
  done

  while true; do
    read -p "Enter Secondary DNS (e.g., 8.8.4.4): " DNS_Secondary
    if [[ "$DNS_Secondary" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      break
    else
      echo "Invalid DNS format. Please try again."
    fi
  done

  # Show the configuration to be applied
  echo -e "\n${LIGHT_BLUE}Configuration to be applied:${NC}"
  echo "IP Address: $IP_Address"
  echo "Netmask: $Netmask"
  echo "Gateway: $Gateway"
  echo "Primary DNS: $DNS_Primary"
  echo "Secondary DNS: $DNS_Secondary"

  # Confirm with the user
  read -p "Do you want to apply this configuration? (Y/n): " apply_choice
  apply_choice=${apply_choice,,}  # Normalize to lowercase

  if [[ "$apply_choice" == "y" || "$apply_choice" == "yes" ]]; then
    # Apply the configuration to dhcpcd.conf
    echo -e "\n# Custom configuration added by script" >> /etc/dhcpcd.conf
    echo "interface eth0" >> /etc/dhcpcd.conf  # Change 'eth0' to your actual interface name
    echo "static ip_address=$IP_Address$Netmask" >> /etc/dhcpcd.conf
    echo "static routers=$Gateway" >> /etc/dhcpcd.conf
    echo "static domain_name_servers=$DNS_Primary $DNS_Secondary" >> /etc/dhcpcd.conf

    # Restart dhcpcd service to apply changes
    echo "Restarting dhcpcd service..."
    sudo systemctl restart dhcpcd

    echo "IP configuration process completed."
  else
    echo "Configuration not applied. You can re-enter the details if needed."
  fi

  echo
}

# Call the step5 function to test it
step5

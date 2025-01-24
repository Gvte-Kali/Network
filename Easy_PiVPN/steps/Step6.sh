# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"   


# Step 6: Apply the configuration to the /etc/dhcpcd.conf file
step6() {
clear
  echo -e "\n${GRAY_BLUE}=== Step 6: Apply IP Configuration ===${NC}"

  # Display a summary of the configuration
  echo "Network Configuration Summary:"
  echo "Interface: $IP_Interface"
  echo "IP Address: $IP_Address$Netmask"
  echo "Gateway: $Gateway"
  echo "Primary DNS: $DNS_Primary"
  echo "Secondary DNS: $DNS_Secondary"

  # Prompt the user to confirm applying the configuration
  PS3="Do you want to apply this network configuration? "
  options=("Yes, apply configuration" "No, cancel configuration")
  
  select opt in "${options[@]}"
  do
    case $opt in
      "Yes, apply configuration")
        # Apply the configuration
        echo "Applying network configuration..."
        
        # Append the configuration to the dhcpcd.conf file
        sudo bash -c "echo -e '\n# Static network configuration\ninterface $IP_Interface\nstatic ip_address=$IP_Address$Netmask\nstatic routers=$Gateway\nstatic domain_name_servers=$DNS_Primary $DNS_Secondary' >> /etc/dhcpcd.conf"
        
        # Restart the dhcpcd service
        sudo systemctl restart dhcpcd
        
        echo "Configuration successfully applied and service restarted."
        return 0
        ;;
      
      "No, cancel configuration")
        echo "Network configuration cancelled."
        return 1
        ;;
      
      *) 
        echo "Invalid option. Please select 1 or 2."
        continue
        ;;
    esac
  done
}

step6

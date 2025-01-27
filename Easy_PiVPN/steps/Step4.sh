# Define colors
GRAY_BLUE="\033[1;34m"    # 
LIGHT_BLUE="\033[1;36m"   # 
RED="\033[1;31m"          # Red
GREEN="\033[1;32m"        # Green
YELLOW="\033[1;33m"       # Yellow
NC="\033[0m"              # Reset color

# Step 4: Display detailed network information and check network configuration
step4() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 4: Network Information ===${NC}"
  
  # Test network connectivity
  if ping -c 4 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}Network connectivity is working.${NC}"
    
    # Display network interfaces details
    ip -br addr | while read -r interface status ip_info; do
      # Extracting the IP address and subnet mask
      ip_address=$(echo "$ip_info" | cut -d'/' -f1)
      netmask=$(echo "$ip_info" | cut -d'/' -f2)
      
      # Retrieving the gateway
      gateway=$(ip route | grep default | awk '{print $3}')
      
      # Retrieving the DNS servers
      dns_servers=$(grep -m 1 '^nameserver' /etc/resolv.conf | awk '{print $2}')
      
      # Formatted output
      echo -e "${LIGHT_BLUE}Interface${NC}   : $interface"
      echo -e "IP Address${NC} : $ip_address/$netmask"
      echo -e "Gateway${NC}    : $gateway"
      echo -e "DNS       : $dns_servers"
      echo "---"
    done
    
    # Prompt to skip steps 5 and 6
    echo -e "${YELLOW}Existing network configuration detected.${NC}"
    echo "Do you want to skip IP configuration steps (5 and 6)?"
    
    PS3="Choose an option: "
    options=("Yes, skip IP configuration" "No, proceed with IP configuration")
    
    select opt in "${options[@]}"; do
      case $opt in
        "Yes, skip IP configuration")
          echo "Skipping steps 5 and 6."
          i=7  # Increment i to skip to step 7
          return 0  # Successfully skip the steps
          ;;
        "No, proceed with IP configuration")
          # Continue with steps 5 and 6
          break
          ;;
        *) 
          echo "Invalid option. Please select 1 or 2."
          continue
          ;;
      esac
    done
  else
    echo -e "${RED}No network connectivity detected.${NC}"
    echo "You will need to configure network settings."
    # Optionally, add a pause or wait for user input
    read -p "Press Enter to continue with network configuration..."
  fi
}

# Call the step4 function to execute it
step4

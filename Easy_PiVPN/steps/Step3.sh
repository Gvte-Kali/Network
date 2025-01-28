# Define colors
GRAY_BLUE="\033[1;34m"    # 
LIGHT_BLUE="\033[1;36m"   # 
RED="\033[1;31m"          # Red
GREEN="\033[1;32m"        # Green
YELLOW="\033[1;33m"       # Yellow
NC="\033[0m"              # Reset color

# Step 3: Display detailed network information and check network configuration
step3() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 3: Network Information ===${NC}"
  
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
    
    echo "================================================="
    echo ""
    echo -e "${YELLOW}Existing network configuration detected.${NC}"
    echo "You can proceed to the next step."
  else
    echo "================================================="
    echo ""
    echo -e "${RED}No network connectivity detected.${NC}"
    echo "You will need to configure network settings."
    # Optionally, add a pause or wait for user input
    read -p "Press Enter to continue with network configuration..."
  fi
}

# Call the step4 function to execute it
step3

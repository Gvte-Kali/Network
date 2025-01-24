# Define colors
GRAY_BLUE="\033[1;34m"    # 
LIGHT_BLUE="\033[1;36m"   # 
NC="\033[0m"              # Reset color

# Step 4: Display detailed network information
step4() {
  echo -e "\n${GRAY_BLUE}=== Step 4: Network Information ===${NC}"
  
  # Using the ip command and resolvconf command to retrieve information
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
    echo -e "Gateway${NC} : $gateway"
    echo -e "DNS       : $dns_servers"
    echo "---"
  done
  
  echo
}

step4

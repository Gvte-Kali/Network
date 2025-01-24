# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"

# Step 5: Request IP configuration from the user
step5() {
  echo -e "\n${GRAY_BLUE}=== Step 5: IP Configuration ===${NC}"
  read -p "Network interface (e.g., eth0): " IP_Interface
  read -p "IP Address (e.g., 192.168.1.100): " IP_Address
  read -p "Netmask (e.g., /24): " Netmask
  read -p "Gateway: " Gateway
  read -p "Primary DNS: " DNS_Primary
  read -p "Secondary DNS: " DNS_Secondary

  # User input validation (basic verification)
  if ! [[ "$IP_Interface" =~ ^[a-z0-9]+$ && "$IP_Address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid entries, please try again."
    return 1
  fi
  echo
}

step5

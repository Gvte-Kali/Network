# Define colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
NC="\033[0m"              # Reset color

step5() {
    echo -e "\n${GRAY_BLUE}=== Step 5: IP Configuration ===${NC}"
    
    # Check if network configuration already exists
    read -p "Have you already configured the network? (y/n): " network_config_exists
    
    if [[ "$network_config_exists" =~ ^[Yy]$ ]]; then
        echo "Existing network configuration. Ending IP configuration."
        return 0
    fi

    # Request IP configuration if no existing configuration
    read -p "Network interface (e.g., eth0): " IP_Interface
    read -p "IP Address (e.g., 192.168.1.100): " IP_Address
    read -p "Netmask (e.g., /24): " Netmask
    read -p "Gateway: " Gateway
    read -p "Primary DNS: " DNS_Primary
    read -p "Secondary DNS: " DNS_Secondary

    # User input validation (basic verification)
    if ! [[ "$IP_Interface" =~ ^[a-z0-9]+$ && "$IP_Address" =~ ^[0-9]+.[0-9]+.[0-9]+.[0-9]+$ ]]; then
        echo "Invalid entries, please try again."
        return 1
    fi

    echo "Configuring IP..."
    # Add network configuration commands here
}

# Call the step5 function to test it
step5

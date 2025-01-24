# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"

network_configuration() {
    clear
    echo -e "${GRAY_BLUE}=== Network Configuration ===${NC}"

    # Check if network configuration already exists
    if ip route | grep -q default; then
        echo -e "${LIGHT_BLUE}Existing network configuration detected.${NC}"
        echo "No additional configuration required."
        return 0
    fi

    # No network configuration, propose configuration
    echo -e "${LIGHT_BLUE}No network configuration detected.${NC}"
    echo "Would you like to configure the network automatically?"
    
    PS3="Choose an option: "
    options=("Automatic DHCP Configuration" "Manual Configuration" "Cancel")
    
    select opt in "${options[@]}"
    do
        case $opt in
            "Automatic DHCP Configuration")
                echo "Configuring network via DHCP..."
                # Find active network interface
                interface=$(ip -br link show | grep -v "lo" | awk '{print $1}' | head -n1)
                
                if [ -z "$interface" ]; then
                    echo "No network interface found."
                    return 1
                fi
                
                # DHCP configuration
                dhclient "$interface"
                
                # Verify configuration
                if ip route | grep -q default; then
                    echo "DHCP configuration successful on $interface"
                    return 0
                else
                    echo "DHCP configuration failed"
                    return 1
                fi
                ;;
            
            "Manual Configuration")
                echo "Manual configuration not implemented in this version."
                return 1
                ;;
            
            "Cancel")
                echo "Network configuration cancelled."
                return 1
                ;;
            
            *) 
                echo "Invalid option"
                ;;
        esac
    done
}

# Direct execution if script is called
network_configuration

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
network_configuration#!/bin/bash

# Define colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
NC="\033[0m"              # Reset color

step5() {
    clear
    echo -e "${GRAY_BLUE}=== Step 5: IP Configuration ===${NC}"
    
    # Network configuration options
    PS3="${LIGHT_BLUE}Have you already configured the network? Choose an option: ${NC}"
    options=("Yes, network is already configured" "No, I want to configure network" "Cancel")
    
    select opt in "${options[@]}"
    do
        case $opt in
            "Yes, network is already configured")
                echo "Existing network configuration. Ending IP configuration."
                return 0
                ;;
            "No, I want to configure network")
                break
                ;;
            "Cancel")
                echo "Operation cancelled."
                return 1
                ;;
            *) 
                echo "Invalid option. Please select 1-3."
                continue
                ;;
        esac
    done

    # IP Configuration inputs with enhanced validation
    while true; do
        read -p "Network interface (e.g., eth0): " IP_Interface
        if [[ "$IP_Interface" =~ ^[a-z0-9]+$ ]]; then
            break
        else
            echo "Invalid interface name. Use only lowercase letters and numbers."
        fi
    done

    while true; do
        read -p "IP Address (e.g., 192.168.1.100): " IP_Address
        if [[ "$IP_Address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            # Validate IP address range
            IFS='.' read -r i1 i2 i3 i4 <<< "$IP_Address"
            if (( i1 >= 0 && i1 <= 255 && 
                  i2 >= 0 && i2 <= 255 && 
                  i3 >= 0 && i3 <= 255 && 
                  i4 >= 0 && i4 <= 255 )); then
                break
            fi
        fi
        echo "Invalid IP address. Please use a valid IP format (0.0.0.0 to 255.255.255.255)."
    done

    while true; do
        read -p "Netmask (e.g., /24): " Netmask

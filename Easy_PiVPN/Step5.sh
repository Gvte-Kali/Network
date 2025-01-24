#!/bin/bash

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
        if [[ "$Netmask" =~ ^/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
            break
        else
            echo "Invalid netmask. Use CIDR notation like /24."
        fi
    done

    while true; do
        read -p "Gateway: " Gateway
        if [[ "$Gateway" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            # Optional: Add more specific gateway validation if needed
            break
        else
            echo "Invalid gateway IP address."
        fi
    done

    while true; do
        read -p "Primary DNS: " DNS_Primary
        if [[ "$DNS_Primary" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            echo "Invalid DNS IP address."
        fi
    done

    while true; do
        read -p "Secondary DNS: " DNS_Secondary
        if [[ "$DNS_Secondary" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            echo "Invalid DNS IP address."
        fi
    done

    # Confirmation step
    echo -e "\n${LIGHT_BLUE}Network Configuration Summary:${NC}"
    echo "Interface: $IP_Interface"
    echo "IP Address: $IP_Address$Netmask"
    echo "Gateway: $Gateway"
    echo "DNS (Primary): $DNS_Primary"
    echo "DNS (Secondary): $DNS_Secondary"

    # Prompt for final confirmation
    read -p "Confirm network configuration? (y/n): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        echo "Configuration cancelled."
        return 1
    fi

    echo "Configuring IP..."
    # Add actual network configuration commands here
    # For example:
    # sudo ip addr add "$IP_Address$Netmask" dev "$IP_Interface"
    # sudo ip route add default via "$Gateway"
    # echo "nameserver $DNS_Primary" | sudo tee /etc/resolv.conf
    # echo "nameserver $DNS_Secondary" | sudo tee -a /etc/resolv.conf

    return 0
}

# Call the step5 function to test it
step5

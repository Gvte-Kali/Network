step5() {
    clear  # Clear screen for better visibility
    
    # Priority request for existing network configuration
    while true; do
        echo -e "${GRAY_BLUE}=== Step 5: IP Configuration ===${NC}"
        read -p "Have you already configured the network? (y/n): " network_config_exists
        
        # Convert to lowercase for flexibility
        network_config_exists=$(echo "$network_config_exists" | tr '[:upper:]' '[:lower:]')
        
        # Debugging output
        echo "Debug: You entered '$network_config_exists'"

        # Response validation
        case "$network_config_exists" in
            y|yes)
                echo "Existing network configuration. Ending IP configuration."
                return 0
                ;;
            n|no)
                break  # Exit loop to continue configuration
                ;;
            *)
                echo "Invalid input. Please answer with 'y' or 'n'."
                sleep 1  # Small delay to see the message
                clear
                ;;
        esac
    done

    # Remaining IP configuration
    read -p "Network interface (e.g., eth0): " IP_Interface
    read -p "IP Address (e.g., 192.168.1.100): " IP_Address
    read -p "Netmask (e.g., /24): " Netmask
    read -p "Gateway: " Gateway
    read -p "Primary DNS: " DNS_Primary
    read -p "Secondary DNS: " DNS_Secondary

    # Interface and IP address validation
    if ! [[ "$IP_Interface" =~ ^[a-z0-9]+$ ]] || ! [[ "$IP_Address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "Invalid entries, please try again."
        return 1
    fi

    # Additional validation for IP address range
    IFS='.' read -r i1 i2 i3 i4 <<< "$IP_Address"
    if (( i1 < 0 || i1 > 255 || i2 < 0 || i2 > 255 || i3 < 0 || i3 > 255 || i4 < 0 || i4 > 255 )); then
        echo "Invalid IP Address range, please try again."
        return 1
    fi

    echo "Configuring IP..."
    # Add network configuration commands here
}

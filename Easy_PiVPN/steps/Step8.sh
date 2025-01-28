# Define colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
RED="\033[1;31m"          # Red
GREEN="\033[1;32m"        # Green
YELLOW="\033[1;33m"       # Yellow
MAGENTA="\033[1;35m"      # Magenta
CYAN="\033[1;36m"         # Cyan
WHITE="\033[1;37m"        # White
NC="\033[0m"              # Reset color

# Step 8: NAT Configuration and Network Access
step8() {
    clear
    echo -e "\n${CYAN}=== NAT configuration on Router ===${NC}"

    # Retrieve the username from /tmp/username.txt
    if [[ -f /tmp/username.txt ]]; then
        username=$(cat /tmp/username.txt)
    else
        echo "Error: /tmp/username.txt not found. Please run the username script first."
        return 1
    fi

    # Define the vpn_config directory path
    vpn_config_dir="/home/$username/vpn_config"
    
    # Identify network gateways
    echo -e "${BLUE}Detecting network gateways...${NC}"
    mapfile -t gateways < <(ip route | grep default)
    
    if [[ ${#gateways[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No network gateway detected.${NC}"
        return 1
    fi
    
    # Retrieve the gateway IP address and main interface
    gateway_ip=$(ip route | grep default | awk '{print $3}' | head -n 1)
    main_interface=$(ip route | grep default | awk '{print $5}' | head -n 1)
    local_ip=$(ip addr show "$main_interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    
    # Detect VPN port
    vpn_port=""
    vpn_type=""
    
    # Check Wireguard first
    wireguard_config_files=(
        "/etc/wireguard/"*".conf"
        "/home/$username/"*".conf"
        "/etc/wireguard/wg0.conf"
    )
    
    for config in "${wireguard_config_files[@]}"; do
        if [[ -f "$config" ]]; then
            vpn_port=$(grep -m 1 "ListenPort" "$config" | awk '{print $3}')
            if [[ -n "$vpn_port" ]]; then
                vpn_type="Wireguard"
                break
            fi
        fi
    done
    
    # If Wireguard fails, check OpenVPN
    if [[ -z "$vpn_port" ]]; then
        vpn_port=$(grep "port " /etc/openvpn/server.conf 2>/dev/null | awk '{print $2}')
        if [[ -n "$vpn_port" ]]; then
            vpn_type="OpenVPN"
        fi
    fi
    
    # Default port if not found
    if [[ -z "$vpn_port" ]]; then
        vpn_port="51820"  # Default Wireguard port
        vpn_type="Wireguard (default)"
        echo -e "${YELLOW}Default VPN port used: $vpn_port${NC}"
    fi
    
    # Display configuration information
    echo -e "\n${BLUE}Configuration Information:${NC}"
    echo "Gateway        : $gateway_ip"
    echo "Interface      : $main_interface"
    echo "Local IP       : $local_ip"
    echo "VPN Type       : $vpn_type"
    echo "VPN Port       : $vpn_port"
    
    # Ask for mode (Graphical or Headless)
    echo -e "\n${LIGHT_BLUE}Select your mode:${NC}"
    echo "1 --> Graphical Mode"
    echo "2 --> Headless Mode"
    read -p "Choose an option (1 or 2): " mode_choice

    if [[ "$mode_choice" -eq 1 ]]; then
        # Graphical mode: Open router interface
        echo -e "\n${CYAN}Opening router's web interface...${NC}"
        read -p "Press Enter to open the router's web interface..." 
        xdg-open "http://$gateway_ip" 2>/dev/null
        
        # Validate NAT configuration
        while true; do
            read -p "Have you configured the NAT rule on the router? (Y/n) : " nat_config
            
            case "${nat_config,,}" in
                y|"")
                    echo "NAT configuration confirmed."
                    break
                    ;;
                n)
                    echo "Please configure the NAT rule before continuing."
                    read -p "Press Enter to try again..."
                    xdg-open "http://$gateway_ip" 2>/dev/null
                    ;;
                *)
                    echo "Invalid response. Use Y or N."
                    ;;
            esac
        done
    else
        # Headless mode: Provide instructions
        echo -e "\n${CYAN}Please configure the NAT rule on your router manually using the following instructions:${NC}"
        echo "1. Access your router's web interface by entering the following URL in your browser: http://$gateway_ip"
        echo "2. Navigate to the port forwarding settings."
        echo "3. Create a new forwarding rule:"
        echo "   - External port : $vpn_port"
        echo "   - Internal port  : $vpn_port"
        echo "   - Internal IP    : $local_ip"
        echo "   - Protocol       : UDP"
        
        # Wait for user confirmation
        while true; do
            read -p "Have you configured the NAT rule on the router? (Y/n) : " nat_config
            
            case "${nat_config,,}" in
                y|"")
                    echo "NAT configuration confirmed."
                    break
                    ;;
                n)
                    echo "Please configure the NAT rule before continuing."
                    ;;
                *)
                    echo "Invalid response. Use Y or N."
                    ;;
            esac
        done
    fi
    
    # Save configuration information
    mkdir -p "/home/$username/vpn_config"
    cat > "/home/$username/vpn_config/nat_port_forwarding" << EOL
GATEWAY_IP=$gateway_ip
MAIN_INTERFACE=$main_interface
LOCAL_IP=$local_ip
VPN_TYPE=$vpn_type
VPN_PORT=$vpn_port
EOL
    echo
    echo "Information saved in /home/$username/vpn_config/nat_port_forwarding"
    echo 
    echo -e "\n${LIGHT_BLUE}NAT configuration complete.${NC}"
    echo

    # Ask the user if they want to reboot
    echo "Setup is done, we recommend to reboot now and launch this program again."
    read -p "Do you want to reboot the computer now? (Y/n): " reboot_choice
    case "${reboot_choice,,}" in
        y|"")
            echo "Rebooting the computer..."
            sudo reboot
            ;;
        n)
            echo "You chose not to reboot."
            ;;
        *)
            echo "Invalid choice. No reboot will be performed."
            ;;
    esac
}

step8

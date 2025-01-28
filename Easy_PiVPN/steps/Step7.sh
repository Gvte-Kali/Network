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

# Step 7: Routing and NAT Configuration between VPN and Physical Network
step7() {
    clear
    echo -e "\n${GRAY_BLUE}=== Routing and NAT configuration for VPN to LAN tunnel ===${NC}"
    echo ""
    echo ""

    # Identify network interfaces
    interfaces=($(ip -o -f inet addr show | awk '{print $2}'))
    echo -e "${YELLOW}Available network interfaces:${NC}"
    for i in "${!interfaces[@]}"; do
        echo "$((i + 1)). ${interfaces[i]}"
    done

    # Select LAN interface
    read -p "Select the LAN interface (number): " lan_choice
    LAN_INTERFACE="${interfaces[$((lan_choice - 1))]}"
    
    # Identify OpenVPN interface
    VPN_INTERFACE="tun0"  # Default for OpenVPN
    VPN_NETWORK="10.8.0.0/24"  # Default OpenVPN IP range

    # Enable IP forwarding
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sed -i 's/#*net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf

    # Configure iptables for NAT
    sudo iptables -t nat -A POSTROUTING -s "$VPN_NETWORK" -o "$LAN_INTERFACE" -j MASQUERADE
    sudo iptables -A FORWARD -i "$VPN_INTERFACE" -o "$LAN_INTERFACE" -j ACCEPT
    sudo iptables -A FORWARD -i "$LAN_INTERFACE" -o "$VPN_INTERFACE" -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Display the current iptables rules
    echo -e "\n${LIGHT_BLUE}Current iptables rules:${NC}"
    sudo iptables -t nat -L -n -v
    echo
    sudo iptables -L -n -v
    echo

    # Display future rules based on user input
    echo -e "\n${LIGHT_BLUE}Future rules to be created:${NC}"
    echo "1. NAT rule: POSTROUTING - MASQUERADE for $VPN_NETWORK on $LAN_INTERFACE"
    echo "2. FORWARD rule: Allow traffic from $VPN_INTERFACE to $LAN_INTERFACE"
    echo "3. FORWARD rule: Allow established/related traffic from $LAN_INTERFACE to $VPN_INTERFACE"

    # Ask for confirmation to apply the rules
    echo
    echo
    read -p "Do you want to apply these rules? (Y/n): " apply_choice
    if [[ ! "$apply_choice" =~ ^[Yy]$ ]]; then
        echo "Configuration not applied. Exiting."
        return 0
    fi

    # Save the rules
    sudo apt-get install -y iptables-persistent
    sudo netfilter-persistent save

    echo -e "${GREEN}Configuration complete. LAN access from OpenVPN enabled.${NC}"
}

step7

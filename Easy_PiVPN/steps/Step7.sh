#!/bin/bash

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

    # Configure firewall to allow OpenVPN traffic
    echo -e "${YELLOW}Configuring firewall...${NC}"
    sudo ufw allow 1194/udp

    # Enable IP forwarding
    echo -e "${YELLOW}Enabling IP forwarding...${NC}"
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

    # Modify /etc/sysctl.conf to make IP forwarding permanent
    echo -e "${YELLOW}Configuring permanent IP forwarding...${NC}"

    # Check if the line exists in the file
    if grep -q "^[#]*net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        # If the line exists and is commented, uncomment it
        sudo sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    else
        # If the line does not exist, append it to the file
        echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
    fi

    # Apply changes
    sudo sysctl -p

    # Add iptables rules for NAT
    echo -e "${YELLOW}Configuring iptables rules for NAT...${NC}"
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    sudo iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT
    sudo iptables -A FORWARD -i eth0 -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT

    # Install iptables-persistent to make iptables rules persistent
    echo -e "${YELLOW}Installing iptables-persistent...${NC}"
    sudo apt install iptables-persistent -y

    # Save current iptables rules
    echo -e "${YELLOW}Saving iptables rules...${NC}"
    sudo netfilter-persistent save
    sudo netfilter-persistent reload

    echo -e "${GREEN}Configuration completed successfully.${NC}"
}

# Call the function to execute the steps
step7

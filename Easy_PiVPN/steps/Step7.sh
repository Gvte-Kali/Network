#!/bin/bash

# Define colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
NC="\033[0m"

# Step 7: Routing and NAT Configuration between VPN and Physical Network
step7() {
    # Check for root privileges
    if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
    fi

    # Function to detect network interfaces
    detect_interfaces() {
        INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
    }

    # Function to get network info for an interface
    get_network_info() {
        local iface=$1
        IP_INFO=$(ip -o -4 addr show dev $iface | awk '{print $4}')
        IP_ADDR=$(echo $IP_INFO | cut -d'/' -f1)
        PREFIX=$(echo $IP_INFO | cut -d'/' -f2)

        # Calculate the netmask
        case $PREFIX in
            8) MASK="255.0.0.0";;
            16) MASK="255.255.0.0";;
            24) MASK="255.255.255.0";;
            32) MASK="255.255.255.255";;
            *) MASK="255.255.255.0";;
        esac

        NETWORK=$(ip route | grep "dev $iface" | grep -v default | awk '{print $1}' | head -n1)
        GATEWAY=$(ip route | grep "default via" | grep "dev $iface" | awk '{print $3}')
    }

    # Initial detection
    detect_interfaces

    # Menu for selecting LAN interface
    LAN_IFACE=$(whiptail --title "Select LAN Interface" --menu \
    "Choose the interface connected to your local network:" 20 60 10 \
    $(for i in "${INTERFACES[@]}"; do
        get_network_info "$i"
        echo "$i" "$IP_ADDR/$PREFIX ($NETWORK)"
    done) 3>&1 1>&2 2>&3)

    [ -z "$LAN_IFACE" ] && exit 1

    # Menu for selecting VPN interface
    VPN_IFACE=$(whiptail --title "Select VPN Interface" --menu \
    "Choose the interface for the VPN (usually tun0):" 20 60 10 \
    $(for i in "${INTERFACES[@]}"; do
        echo "$i" "$(ip -o -4 addr show dev $i 2>/dev/null | awk '{print $4}' || echo 'Not configured')"
    done) 3>&1 1>&2 2>&3)

    [ -z "$VPN_IFACE" ] && exit 1

    # Get network info
    get_network_info "$LAN_IFACE"

    # Display confirmation
    whiptail --title "Summary" --msgbox \
    "Selected Configuration:
    - LAN Interface: $LAN_IFACE
    - IP Address: $IP_ADDR/$PREFIX
    - Network: $NETWORK
    - Netmask: $MASK
    - Gateway: ${GATEWAY:-Not detected}
    - VPN Interface: $VPN_IFACE" 20 60

    # Configure NAT
    configure_nat() {
        echo -e "${YELLOW}Configuring firewall...${NC}"
        sudo ufw allow 1194/udp

        echo -e "${YELLOW}Enabling IP forwarding...${NC}"
        echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

        echo -e "${YELLOW}Configuring permanent IP forwarding...${NC}"
        if grep -q "^[#]*net.ipv4.ip_forward=1" /etc/sysctl.conf; then
            sudo sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
        else
            echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
        fi

        sudo sysctl -p

        echo -e "${YELLOW}Configuring iptables rules for NAT...${NC}"
        sudo iptables -t nat -F
        sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $LAN_IFACE -j MASQUERADE
        sudo iptables -A FORWARD -i $VPN_IFACE -o $LAN_IFACE -j ACCEPT
        sudo iptables -A FORWARD -i $LAN_IFACE -o $VPN_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
        sudo iptables -A FORWARD -i $VPN_IFACE ! -d $NETWORK -j DROP

        echo -e "${YELLOW}Installing iptables-persistent...${NC}"
        sudo apt install iptables-persistent -y

        echo -e "${YELLOW}Saving iptables rules...${NC}"
        sudo netfilter-persistent save
        sudo netfilter-persistent reload
    }

    # Configure OpenVPN
    configure_openvpn() {
        # Replace the dev line with the selected VPN interface
        sudo sed -i "s/^dev .*/dev $VPN_IFACE/" /etc/openvpn/server.conf

        # Remove any existing route push directives
        sudo sed -i "/^push \"route /d" /etc/openvpn/server.conf

        # Add the new route push directive
        echo "push \"route $NETWORK $MASK\"" | sudo tee -a /etc/openvpn/server.conf

        # Restart OpenVPN to apply changes
        sudo systemctl restart openvpn
    }

    # Execution
    if (whiptail --title "Confirmation" --yesno "Apply this configuration?" 10 60); then
        configure_nat
        configure_openvpn
        whiptail --title "Success" --msgbox "Configuration applied successfully!" 10 60
    else
        whiptail --title "Cancelled" --msgbox "No changes were applied." 10 60
    fi
}

# Call the function to execute the steps
step7

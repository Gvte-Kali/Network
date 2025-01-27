#!/bin/bash

# Retrieve the username from cron_user.txt or use the passed environment variable
if [[ -n "$USERNAME" ]]; then
    username="$USERNAME"
elif [[ -f /home/*/vpn_config/cron_user.txt ]]; then
    username=$(cat /home/*/vpn_config/cron_user.txt)
else
    echo "Unable to determine username" >> "/home/$username/vpn_config/ip_change_log.txt"
    exit 1
fi

# Configuration file paths
OPENVPN_CONFIG="/etc/openvpn/server/server.conf"
CLIENT_CONFIGS_DIR="/home/$username/ovpns"
VPN_CONFIG_DIR="/home/$username/vpn_config"
LOG_FILE="$VPN_CONFIG_DIR/ip_change_log.txt"
PUBLIC_IP_FILE="$VPN_CONFIG_DIR/public_ip.txt"
TEMP_CONFIG_DIR=$(mktemp -d)


# Function to obtain public IPv4 address
get_ipv4() {
    local ipv4_methods=(
        "curl -4 -s ifconfig.me"
        "curl -4 -s ipv4.icanhazip.com"
        "curl -4 -s ipinfo.io/ip"
        "dig +short myip.opendns.com @resolver1.opendns.com"
    )
    
    for method in "${ipv4_methods[@]}"; do
        local ip=$(${method})
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    return 1
}

# Function to send a message to Discord
send_discord_message() {
    local message="$1"
    local webhook_file="${DISCORD_WEBHOOK_FILE:-$VPN_CONFIG_DIR/discord_webhook.txt}"
    local file_path="$2"

    if [ -f "$webhook_file" ]; then
        local discord_webhook=$(cat "$webhook_file")
        
        if [ -n "$file_path" ] && [ -f "$file_path" ]; then
            # Send with file
            curl -F "payload_json={\"content\":\"$message\"}" \
                 -F "file=@$file_path" \
                 "$discord_webhook"
        else
            # Simple message send
            curl -X POST "$discord_webhook" \
                 -H "Content-Type: application/json" \
                 -d "{\"content\":\"$message\"}"
        fi
    fi
}
# Retrieve current public IPv4 address
current_public_ip=$(get_ipv4)

# If unable to get IP address, exit silently
if [ -z "$current_public_ip" ]; then
    exit 1
fi

# Check if the IP has changed
if [ -f "$PUBLIC_IP_FILE" ]; then
    previous_ip=$(cat "$PUBLIC_IP_FILE")
    
    # If IP hasn't changed, exit silently
    if [ "$current_public_ip" == "$previous_ip" ]; then
        exit 0
    fi
fi

# IP has changed - update configuration
{
    # Update PiVPN configuration files
    
    # 1. Update OpenVPN server configuration
    sudo sed -i "s/^remote .*/remote $current_public_ip/" "$OPENVPN_CONFIG"
    
    # 2. Update PiVPN specific configuration files
    
    # Check and update PiVPN setup configuration
    pivpn_setup_file="/etc/pivpn/setupVars.conf"
    if [ -f "$pivpn_setup_file" ]; then
        sudo sed -i "s/^PUBLICIP=.*/PUBLICIP=$current_public_ip/" "$pivpn_setup_file"
    fi
    
    # Some additional potential configuration files
    pivpn_config_files=(
        "/etc/pivpn/wireguard/setupVars.conf"
        "/etc/pivpn/openvpn/setupVars.conf"
    )
    
    for config_file in "${pivpn_config_files[@]}"; do
        if [ -f "$config_file" ]; then
            sudo sed -i "s/^PUBLICIP=.*/PUBLICIP=$current_public_ip/" "$config_file"
        fi
    done
    
    # Regenerate all client configurations
    sudo pivpn -r
    
    # Update public IP file
    echo "$current_public_ip" > "$PUBLIC_IP_FILE"
    
    # Prepare zip of new client configurations
    zip_file="$TEMP_CONFIG_DIR/vpn_user_configs.zip"
    zip -j "$zip_file" "$CLIENT_CONFIGS_DIR"/*.ovpn
    
    # Prepare Discord message
    message="🌐 Public IP Address Updated\n"
    message+="👤 User: $username\n"
    message+="📍 New IP Address: $current_public_ip\n"
    message+="📅 Date: $(date)\n"
    message+="📦 Updated VPN User Configurations Attached"
    
    # Send message and files to Discord
    send_discord_message "$message" "$zip_file"
    
    # Log the update
    echo "$(date): IP address updated to $current_public_ip" >> "$LOG_FILE"
} >> "$LOG_FILE" 2>&1

# Clean up temporary files
rm -rf "$TEMP_CONFIG_DIR"

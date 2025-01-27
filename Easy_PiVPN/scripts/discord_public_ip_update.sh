#!/bin/bash

# Retrieve the username from /tmp/username.txt
if [[ -f /tmp/username.txt ]]; then
    username=$(cat /tmp/username.txt) 
else
    echo "Error: /tmp/username.txt not found. Please run the username script first."
    return 1
fi

# Configuration file paths
OPENVPN_CONFIG="/etc/openvpn/server/server.conf"
CLIENT_CONFIGS_DIR="/home/$username/ovpns"
VPN_CONFIG_DIR="/home/$username/vpn_config"
LOG_FILE="$VPN_CONFIG_DIR/ip_change_log.txt"
PUBLIC_IP_FILE="$VPN_CONFIG_DIR/public_ip.txt"

# Create log directory if it doesn't exist
mkdir -p "$VPN_CONFIG_DIR"

# Function to obtain public IPv4 address
get_ipv4() {
    # Multiple methods to get IPv4
    local ipv4_methods=(
        "curl -4 -s ifconfig.me"
        "curl -4 -s ipv4.icanhazip.com"
        "curl -4 -s ipinfo.io/ip"
        "dig +short myip.opendns.com @resolver1.opendns.com"
    )
    
    for method in "${ipv4_methods[@]}"; do
        local ip=$(${method})
        # Basic IPv4 validation
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    echo "Unable to determine IPv4" >> "$LOG_FILE"
    return 1
}

# Function to send a message to Discord
send_discord_message() {
    local message="$1"
    local webhook_file="$VPN_CONFIG_DIR/discord_webhook.txt"

    if [ -f "$webhook_file" ]; then
        local discord_webhook=$(cat "$webhook_file")
        
        # Send simple message
        curl -X POST "$discord_webhook" \
             -H "Content-Type: application/json" \
             -d "{\"content\":\"$message\"}"
    else
        echo "$(date): Discord webhook file not found." >> "$LOG_FILE"
    fi
}

# Retrieve current public IPv4 address
current_public_ip=$(get_ipv4)

# If unable to get IP address, log and exit
if [ -z "$current_public_ip" ]; then
    cat > "$VPN_CONFIG_DIR/ip_update_log" << EOL
Update Date: $(date)
User: $username
New IP Address: Unable to retrieve
EOL
    echo "$(date): Unable to retrieve IP address." >> "$LOG_FILE"
    exit 1
fi

# Check if the IP has changed
if [ -f "$PUBLIC_IP_FILE" ]; then
    previous_ip=$(cat "$PUBLIC_IP_FILE")
    
    # If IP hasn't changed, exit
    if [ "$current_public_ip" == "$previous_ip" ]; then
        echo "$(date): IP address unchanged. No action needed." >> "$LOG_FILE"
        exit 0
    fi
fi

# IP has changed or is new - update the file
echo "$current_public_ip" > "$PUBLIC_IP_FILE"

# Send Discord notification about IP change
send_discord_message "🌐 New Public IP Address: $current_public_ip"

# Save update information
cat > "$VPN_CONFIG_DIR/ip_update_log" << EOL
Update Date: $(date)
User: $username
New IP Address: $current_public_ip
EOL

echo "$(date): IP address updated successfully." >> "$LOG_FILE"

# Colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
RED="\033[1;31m"          # Red
GREEN="\033[1;32m"        # Green
YELLOW="\033[1;33m"       # Yellow
MAGENTA="\033[1;35m"      # Magenta
CYAN="\033[1;36m"         # Cyan
WHITE="\033[1;37m"        # White
NC="\033[0m"              # Reset color


# Step 8: Discord Cronjob Configuration
step8() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 8: Discord Cronjob Configuration ===${NC}"

  # Retrieve the username from /tmp/username.txt
  if [[ -f /tmp/username.txt ]]; then
    username=$(cat /tmp/username.txt)
  else
    echo "Error: /tmp/username.txt not found. Please run the username script first."
    return 1
  fi

  # Define the vpn_config directory path
  vpn_config_dir="/home/$username/vpn_config"

  # Check if the vpn_config directory exists
  if [[ ! -d "$vpn_config_dir" ]]; then
    echo "Error: The directory $vpn_config_dir does not exist. Please create it first."
    return 1
  fi

  # Request information for Discord API
  echo -e "${LIGHT_BLUE}Configuring Discord Webhook Information${NC}"

  # Request Discord webhook URL
  while true; do
    read -p "Enter the Discord webhook URL: " discord_webhook

    # Simple URL validation
    if [[ "$discord_webhook" =~ ^https://discord.com/api/webhooks/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
      break
    else
      echo "Invalid webhook URL. Please enter a valid Discord webhook URL."
    fi
  done

  # Save webhook URL to a file
  mkdir -p "$vpn_config_dir"
  echo "$discord_webhook" > "$vpn_config_dir/discord_webhook.txt"

  # Create a wrapper script that downloads and executes the script each time
  wrapper_script="$vpn_config_dir/run_discord_ip_update.sh"

  cat > "$wrapper_script" << 'EOF'
#!/bin/bash

# Retrieve the username from cron_user.txt
if [[ -f /home/*/vpn_config/cron_user.txt ]]; then
    username=$(cat /home/*/vpn_config/cron_user.txt)
    vpn_config_dir="/home/$username/vpn_config"
else
    echo "Error: Unable to determine username" >&2
    exit 1
fi

# Download the script each execution
wget -O /tmp/update_pivpn_ip.sh "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/discord_public_ip_update.sh"

# Make the script executable
chmod +x /tmp/update_pivpn_ip.sh

# Execute the script with the webhook and username from the user's vpn_config directory
USERNAME="$username" DISCORD_WEBHOOK_FILE="$vpn_config_dir/discord_webhook.txt" /tmp/update_pivpn_ip.sh

# Remove the temporary script
rm /tmp/update_pivpn_ip.sh
EOF

  # Make the wrapper executable
  chmod +x "$wrapper_script"

  # Create a cronjob to run the wrapper every 10 minutes
  (crontab -l 2>/dev/null; echo "*/10 * * * * $wrapper_script") | crontab -

  echo -e "\n${LIGHT_BLUE}Cronjob configured to update public IP!${NC}"
  echo "The script will download and execute the update script every 10 minutes."
  echo "You can modify or remove this cronjob at any time."
  echo""
  read -p "$(echo -e "${LIGHT_BLUE}Press Enter to continue to the next step...${NC}")"
}

step8

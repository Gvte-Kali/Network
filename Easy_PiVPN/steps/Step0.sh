# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"

# Step 0: Preparing directories and configuration files
step0() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 0: Preparing directories ===${NC}"

  # Retrieve the username from /tmp/username.txt
  if [[ -f /tmp/username.txt ]]; then
    username=$(cat /tmp/username.txt)
  else
    echo "Error: /tmp/username.txt not found. Please run the username script first."
    return 1
  fi

  # Create the vpn_config and public_cron folders
  mkdir -p "/home/$username/vpn_config"

  # Create log and temporary files if necessary
  touch "/home/$username/vpn_config/install_log.txt"
  touch "/home/$username/vpn_config/temp_config.txt"

  # Retrieve the public IP address
  public_ip=$(curl -s ifconfig.me)
  echo "$public_ip" > "/home/$username/vpn_config/public_ip"

  echo "Directories and configuration files created."
  echo
}

# Call the step0 function
step0

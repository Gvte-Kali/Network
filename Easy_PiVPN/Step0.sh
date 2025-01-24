# Step 0: Preparing directories and configuration files
step0() {
  echo -e "\n${GRAY_BLUE}=== Step 0: Preparing directories ===${NC}"
  
  # Create the vpn_config and public_cron folders
  mkdir -p "$HOME/vpn_config"
  
  # Create log and temporary files if necessary
  touch "$HOME/vpn_config/install_log.txt"
  touch "$HOME/vpn_config/temp_config.txt"
  
  # Retrieve the public IP address
  public_ip=$(curl -s ifconfig.me)
  echo "$public_ip" > "$HOME/vpn_config/public_ip"

  echo "Directories and configuration files created."
  echo
}

step0

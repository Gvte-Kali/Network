# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"

# Step 0: Preparing directories and configuration files
step0() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 0: Preparing Directories ===${NC}"

  # Check dependencies
  dependencies=("curl" "wget" "jq")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      echo "Installing $dep..."
      sudo apt install -y "$dep"
    fi
  done

  # Retrieve the username from /tmp/username.txt
  if [[ -f /tmp/username.txt ]]; then
    username=$(cat /tmp/username.txt)
  else
    echo "Error: /tmp/username.txt not found. Please run the username script first."
    return 1
  fi

  # Create the vpn_config and public_cron folders
  mkdir -p "/home/$username/vpn_config"

  # Retrieve the public IPv4 address
  public_ip=$(curl -4 -s ifconfig.me)
  
  # Validate that the IP is an IPv4 address
  if [[ $public_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$public_ip" > "/home/$username/vpn_config/public_ip"
    echo "Public IPv4 address retrieved: $public_ip"
  else
    # Fallback method if the first method fails
    public_ip=$(curl -s https://ipv4.icanhazip.com)
    
    # Validate again
    if [[ $public_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$public_ip" > "/home/$username/vpn_config/public_ip"
      echo "Public IPv4 address retrieved: $public_ip"
    else
      echo "Error: Unable to retrieve a valid IPv4 address"
      return 1
    fi
  fi

  echo "Directories and configuration files created."
  echo
}

# Call the step0 function
step0

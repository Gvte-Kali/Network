# Define colors
GRAY_BLUE="\033[1;34m"    # Gray-blue color
LIGHT_BLUE="\033[1;36m"   # Light blue color
NC="\033[0m"              # Reset color

# Step 1: Update packages and install OpenVPN
step1() {
  clear
  echo -e "\n${GRAY_BLUE}=== Updating packages and installing OpenVPN ===${NC}"
  
  # Ask user if they want to update and upgrade packages
  read -p "${LIGHT_BLUE}Do you want to update and upgrade packages? (y/n): ${NC}" update_choice
  if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
    echo -e "\n${LIGHT_BLUE}Updating and upgrading packages...${NC}"
    sudo apt update && sudo apt upgrade -y
  else
    echo -e "\n${LIGHT_BLUE}Skipping package update and upgrade.${NC}"
  fi
  
  # Ask user if they want to install OpenVPN
  read -p "${LIGHT_BLUE}Do you want to install OpenVPN? (y/n): ${NC}" install_choice
  if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
    echo -e "\n${LIGHT_BLUE}Installing OpenVPN...${NC}"
    sudo apt install -y openvpn
  else
    echo -e "\n${LIGHT_BLUE}Skipping OpenVPN installation.${NC}"
  fi
  
  echo
}

# Execute step1
step1

# Colors
GRAY_BLUE="\033[1;34m"    # Dark gray blue
LIGHT_BLUE="\033[1;36m"   # Light blue
RED="\033[1;31m"          # Red
GREEN="\033[1;32m"        # Green
YELLOW="\033[1;33m"       # Yellow
NC="\033[0m"              # Reset color

# Step 4: Guide for configuring autologin
step4() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 4: Configure Autologin ===${NC}"
  
  # Detect current autologin settings
  _detect_autologin() {
    local lightdm_conf="/etc/lightdm/lightdm.conf"
    local autologin_status="Not configured"
    
    # Check LightDM configuration
    if grep -q "autologin-user=" "$lightdm_conf" 2>/dev/null; then
      autologin_user=$(grep "autologin-user=" "$lightdm_conf" | cut -d'=' -f2)
      autologin_status="Configured for user: $autologin_user"
    fi
    
    # Check systemd autologin
    if systemctl get-default | grep -q graphical; then
      autologin_status+=" | Graphical login enabled"
    fi
    
    echo "$autologin_status"
  }
  
  # Detect current autologin settings
  current_autologin=$(_detect_autologin)
  
  # Display current autologin status
  echo -e "${YELLOW}Current Autologin Status:${NC} $current_autologin"
  echo
  
  # Instructions for autologin configuration
  echo "To configure autologin in Desktop mode (graphical interface):"
  echo "1. Navigate through raspi-config submenus:"
  echo "   - Go to \"System Options\"."
  echo "   - Then, go to \"Boot / Auto Login\"."
  echo "   - Finally, select \"Desktop Autologin\"."
  echo

  # Ask for user confirmation
  while true; do
    read -p "Do you want to proceed with autologin configuration? (y/n): " confirmation
    
    case "${confirmation,,}" in
      y|yes)
        read -p "Press Enter to continue and open raspi-config..."
        sudo raspi-config
        return 0
        ;;
      n|no)
        # Offer alternative options
        echo -e "\n${LIGHT_BLUE}What would you like to do?${NC}"
        PS3="Select an option: "
        options=(
          "Open a tutorial about autologin"
          "Review autologin instructions"
          "Exit"
        )
        
        select opt in "${options[@]}"; do
          case $REPLY in
            1)
              echo "Opening tutorial in web browser..."
              xdg-open "https://linuxconfig.org/how-to-set-user-autologin-on-raspberry-pi" &>/dev/null
              break
              ;;
            2)
              # Redisplay instructions
              clear
              echo -e "\n${GRAY_BLUE}=== Autologin Configuration Instructions ===${NC}"
              echo "1. Open raspi-config"
              echo "2. Navigate to \"System Options\""
              echo "3. Select \"Boot / Auto Login\""
              echo "4. Choose \"Desktop Autologin\""
              read -p "Press Enter to continue..."
              break
              ;;
            3)
              echo "Exiting autologin configuration..."
              return 1
              ;;
            *)
              echo "Invalid option. Please select 1-3."
              ;;
          esac
        done
        ;;
      *)
        echo "Invalid input. Please enter 'y' for yes or 'n' for no."
        ;;
    esac
  done
}

step4

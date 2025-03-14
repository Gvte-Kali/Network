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

# Step 6: Install PiVPN
step6() {
  clear
  echo -e "\n${GRAY_BLUE}=== PiVPN Installation ===${NC}"
  curl -L https://install.pivpn.io | bash
  echo
}

step6

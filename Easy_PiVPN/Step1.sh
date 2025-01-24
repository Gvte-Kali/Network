# Colors
GRAY_BLUE="\033[1;34m"
LIGHT_BLUE="\033[1;36m"
NC="\033[0m"         

clear

# Step 1: Update packages
step1() {
  echo -e "\n${GRAY_BLUE}=== Step 1: Updating packages ===${NC}"
  sudo apt update && sudo apt upgrade -y
  echo
}

step1

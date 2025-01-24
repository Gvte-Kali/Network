# Define colors
GRAY_BLUE="\033[1;34m"    # 
LIGHT_BLUE="\033[1;36m"   # 
NC="\033[0m"              # Reset color

# Step 3 : Install OpenVPN
step3() {
  echo -e "\n${GRAY_BLUE}=== Étape 3 : Installing OpenVPN ===${NC}"
  sudo apt install -y openvpn
  echo
}

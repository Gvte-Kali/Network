# Define colors
GRAY_BLUE="\033[1;34m"    # 
LIGHT_BLUE="\033[1;36m"   # 
NC="\033[0m"              # Reset color

# Retrieve the username from /tmp/username.txt
if [[ -f /tmp/username.txt ]]; then
  username=$(cat /tmp/username.txt)
else
  echo "Error: /tmp/username.txt not found. Please run the username script first."
  return 1
fi

# RustDesk version and link
rustdesk_link="https://github.com/rustdesk/rustdesk/releases/download/1.3.7/rustdesk-1.3.7-x86_64.deb"
rustdesk_version="1.3.7"

# Step 2: Download and install RustDesk
step2() {
  clear
  echo -e "\n${GRAY_BLUE}=== Step 2: RustDesk Installation ===${NC}"
  
  # Ask if user wants to install RustDesk as a VPN backup
  while true; do
    read -p "Do you want to install RustDesk as a backup access method for headless servers? (Y/n): " install_choice
    
    case "$install_choice" in
      [Yy]|"")
        # Proceed with RustDesk installation
        # Check if RustDesk is installed
        if dpkg -l | grep -q rustdesk; then
          # RustDesk is installed, check the version
          current_version=$(dpkg -l | grep rustdesk | awk '{print $3}')
          
          echo "Current version of RustDesk: $current_version"
          echo "Latest available version: $rustdesk_version"
          
          # Compare versions
          if [ "$(printf '%s\n' "$rustdesk_version" "$current_version" | sort -V | head -n1)" = "$current_version" ]; then
            # Current version is lower than the latest version
            read -p "A new version is available. Do you want to update? (Y/n): " update_choice
            
            if [[ "$update_choice" =~ ^[Yy]$ ]] || [ -z "$update_choice" ]; then
              # Download the .deb file
              echo "Downloading RustDesk..."
              wget -O "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" "$rustdesk_link"
              
              # Attempt installation
              echo "Installing RustDesk..."
              sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
              
              # Handle potential errors
              if [ $? -ne 0 ]; then
                echo "An error occurred during the update."
                
                # Update packages
                echo "Updating packages..."
                sudo apt update
                
                # Resolve missing dependencies
                echo "Installing missing dependencies..."
                sudo apt install -f -y
                
                # Retry installation
                echo "Retrying installation of RustDesk..."
                sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
                
                if [ $? -ne 0 ]; then
                  echo "Update failed. Trying to repair with apt --fix-broken install"
                  sudo apt --fix-broken install -y
                  
                  # Final installation attempt
                  sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
                fi
              fi
            else
              echo "Update canceled. Continuing the script."
            fi
          else
            echo "You already have the latest version of RustDesk."
          fi
        else
          # RustDesk is not installed, proceed with installation
          # Download the .deb file
          echo "Downloading RustDesk..."
          wget -O "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" "$rustdesk_link"
          
          # Attempt installation
          echo "Installing RustDesk..."
          sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
          
          # Handle potential errors
          if [ $? -ne 0 ]; then
            echo "An error occurred during installation."
            
            # Update packages
            echo "Updating packages..."
            sudo apt update
            
            # Resolve missing dependencies
            echo "Installing missing dependencies..."
            sudo apt install -f -y
            
            # Retry installation
            echo "Retrying installation of RustDesk..."
            sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
            
            if [ $? -ne 0 ]; then
              echo "Installation failed. Trying to repair with apt --fix-broken install"
              sudo apt --fix-broken install -y
              
              # Final installation attempt
              sudo apt install "/tmp/rustdesk-${rustdesk_version}-x86_64.deb" -y
            fi
          fi
        fi
        
        # 1. Configure auto-start
        echo "Configuring RustDesk to start automatically..."
        sudo systemctl enable rustdesk
        
        # 2. Check the service
        echo "Checking RustDesk service..."
        if ! systemctl is-active --quiet rustdesk; then
          echo "The RustDesk service is not running. Starting..."
          sudo systemctl start rustdesk
          
          # Check after starting
          if ! systemctl is-active --quiet rustdesk; then
            echo "ERROR: Unable to start the RustDesk service"
            return 1
          fi
        fi
        
        # 3. Message for the password
        echo -e "\n${LIGHT_BLUE}IMPORTANT:${NC}"
        echo "You need to set a permanent password for your RustDesk session."
        echo "Go to the settings and set a unique password (one-time password)."
        echo
        
        # 4. Request the session number
        while true; do
          read -p "Enter your RustDesk session number: " rustdesk_id
          
          # Simple validation of the session number
          if [[ "$rustdesk_id" =~ ^[0-9]+$ ]]; then
            echo "Session number recorded: $rustdesk_id"
            break
          else
            echo "Invalid session number. Please enter only digits."
          fi
        done

        # Create the rustdesk session file
        echo "$rustdesk_id" > "/home/$username/vpn_config/rustdesk"
        
        echo "RustDesk installation and configuration process completed."
        echo
        break
        ;;
      
      [Nn])
        # No RustDesk, create file with "no rustdesk"
        echo "no rustdesk" > "/home/$username/vpn_config/rustdesk"
        echo "Skipping RustDesk installation. A file has been created to indicate no RustDesk."
        break
        ;;
      
      *)
        echo "Invalid choice. Please answer Y or N."
        ;;
    esac
  done
}

step2

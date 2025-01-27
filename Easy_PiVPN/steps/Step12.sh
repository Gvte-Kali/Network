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

# Step 12: PiVPN User Management
step12() {
  clear
  # Retrieve the username from /tmp/username.txt
  if [[ -f /tmp/username.txt ]]; then
    username=$(cat /tmp/username.txt)
  else
    echo "Error: /tmp/username.txt not found. Please run the username script first."
    return 1
  fi

  OVPN_DIR="/home/$username/ovpns/"  # Directory for OVPN files

  echo -e "\n${GRAY_BLUE}=== Step 12: OpenVPN User Management ===${NC}"

  # Check if PiVPN is installed
  if ! command -v pivpn &> /dev/null; then
    echo -e "${LIGHT_BLUE}PiVPN is not installed.${NC}"
    echo "Please install PiVPN first in Step 9."
    return 1
  fi

  # Function to send a message to Discord
  send_discord_message() {
    local message="$1"
    local webhook_file="/home/$username/vpn_config/discord_webhook.txt"
    local file_path="$2"

    if [ -f "$webhook_file" ]; then
      local discord_webhook=$(cat "$webhook_file")
      
      if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        # Correct the file path
        local absolute_file_path=$(realpath "$file_path")
        
        # Send with file
        curl -F "payload_json={\"content\":\"$message\"}" \
             -F "file=@$absolute_file_path" \
             "$discord_webhook"
      else
        # Simple message send
        curl -X POST "$discord_webhook" \
             -H "Content-Type: application/json" \
             -d "{\"content\":\"$message\"}"
      fi
    else
      echo "Discord webhook file not found."
    fi
  }

  # User management menu
  while true; do
    echo -e "\n${LIGHT_BLUE}OpenVPN User Management Options:${NC}"
    echo "1. List existing users"
    echo "2. Create a new user"
    echo "3. Delete a user"
    echo "4. Export a user's configuration"
    echo "0. Return to the main menu"
    
    read -p "Your choice: " user_choice
    
    case "$user_choice" in
      1)
        # List existing users
        echo -e "\n${LIGHT_BLUE}Existing OpenVPN Users:${NC}"
        existing_users=$(ls "$OVPN_DIR"/*.ovpn 2>/dev/null | sed 's/.*\///; s/\.ovpn//')
        
        if [ -z "$existing_users" ]; then
          echo "No existing users."
        else
          echo "$existing_users"
          # Send the list to Discord
          send_discord_message "List of VPN users:\n$existing_users"
        fi
        ;;
      
      2)
        # Add a new user
        while true; do
          read -p "Enter the username (no spaces): " new_user
          
          # Validate the username
          if [[ "$new_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            # Check if the user already exists
            if [ -f "$OVPN_DIR/$new_user.ovpn" ]; then
              echo -e "${GRAY_BLUE}A user with this name already exists.${NC}"
              read -p "Would you like to choose another name? (Y/n) : " retry_choice
              
              if [[ "$retry_choice" =~ ^[Nn]$ ]]; then
                break
              fi
            else
              # Create the user
              echo "Creating user $new_user..."
              sudo pivpn -a -n "$new_user"
              
              # Wait for the creation to finish
              sleep 2
              
              user_config="$OVPN_DIR/$new_user.ovpn"
              
              if [ -f "$user_config" ]; then
                # Send the message and file to Discord
                send_discord_message "New VPN user created: $new_user" "$user_config"
                
                echo -e "\n${LIGHT_BLUE}Configuration file created and sent to Discord.${NC}"
              else
                echo -e "${GRAY_BLUE}Error: The configuration file was not created.${NC}"
              fi
              
              break
            fi
          else
            echo "Invalid username. Use only letters, numbers, _ and -."
          fi
        done
        ;;
      
      3)
        # Delete a user
        echo -e "\n${LIGHT_BLUE}Delete an OpenVPN user:${NC}"
        existing_users=($(ls "$OVPN_DIR"/*.ovpn | sed 's/.*\///; s/\.ovpn//'))
        
        if [ ${#existing_users[@]} -eq 0 ]; then
          echo "No existing users to delete."
          continue
        fi
        
        echo "Existing users:"
        for i in "${!existing_users[@]}"; do
          echo "$((i+1)). ${existing_users[i]}"
        done
        
        while true; do
          read -p "Select the user to delete (1-${#existing_users[@]}) : " delete_choice
          
          if [[ "$delete_choice" =~ ^[0-9]+$ ]] && 
             [ "$delete_choice" -ge 1 ] && 
             [ "$delete_choice" -le "${#existing_users[@]}" ]; then
            
            user_to_delete="${existing_users[$((delete_choice-1))]}"
            echo "Deleting user $user_to_delete..."
            sudo pivpn -r "$user_to_delete"
            
            # Send a notification to Discord
            send_discord_message "VPN user deleted: $user_to_delete"
            
            echo "User  $user_to_delete deleted."
            break
          else
            echo "Invalid choice. Please select a valid number."
          fi
        done
        ;;
      
      4)
        # Export a user's configuration
        echo -e "\n${LIGHT_BLUE}Export a user's OpenVPN configuration:${NC}"
        existing_users=($(ls "$OVPN_DIR"/*.ovpn | sed 's/.*\///; s/\.ovpn//'))
        
        if [ ${#existing_users[@]} -eq 0 ]; then
          echo "No existing users to export."
          continue
        fi
        
        echo "Existing users:"
        for i in "${!existing_users[@]}"; do
          echo "$((i+1)). ${existing_users[i]}"
        done
        
        while true; do
          read -p "Select the user to export (1-${#existing_users[@]}) : " export_choice
          
          if [[ "$export_choice" =~ ^[0-9]+$ ]] && 
             [ "$export_choice" -ge 1 ] && 
             [ "$export_choice" -le "${#existing_users[@]}" ]; then
            
            user_to_export="${existing_users[$((export_choice-1))]}"
            export_path="/home/$username/vpn_config/${user_to_export}_config.ovpn"
            cp "$OVPN_DIR/$user_to_export.ovpn" "$export_path"
            
            # Send a notification to Discord with the exported file
            send_discord_message "User  configuration exported: $user_to_export" "$export_path"
            echo "User  configuration for $user_to_export exported to $export_path."
            break
          else
            echo "Invalid choice. Please select a valid number."
          fi
        done
        ;;
      
      0)
        # Return to the main menu
        break
        ;;
      
      *)
        echo "Invalid choice. Please try again."
        ;;
    esac
    
    # Pause for visibility
    read -p "Press Enter to continue..."
  done
  
  # Save users
  mkdir -p "/home/$username/vpn_config"
  ls "$OVPN_DIR"/*.ovpn 2>/dev/null | sed 's/.*\///; s/\.ovpn//' > "/home/$username/vpn_config/vpn_users"
  
  echo -e "\n${LIGHT_BLUE}List of users saved in /home/$username/vpn_config/vpn_users${NC}"
  send_discord_message "List of users saved in /home/$username/vpn_config/vpn_users"
  echo
}

step12

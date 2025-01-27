#!/bin/bash

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

# Function to display the main menu
main_menu() {
  clear
  echo -e "${LIGHT_BLUE}====== Main Menu ======${NC}"
  echo
  echo "1 --> Start full setup"
  echo "2 --> Go to a specific step"
  echo "3 --> PiVPN Management"
  echo "4 --> Send files to Discord"  # New option for sending files
  echo
  echo -e "${RED}=====================================${NC}"
  echo "0 --> Exit"
  echo
  read -p "-->  " main_choice
}

# Function to check prerequisites
check_prerequisites() {
  # Check if the user has sudo rights
  if [[ $EUID -ne 0 ]]; then
     echo "This script must be run with sudo privileges." 
     exit 1
  fi
}

# Internal function to get and select username
get_user_name() {
    # Get list of all users with login shells
    local users=($(getent passwd | awk -F: '$7 ~ /\/bin\/bash|\/bin\/zsh|\/bin\/sh/ {print $1}'))

    # Check if any users are found
    if [ ${#users[@]} -eq 0 ]; then
        echo "No users found with login shells."
        return 1
    fi

    # Display available users
    echo -e "${LIGHT_BLUE}Available Users:${NC}"
    for i in "${!users[@]}"; do
        echo "$((i+1)). ${users[i]}"
    done

    # User selection
    local selection
    while true; do
        read -p "Select a user by number ( choose root only if you know what you are doing ) (1-${#users[@]}): " selection

        # Validate selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && 
           [ "$selection" -ge 1 ] && 
           [ "$selection" -le ${#users[@]} ]; then

            # Adjust for zero-based indexing
            local chosen_user="${users[$((selection-1))]}"

            # Confirm selection
            read -p "You selected $chosen_user. Is this correct? (Y/n): " confirm

            if [[ "$confirm" =~ ^[Yy]$ ]] || [ -z "$confirm" ]; then
                # Save username to temporary file
                echo "$chosen_user" > /tmp/username.txt
                echo -e "${GREEN}Username '$chosen_user' has been saved to /tmp/username.txt.${NC}"
                return 0
            fi
        else
            echo "Invalid selection. Please choose a number between 1 and ${#users[@]}."
        fi
    done
}

# Function to send files to Discord
send_file_to_discord() {
    clear
    # Retrieve the username from /tmp/username.txt
    if [[ -f /tmp/username.txt ]]; then
        username=$(cat /tmp/username.txt)
    else
        echo "Error: /tmp/username.txt not found. Please run the username script first."
        return 1
    fi

    local config_dir="/home/$username/vpn_config/"
    
    while true; do  # Start the loop
        # List files in the directory
        clear
        echo -e "${LIGHT_BLUE}=== Select a file to send to Discord ===${NC}"
        mapfile -t files < <(find "$config_dir" -maxdepth 1 -type f)
        
        if [ ${#files[@]} -eq 0 ]; then
            echo "No files found in $config_dir."
            return 1
        fi

        for i in "${!files[@]}"; do
            echo "$((i+1)). $(basename "${files[i]}")"
        done
        echo "0 --> Send all files"
        echo "99 --> Return to the main menu"

        read -p "Select a file by number: " file_choice
        
        if [[ "$file_choice" =~ ^[0-9]+$ ]]; then
            if [ "$file_choice" -eq 99 ]; then
                break  # Exit the loop and return to main menu
            elif [ "$file_choice" -eq 0 ]; then
                # Send all files
                for file in "${files[@]}"; do
                    filename=$(basename "$file")
                    # Use printf to handle newlines and escape special characters
                    file_content=$(printf '%s' "$(cat "$file")")
                    send_discord_message "📄 File: $filename\n\`\`\`\n$file_content\`\`\`\n\n"
                done
                echo "All files sent to Discord."
            elif [ "$file_choice" -ge 1 ] && [ "$file_choice" -le ${#files[@]} ]; then
                # Send the selected file
                local selected_file="${files[$((file_choice-1))]}"
                filename=$(basename "$selected_file")
                # Use printf to handle newlines and escape special characters
                file_content=$(printf '%s' "$(cat "$selected_file")")
                send_discord_message "📄 File: $filename\n\`\`\`\n$file_content\`\`\`\n\n"
                echo "File sent to Discord."
            else
                echo "Invalid choice. Please try again."
                continue
            fi

            # Pause for visibility
            read -p "Press Enter to continue..."
        else
            echo "Invalid choice. Please try again."
        fi
    done
}

# Function to send a message to Discord
send_discord_message() {
    local message="$1"
    local webhook_file="/home/$username/vpn_config/discord_webhook.txt"
    
    if [ -f "$webhook_file" ]; then
        local discord_webhook=$(cat "$webhook_file")
        
        # Escape newlines and quotes for JSON
        message=$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
        
        # Send message
        curl -X POST "$discord_webhook" \
             -H "Content-Type: application/json" \
             -d "{\"content\":\"$message\"}"
    else
        echo "Discord webhook file not found."
    fi
}

# PiVPN Management function
PiVPN_Mgmt() {
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

  # User management menu
  while true; do
    echo -e "\n${LIGHT_BLUE}OpenVPN User Management Options:${NC}"
    echo "1 --> List existing users"
    echo "2 --> Create a new user"
    echo "3 --> Delete a user"
    echo "4 --> Export a user's configuration"
    echo "5 --> Send files to Discord"  # New option for sending files
    echo -e "${WHITE}=========================================${NC}"
    echo "0. Return to the main menu"

    read -p " --> " user_choice

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

            echo "User   $user_to_delete deleted."
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

      5)
        send_file_to_discord  # Call the function to send files to Discord
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

# Function to fetch and execute a script from a specific URL
fetch_and_run_script() {
    local url="$1"
    local script_path="/tmp/step_$(date +%s).sh"

    # Download the script
    if ! curl -s "$url" > "$script_path"; then
        echo "Error downloading the script"
        return 1
    fi

    # Make the script executable
    chmod +x "$script_path"

    # Execute the script with sudo
    sudo bash "$script_path"

    # Clean up the temporary script
    rm -f "$script_path"
}

# Function to manage steps and action choices
run_step() {
  local step_number=$1
  echo "Executing Step $step_number..."

  # Check if we should skip steps 5 and 6
  if [[ $step_number -eq 5 ]] && [[ -f /tmp/skip_network_config_step5 ]]; then
    echo "Skipping step 5 as per previous configuration."
    rm -f /tmp/skip_network_config_step5
    return 0
  fi

  if [[ $step_number -eq 6 ]] && [[ -f /tmp/skip_network_config_step6 ]]; then
    echo "Skipping step 6 as per previous configuration."
    rm -f /tmp/skip_network_config_step6
    return 0
  fi

  local url="https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/steps/Step${step_number}.sh"
  fetch_and_run_script "$url"
}

# Function to display the list of steps
display_steps() {
  echo
  echo -e "${LIGHT_BLUE}=== List of Steps ===${NC}"
  echo "0 --> Prepare directories"
  echo "1 --> Update packages"
  echo "2 --> Install RustDesk"
  echo "3 --> Install OpenVPN"
  echo "4 --> List network interfaces"
  echo "5 --> IP configuration"
  echo "6 --> Apply IP configuration"
  echo "7 --> Configure autologin"
  echo "8 --> Configure Discord cronjob"
  echo "9 --> Install PiVPN"
  echo "10 --> Configure routing and NAT VPN on Raspberry Pi"
  echo "11 --> Configure NAT and port forwarding on router"
  echo -e "${WHITE}=========================================${NC}"
  echo "99 --> Return to Main Menu"
  echo
}

# Main menu flow
main_menu_flow() {
  main_menu
  case "$main_choice" in
    1)
      # Start all setup steps
      run_step 0  # Call to execute Step 0
      for i in {1..11}; do
        run_step $i
      done
      ;;
    2)
      # Display the list of steps and allow choosing a specific step
      while true; do
        display_steps
        read -p "-->  " specific_step
        echo
        if [[ "$specific_step" -eq 0 ]]; then
          run_step 0  # Call to execute Step 0
        elif [[ "$specific_step" -ge 1 && "$specific_step" -le 11 ]]; then
          run_step $specific_step
        elif [[ "$specific_step" -eq 99 ]]; then
          clear
          main_menu_flow  # Call the main menu flow again
          return  # Exit the loop
        else
          echo "Invalid choice. Please try again."
        fi
      done
      ;;
    3) 
      PiVPN_Mgmt
      main_menu_flow
      ;;
    4)
      send_file_to_discord  # Call the function to send files to Discord
      main_menu_flow
      ;;
    0) echo "Exiting the script."; exit 0 ;;
    *) echo "Invalid choice. Returning to the main menu..."; main_menu_flow ;;
  esac
}

cat << EOF
______________________________________________________________________________________________
888      d888                             888          d8888                            d8888  
888     d8888                             888         d8P888                           d8P888  
888       888                             888        d8P 888                          d8P 888  
88888b.   888   .d88b.           88888b.  88888b.   d8P  888  888d888 88888b.d88b.   d8P  888  
888 "88b  888  d88P"88b          888 "88b 888 "88b d88   888  888P"   888 "888 "88b d88   888  
888  888  888  888  888          888  888 888  888 8888888888 888     888  888  888 8888888888 
888 d88P  888  Y88b 888          888 d88P 888  888       888  888     888  888  888       888  
88888P" 8888888 "Y88888 88888888 88888P"  888  888       888  888     888  888  888       888  
                    888          888                                                           
              Y8b d88P          888                                                           
                "Y88P"           888                                                           
______________________________________________________________________________________________
EOF

# Call the prerequisite check
check_prerequisites

# Call of the function to get and check username
get_user_name

# Start the script by calling the main menu flow
main_menu_flow

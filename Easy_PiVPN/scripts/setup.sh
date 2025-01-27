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
  echo
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


# Function to send a message to Discord
send_discord_message() {
    local message="$1"
    local file_path="$2"
    local webhook_file="/home/$username/vpn_config/discord_webhook.txt"

    if [ ! -f "$webhook_file" ]; then
        echo "Discord webhook file not found."
        return 1
    fi

    local discord_webhook=$(cat "$webhook_file")

    if [ -n "$file_path" ] && [ -f "$file_path" ]; then
        # Envoi avec fichier
        curl -F "payload_json={\"content\":\"$message\"}" \
             -F "file=@$file_path" \
             "$discord_webhook"
    else
        # Envoi simple du message
        # Utiliser jq pour encoder correctement le message
        encoded_message=$(echo "$message" | jq -R -s '.')
        
        curl -X POST "$discord_webhook" \
             -H "Content-Type: application/json" \
             -d "{\"content\":$encoded_message}"
    fi
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
        # List files in the directory, excluding .sh files
        clear
        echo -e "${LIGHT_BLUE}=== Select a file to send to Discord ===${NC}"
        mapfile -t files < <(find "$config_dir" -maxdepth 1 -type f ! -name "*.sh")
        
        if [ ${#files[@]} -eq 0 ]; then
            echo "No files found in $config_dir."
            return 1
        fi

        for i in "${!files[@]}"; do
            echo "$((i+1)). $(basename "${files[i]}")"
        done
        echo "0 --> Send all files"
        echo
        echo -e "${RED}=====================================${NC}"
        echo
        echo "99 --> Return to the main menu"
        echo
        echo
        echo

        read -p "Select a file by number: " file_choice
        
        if [[ "$file_choice" =~ ^[0-9]+$ ]]; then
            if [ "$file_choice" -eq 99 ]; then
                break  # Exit the loop and return to main menu
            elif [ "$file_choice" -eq 0 ]; then
                # Send all files
                for file in "${files[@]}"; do
                    filename=$(basename "$file")
                    
                    # Special handling for .ovpn files
                    if [[ "$filename" == *.ovpn ]]; then
                        send_discord_message "📄 OpenVPN Configuration: $filename" "$file"
                    else
                        file_content=$(cat "$file")
                        send_discord_message "📄 File: $filename

\`\`\`
$file_content
\`\`\`"
                    fi
                done
                echo "All files sent to Discord."
            elif [ "$file_choice" -ge 1 ] && [ "$file_choice" -le ${#files[@]} ]; then
                # Send the selected file
                local selected_file="${files[$((file_choice-1))]}"
                filename=$(basename "$selected_file")
                
                # Special handling for .ovpn files
                if [[ "$filename" == *.ovpn ]]; then
                    send_discord_message "📄 OpenVPN Configuration: $filename" "$selected_file"
                else
                    file_content=$(cat "$selected_file")
                    send_discord_message "📄 File: $filename

\`\`\`
$file_content
\`\`\`"
                fi
                
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


# PiVPN Management Function
PiVPN_Mgmt() {
    # Clear the screen
    clear

    # Retrieve username
    if [[ ! -f /tmp/username.txt ]]; then
        echo "Error: /tmp/username.txt not found. Please run the username script first."
        return 1
    fi

    username=$(cat /tmp/username.txt)
    OVPN_DIR="/home/$username/ovpns"

    # Ensure directory exists, create if necessary
    mkdir -p "$OVPN_DIR"

    # Check PiVPN installation
    if ! command -v pivpn &> /dev/null; then
        echo -e "${LIGHT_BLUE}PiVPN is not installed.${NC}"
        echo "Please install PiVPN in Step 9."
        return 1
    fi

    # Internal function to list users
    list_users() {
        local users=$(find "$OVPN_DIR" -maxdepth 1 -type f -name "*.ovpn" -printf "%f\n" | sed 's/\.ovpn$//')
        
        if [ -z "$users" ]; then
            echo "No existing users found."
            return 1
        fi
        
        echo "Existing VPN Users:"
        echo "$users"
        return 0
    }

    # Main menu loop
    while true; do
        clear
        echo -e "${LIGHT_BLUE}=== OpenVPN User Management ===${NC}"
        echo "1. List Users"
        echo "2. Create New User"
        echo "3. Delete User"
        echo "4. Export User Configuration"
        echo "0. Exit to Main Menu"
        echo -e "${RED}=====================================${NC}"

        read -p "Select an option: " user_choice

        case "$user_choice" in
            1)
                # List users
                if list_users; then
                    # Retrieve user list
                    local users=$(find "$OVPN_DIR" -maxdepth 1 -type f -name "*.ovpn" -printf "%f\n" | sed 's/\.ovpn$//')
                    
                    # Send list to Discord if not empty
                    if [ -n "$users" ]; then
                        send_discord_message "Current VPN Users:
$users"
                    fi
                fi
                ;;

            2)
                # Add a new user
                while true; do
                    read -p "Enter new username (no spaces): " new_user

                    # Username validation
                    if [[ ! "$new_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                        echo "Invalid username format."
                        continue
                    fi

                    # Check if user exists
                    if [ -f "$OVPN_DIR/$new_user.ovpn" ]; then
                        echo "A user with this name already exists."
                        read -p "Would you like to choose another name? (Y/n): " retry_choice
                        [[ "$retry_choice" =~ ^[Nn]$ ]] && break
                        continue
                    fi

                    # User creation
                    echo "Creating new VPN user: $new_user"
                    sudo pivpn -a -n "$new_user"
                    sleep 2

                    user_config="$OVPN_DIR/$new_user.ovpn"
                    
                    if [ -f "$user_config" ]; then
                        send_discord_message "New VPN User Created: $new_user" "$user_config"
                        echo "User $new_user created successfully."
                    else
                        echo "Failed to create user configuration."
                    fi
                    break
                done
                ;;

            3)
                # Delete a user
                mapfile -t existing_users < <(find "$OVPN_DIR" -maxdepth 1 -type f -name "*.ovpn" -printf "%f\n" | sed 's/\.ovpn$//')
                
                if [ ${#existing_users[@]} -eq 0 ]; then
                    echo "No users available to delete."
                    continue
                fi

                echo "Available Users:"
                for i in "${!existing_users[@]}"; do
                    echo "$((i+1)). ${existing_users[i]}"
                done

                read -p "Select user to delete (1-${#existing_users[@]}): " delete_choice

                if [[ "$delete_choice" =~ ^[0-9]+$ ]] && 
                   [ "$delete_choice" -ge 1 ] && 
                   [ "$delete_choice" -le "${#existing_users[@]}" ]; then
                    
                    user_to_delete="${existing_users[$((delete_choice-1))]}"
                    echo "Removing VPN user: $user_to_delete"
                    sudo pivpn -r "$user_to_delete"
                    send_discord_message "VPN User Removed: $user_to_delete"
                    echo "User $user_to_delete has been deleted."
                fi
                ;;

            4)
                # Export configuration
                mapfile -t existing_users < <(find "$OVPN_DIR" -maxdepth 1 -type f -name "*.ovpn" -printf "%f\n" | sed 's/\.ovpn$//')
                
                if [ ${#existing_users[@]} -eq 0 ]; then
                    echo "No users available to export."
                    continue
                fi

                echo "Available Users:"
                for i in "${!existing_users[@]}"; do
                    echo "$((i+1)). ${existing_users[i]}"
                done

                read -p "Select user to export (1-${#existing_users[@]}): " export_choice

                if [[ "$export_choice" =~ ^[0-9]+$ ]] && 
                   [ "$export_choice" -ge 1 ] && 
                   [ "$export_choice" -le "${#existing_users[@]}" ]; then
                    
                    user_to_export="${existing_users[$((export_choice-1))]}"
                    export_path="/home/$username/vpn_config/${user_to_export}_config.ovpn"
                    
                    mkdir -p "/home/$username/vpn_config"
                    cp "$OVPN_DIR/$user_to_export.ovpn" "$export_path"
                    
                    send_discord_message "VPN Configuration Exported: $user_to_export" "$export_path"
                    echo "Configuration for $user_to_export exported to $export_path"
                fi
                ;;

            0)
                break
                ;;

            *)
                echo "Invalid option. Please try again."
                ;;
        esac

        read -p "Press Enter to continue..." pause
    done

    # Final users list save
    mkdir -p "/home/$username/vpn_config"
    find "$OVPN_DIR" -maxdepth 1 -type f -name "*.ovpn" -printf "%f\n" | sed 's/\.ovpn$//' > "/home/$username/vpn_config/vpn_users"

    echo "User list saved."
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
  echo
  echo
  echo -e "${WHITE}=========================================${NC}"
  echo
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

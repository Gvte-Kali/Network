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
  echo -e "${LIGHT_BLUE}====== Main Menu ======${NC}"
  echo
  echo "1 --> Start full setup"
  echo "2 --> Go to a specific step"
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
        read -p "Select a user by number (1-${#users[@]}): " selection
        
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
  echo "0. Prepare directories"
  echo "1. Update packages"
  echo "2. Install RustDesk"
  echo "3. Install OpenVPN"
  echo "4. List network interfaces"
  echo "5. IP configuration"
  echo "6. Apply IP configuration"
  echo "7. Configure autologin"
  echo "8. Configure Discord cronjob"
  echo "9. Install PiVPN"
  echo "10. Configure routing and NAT VPN on Raspberry Pi"
  echo "11. Configure NAT and port forwarding on router"
  echo "12. Manage PiVPN users"
  echo -e "${WHITE}=========================================${NC}"
  echo "99. Return to Main Menu"
  echo
}

# Main menu flow
main_menu_flow() {
  main_menu
  case "$main_choice" in
    1)
      # Start all setup steps
      run_step 0  # Call to execute Step 0
      for i in {1..12}; do
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
        elif [[ "$specific_step" -ge 1 && "$specific_step" -le 12 ]]; then
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
    0) echo "Exiting the script."; exit 0 ;;
    *) echo "Invalid choice. Returning to the main menu..."; main_menu_flow ;;
  esac
}

cat << EOF
${RED}______________________________________________________________________________________________

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
${NC}
EOF



# Call the prerequisite check
check_prerequisites

# Call of the function to get and check username
get_user_name

# Start the script by calling the main menu flow
main_menu_flow

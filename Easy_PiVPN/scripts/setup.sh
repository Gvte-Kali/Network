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


# Internal function to check if a user exists
get_user_name() {
    _check_user_exists() {
        local username="$1"
        
        # Check if the user exists
        if id "$username" &>/dev/null; then
            return 0  # User exists
        else
            return 1  # User does not exist
        fi
    }

    local username=""
    local max_attempts=3
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        # Prompt the user to enter a username
        read -p "Enter your username: " username

        # Check if the user exists
        if _check_user_exists "$username"; then
            # Save the username to a temporary file
            echo "$username" > /tmp/username.txt
            echo "Username '$username' exists and has been saved to /tmp/username.txt."
            return 0  # Success
        else
            echo "Username '$username' does not exist. Please try again."
            ((attempt++))
        fi
    done

    # Failure after the maximum number of attempts
    echo "Maximum number of attempts reached. Exiting."
    return 1
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
  local url="https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/steps/Step${step_number}.sh"
  fetch_and_run_script "$url"  # Call the fetch and run function
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



# Call the prerequisite check
check_prerequisites

# Call of the function to get and check username
get_user_name

# Start the script by calling the main menu flow
main_menu_flow

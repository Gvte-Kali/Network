#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("wget" "whiptail" "ansible")

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y $dep
        fi
    done
}

# Function to display the main menu
show_main_menu() {
    local backtitle="Configuration Menu"
    local height=$((LINES - 10))
    local width=$((COLUMNS - 20))
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" $height $width 3 \
           "1" "Deployment Scripts" \
           "2" "Customizing Scripts" \
           "99" "Exit Script" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        exit 0  # Exit the program if Cancel is pressed
    fi

    case $choice in
        1) show_deployment_menu "$backtitle" ;;
        2) show_customizing_menu "$backtitle" ;;
        99) whiptail --msgbox "You have chosen to exit the program. Thank you for using this script!" 8 50; exit 0 ;;  # Exit message
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the deployment menu
show_deployment_menu() {
    local backtitle="$1 --> Deployment Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 70 3 \
           "1" "Network" \
           "99" "Back to Main Menu" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_main_menu  # Return to the main menu if Cancel is pressed
    fi

    case $choice in
        1) show_network_menu "$backtitle" ;;
        99) show_main_menu ;;  # Return to main menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the network menu
show_network_menu() {
    local backtitle="$1 --> Network Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 70 3 \
           "1" "Easy_PiVPN.sh" \
           "99" "Back to Deployment Menu" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_deployment_menu "$(echo -e "$backtitle" | sed 's/-->.*//')"  # Return to the deployment menu if Cancel is pressed
    fi

    case $choice in
        1)
            bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh"
            ;;
        99) show_deployment_menu "$(echo -e "$backtitle" | sed 's/-->.*//')" ;;  # Return to deployment menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the customizing menu
show_customizing_menu() {
    local backtitle="$1 --> Customizing Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 70 3 \
           "1" "Raspberry_Pi_Customization" \
           "99" "Back to Main Menu" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_main_menu  # Return to the main menu if Cancel is pressed
    fi

    case $choice in
        1)
            execute_script "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_P i_OS/Custom_RPI_OS.sh"
            ;;
        99) show_main_menu ;;  # Return to main menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to execute a script from a GitHub URL
#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("wget" "whiptail" "ansible")

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y $dep
        fi
    done
}

# Function to display the main menu
show_main_menu() {
    local backtitle="Configuration Menu"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 60 3 \
           "1" "Deployment Scripts" \
           "2" "Customizing Scripts" \
           "99" "Exit Script" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        exit 0  # Exit the program if Cancel is pressed
    fi

    case $choice in
        1) show_deployment_menu "$backtitle" ;;
        2) show_customizing_menu "$backtitle" ;;
        99) whiptail --msgbox "You have chosen to exit the program. Thank you for using this script!" 8 50; exit 0 ;;  # Exit message
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the deployment menu
show_deployment_menu() {
    local backtitle="$1 --> Deployment Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 60 2 \
           "1" "Network" \
           "99" "Back to Main Menu" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_main_menu  # Return to the main menu if Cancel is pressed
    fi

    case $choice in
        1) show_network_menu "$backtitle" ;;
        99) show_main_menu ;;  # Return to main menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the network menu
show_network_menu() {
    local backtitle="$1 --> Network Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 60 2 \
           "1" "Easy_PiVPN.sh" \
           "99" "Back to Deployment Menu" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_deployment_menu "$(echo -e "$backtitle" | sed 's/-->.*//')"  # Return to the deployment menu if Cancel is pressed
    fi

    case $choice in
        1)
            bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh"
            ;;
        99) show_deployment_menu "$(echo -e "$backtitle" | sed 's/-->.*//')" ;;  # Return to deployment menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the customizing menu
show_customizing_menu() {
    local backtitle="$1 --> Customizing Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 60 2 \
           "1" "Customization Options" \
           "99" "Back to Main Menu" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_main_menu  # Return to the main menu if Cancel is pressed
    fi

    case $choice in
        1) show_customization_options_menu "$backtitle" ;;  # Go to the new submenu
        99) show_main_menu ;;  # Return to main menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the customization options submenu
show_customization_options_menu() {
    local backtitle="$1 --> Customization Options"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 60 3 \
           "1" "Run Custom_RPI_OS.sh" \
           "2" "Run Custom_RPI_OS.yml" \
           "99" "Back to Customizing Scripts" 3>&1 1>&2 2>&3)

    # Check if the user pressed Cancel
    if [ $? -ne 0 ]; then
        show_customizing_menu "$backtitle"  # Return to the customizing menu if Cancel is pressed
    fi

    case $choice in
        1)
            execute_script "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Custom_RPI_OS.sh"
            ;;
        2)
            execute_script "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Custom_RPI_OS.yml"
            ;;
        99) show_customizing_menu "$backtitle" ;;  # Return to customizing menu
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to execute a script from a GitHub URL
execute_script() {
    local url=$1
    local script_name=$(basename $url)

    # Download the script
    wget -O /tmp/$script_name $url

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        # Check the file extension
        case "${script_name##*.}" in
            sh)
                # Make the script executable and run it
                chmod +x /tmp/$script_name
                /tmp/$script_name
                wget -O /tmp/Deployment.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Deployment.sh && chmod +x /tmp/Deployment.sh && bash /tmp/Deployment.sh
                ;;
            yml)
                # Run the Ansible playbook
                ansible-playbook /tmp/$script_name
                wget -O /tmp/Deployment.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Deployment.sh && chmod +x /tmp/Deployment.sh && bash /tmp/Deployment.sh
                ;;
            *)
                # Show an error message for unsupported file types
                whiptail --msgbox "Error: Unsupported file type. Please provide a .sh or .yml file." 8 50
                ;;
        esac

        # Remove the script after execution
        rm /tmp/$script_name
    else
        whiptail --msgbox "Error downloading the script." 8 50
    fi
}

# Check and install dependencies
check_dependencies

# Display the main menu
show_main_menu

# Check and install dependencies
check_dependencies

# Display the main menu
show_main_menu

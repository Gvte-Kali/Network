#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("wget" "ansible")

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            whiptail --title "Dependency Check" --msgbox "$dep is not installed. Installing..." 8 50
            sudo apt-get update
            sudo apt-get install -y $dep
        else
            whiptail --title "Dependency Check" --msgbox "$dep is already installed." 8 50
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
           --menu "Choose an option:" $height $width 4 \
           "1" "Deployment Scripts" "Manage and run deployment scripts for your system." \
           "2" "Customizing Scripts" "Customize your Raspberry Pi settings." \
           "3" "Exit" "Exit the configuration menu." 3>&1 1>&2 2>&3)

    case $choice in
        1) show_deployment_menu "$backtitle" ;;
        2) show_customizing_menu "$backtitle" ;;
        3) exit 0 ;;
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the deployment menu
show_deployment_menu() {
    local backtitle="${1} → Deployment Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 70 3 \
           "1" "Network" "Manage network-related scripts." \
           "2" "Back to Main Menu" "Return to the main menu." 3>&1 1>&2 2>&3)

    case $choice in
        1) show_network_menu "$backtitle" ;;
        2) show_main_menu ;;
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the network menu
show_network_menu() {
    local backtitle="${1} → Network Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 70 3 \
           "1" "Easy_PiVPN.sh" "Run the Easy PiVPN setup script." \
           "2" "Back to Deployment Menu" "Return to the deployment menu." 3>&1 1>&2 2>&3)

    case $choice in
        1)
            bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh"
            ;;
        2) show_deployment_menu "$(echo -e "$backtitle" | sed 's/ → Network Scripts//')" ;;
        *) whiptail --msgbox "Invalid choice. Please try again." 8 50 ;;
    esac
}

# Function to display the customizing menu
show_customizing_menu() {
    local backtitle="${1} → Customizing Scripts"
    local choice

    choice=$(whiptail --clear --title "$backtitle" \
           --menu "Choose an option:" 20 70 3 \
           "1" "Raspberry_Pi_Customization" "Run the Raspberry Pi customization script." \
           "2" "Back to Main Menu" "Return to the main menu." 3>&1 1>&2 2>&3)

    case $choice in
        1)
            execute_script "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Custom_RPI_OS.sh"
            ;;
        2) show_main_menu ;;
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
        # Make the script executable
        chmod +x /tmp/$script_name

        # Execute the script
        /tmp/$script_name

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

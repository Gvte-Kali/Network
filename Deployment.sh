#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("dialog" "wget" "ansible")

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo "$dep is not installed. Installing..."
            sudo apt-get update
            sudo apt-get install -y $dep
        fi
    done
}

# Function to display the main menu
show_main_menu() {
    local backtitle="Configuration Menu"
    dialog --clear --backtitle "$backtitle" \
           --title "Main Menu" \
           --nocancel \
           --menu "Choose an option:" 0 0 3 \
           "Deployment Scripts" "Manage deployment scripts" \
           "Customizing Scripts" "Manage customizing scripts" \
           "Exit" "Exit the menu" 2>menu_choice.txt

    choice=$(<menu_choice.txt)
    case $choice in
        "Deployment Scripts")
            show_deployment_menu "$backtitle"
            ;;
        "Customizing Scripts")
            show_customizing_menu "$backtitle"
            ;;
        "Exit")
            exit 0
            ;;
        *)
            dialog --msgbox "Invalid choice. Please try again." 10 50
            show_main_menu
            ;;
    esac
}

# Function to display the deployment menu
show_deployment_menu() {
    local backtitle="$1
│
├── Deployment Scripts"
    dialog --clear --backtitle "$backtitle" \
           --title "Deployment Scripts" \
           --nocancel \
           --menu "Choose an option:" 0 0 3 \
           "Network" "Manage network scripts" \
           "Back to Main Menu" "Return to the main menu" 2>menu_choice.txt

    choice=$(<menu_choice.txt)
    case $choice in
        "Network")
            show_network_menu "$backtitle"
            ;;
        "Back to Main Menu")
            show_main_menu
            ;;
        *)
            dialog --msgbox "Invalid choice. Please try again." 10 50
            show_deployment_menu "$backtitle"
            ;;
    esac
}

# Function to display the network menu
show_network_menu() {
    local backtitle="$1
│
├── Network Scripts"
    dialog --clear --backtitle "$backtitle" \
           --title "Network Scripts" \
           --nocancel \
           --menu "Choose an option:" 0 0 3 \
           "Easy_PiVPN.sh" "Run Easy_PiVPN setup script" \
           "Back to Deployment Menu" "Return to the deployment menu" 2>menu_choice.txt

    choice=$(<menu_choice.txt)
    case $choice in
        "Easy_PiVPN.sh")
            bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh" && read -p "Press Enter..."
            ;;
        "Back to Deployment Menu")
            show_deployment_menu "$(echo $backtitle | sed 's/│\n├── Network Scripts//')"
            ;;
        *)
            dialog --msgbox "Invalid choice. Please try again." 10 50
            show_network_menu "$backtitle"
            ;;
    esac
}

# Function to display the customizing menu
show_customizing_menu() {
    local backtitle="$1
│
├── Customizing Scripts"
    dialog --clear --backtitle "$backtitle" \
           --title "Customizing Scripts" \
           --nocancel \
           --menu "Choose an option:" 0 0 3 \
           "Raspberry_Pi_Custom.sh" "Run Raspberry Pi customization script" \
           "Back to Main Menu" "Return to the main menu" 2>menu_choice.txt

    choice=$(<menu_choice.txt)
    case $choice in
        "Raspberry_Pi_Custom.sh")
            execute_script "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Custom_RPI_OS.sh"
            ;;
        "Back to Main Menu")
            show_main_menu
            ;;
        *)
            dialog --msgbox "Invalid choice. Please try again." 10 50
            show_customizing_menu "$backtitle"
            ;;
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
        dialog --msgbox "Error downloading the script." 10 50
    fi
}

# Check and install dependencies
check_dependencies

# Display the main menu
show_main_menu

#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("dialog" "wget")

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
           --menu "Choose an option:" 15 50 3 \
           1 "Deployment Scripts" \
           2 "Customizing Scripts" \
           99 "Exit" 2>menu_choice.txt

    choice=$(cat menu_choice.txt)
    case $choice in
        1)
            show_deployment_menu "$backtitle"
            ;;
        2)
            show_customizing_menu "$backtitle"
            ;;
        99)
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
           --menu "Choose an option:" 15 50 3 \
           1 "Network" \
           99 "Back to Main Menu" 2>menu_choice.txt

    choice=$(cat menu_choice.txt)
    case $choice in
        1)
            show_network_menu "$backtitle"
            ;;
        99)
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
           --menu "Choose an option:" 15 50 3 \
           1 "Easy_PiVPN.sh" \
           99 "Back to Deployment Menu" 2>menu_choice.txt

    choice=$(cat menu_choice.txt)
    case $choice in
        1)
            bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh" && read -p "Press Enter..."
            ;;
        99)
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
           --menu "Choose an option:" 15 50 3 \
           1 "Raspberry_Pi_Custom.sh" \
           99 "Back to Main Menu" 2>menu_choice.txt

    choice=$(cat menu_choice.txt)
    case $choice in
        1)
            execute_script "https://raw.githubusercontent.com/your_username/your_repo/main/Raspberry_Pi_Custom.sh"
            ;;
        99)
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

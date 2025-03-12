#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("lxpanelctl" "lxappearance" "pcmanfm" "wget" "sed" "whiptail" "pipx" "zsh-syntax-highlighting" "zsh-autosuggestions")
    local all_installed=true

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            whiptail --title "Dependency Check" --msgbox "$dep is not installed. Installing..." 8 50
            sudo apt-get update
            if sudo apt-get install -y $dep; then
                whiptail --title "Dependency Check" --msgbox "$dep has been installed successfully." 8 50
            else
                whiptail --title "Dependency Check" --msgbox "Failed to install $dep. Please check your package manager." 8 50
                all_installed=false
            fi
        else
            whiptail --title "Dependency Check" --msgbox "$dep is already installed." 8 50
        fi
    done

    if $all_installed; then
        whiptail --title "Dependency Check" --msgbox "All dependencies are installed." 8 50
    fi
}

# Function to detect the default terminal application
detect_default_terminal() {
    local default_terminal=$(xdg-mime query default inode/directory)
    if [ -z "$default_terminal" ]; then
        whiptail --title "Default Terminal" --msgbox "No default terminal detected." 8 50
    else
        whiptail --title "Default Terminal" --msgbox "Default terminal detected: $default_terminal" 8 50
    fi
}

# Function to ask if the user wants to install Terminator
ask_install_terminator() {
    if command -v terminator &> /dev/null; then
        whiptail --title "Terminator Check" --msgbox "Terminator is already installed." 8 50
        return
    fi

    if (whiptail --title "Install Terminator" --yesno "Do you want to install Terminator as your terminal emulator?" 10 50); then
        whiptail --title "Installing Terminator" --msgbox "Installing Terminator..." 8 50
        sudo apt-get update
        if sudo apt-get install -y terminator; then
            whiptail --title "Terminator Installation" --msgbox "Terminator has been installed successfully." 8 50
        else
            whiptail --title "Terminator Installation" --msgbox "Failed to install Terminator. Please check your package manager." 8 50
        fi
    else
        whiptail --title "Terminator Installation" --msgbox "Terminator installation skipped." 8 50
    fi
}

# Function to ask if the user wants to switch to zsh
ask_switch_to_zsh() {
    local current_shell=$(basename "$SHELL")
    if [ "$current_shell" != "zsh" ]; then
        if (whiptail --title "Switch to Zsh" --yesno "Do you want to switch your default shell to Zsh?" 10 50); then
            whiptail --title "Installing Zsh" --msgbox "Installing Zsh..." 8 50
            sudo apt-get update
            if sudo apt-get install -y zsh; then
                whiptail --title "Downloading Configuration" --msgbox "Downloading .zshrc and .zsh_aliases..." 8 50
                if curl -o ~/.zshrc https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zshrc && \
                   curl -o ~/.zsh_aliases https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zsh_aliases; then
                    whiptail --title "Setting Default Shell" --msgbox "Setting Zsh as default shell..." 8 50
                    chsh -s $(which zsh)
                    whiptail --title "Zsh Installation" --msgbox "Zsh is now the default shell. Please reboot to see the changes." 8 50
                else
                    whiptail --title "Configuration Error" --msgbox "Failed to download Zsh configuration files." 8 50
                fi
            else
                whiptail --title "Zsh Installation" --msgbox "Failed to install Zsh. Please check your package manager." 8 50
            fi
        else
            whiptail --title "Zsh Installation" --msgbox "Zsh installation skipped." 8 50
        fi
    else
        whiptail --title "Zsh Check" --msgbox "Zsh is already the default shell." 8 50
    fi
}

# Function to move the taskbar to the bottom
move_taskbar_to_bottom() {
    whiptail --title "Moving Taskbar" --msgbox "Moving taskbar to the bottom..." 8 50
    if grep -q "position=top" ~/.config/lxpanel/LXDE-pi/panels/panel; then
        if sed -i 's/position=top/position=bottom/' ~/.config/lxpanel/LXDE-pi/panels/panel; then
            lxpanelctl restart
            whiptail --title "Taskbar Position" --msgbox "Taskbar moved to the bottom." 8 50
        else
            whiptail --title "Taskbar Position" --msgbox "Failed to update taskbar position." 8 50
        fi
    else
        whiptail --title "Taskbar Position" --msgbox "Taskbar is already at the bottom or not found." 8 50
    fi
}

# Function to enable dark mode
enable_dark_mode() {
    whiptail --title "Enabling Dark Mode" --msgbox "Enabling dark mode..." 8 50
    if ! grep -q "gtk-theme-name=Dark" ~/.config/lxsession/LXDE-pi/desktop.conf; then
        if echo "gtk-theme-name=Dark" >> ~/.config/lxsession/LXDE-pi/desktop.conf; then
            whiptail --title "Dark Mode Configuration" --msgbox "Dark mode configuration added." 8 50
        else
            whiptail --title "Dark Mode Configuration" --msgbox "Failed to add dark mode configuration." 8 50
        fi
    else
        whiptail --title "Dark Mode Check" --msgbox "Dark mode is already enabled." 8 50
    fi

    whiptail --title "Launching lxappearance" --msgbox "Launching lxappearance for 5 seconds..." 8 50
    timeout 5 lxappearance
    whiptail --title "Logout Reminder" --msgbox "Please log out and log back in to apply the changes." 8 50
}

# Function to set a custom wallpaper
set_custom_wallpaper() {
    local wallpaper_url="https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Wallpaper.png"
    local wallpaper_path="/usr/share/rpd-wallpaper/Wallpaper.png"

    whiptail --title "Setting Wallpaper" --msgbox "Downloading and setting custom wallpaper..." 8 50
    if sudo wget -O "$wallpaper_path" "$wallpaper_url"; then
        if command -v pcmanfm &> /dev/null; then
            pcmanfm --set-wallpaper="$wallpaper_path"
        else
            whiptail --title "Wallpaper Error" --msgbox "pcmanfm is not installed. Please install it to set the wallpaper." 8 50
        fi
    else
        whiptail --title "Wallpaper Error" --msgbox "Failed to download the wallpaper." 8 50
    fi
}

# Main function to run the script
main() {
    check_dependencies
    detect_default_terminal
    ask_install_terminator
    ask_switch_to_zsh
    move_taskbar_to_bottom
    enable_dark_mode
    set_custom_wallpaper

    whiptail --title "Completion" --msgbox "Customization complete! Please restart your device to see all changes." 8 50
}

# Execute the main function
main

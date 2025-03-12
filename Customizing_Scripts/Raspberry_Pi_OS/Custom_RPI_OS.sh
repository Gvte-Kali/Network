#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("lxpanelctl" "lxappearance" "pcmanfm" "wget" "sed" "dialog" "pipx" "zsh-syntax-highlighting" "zsh-autosuggestions")

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo "$dep is not installed. Installing..."
            sudo apt-get update
            sudo apt-get install -y $dep
        else
            echo "$dep is already installed."
        fi
    done
}

# Function to detect the default terminal application
detect_default_terminal() {
    local default_terminal=$(xdg-mime query default inode/directory)
    echo "Default terminal detected: $default_terminal"
}

# Function to ask if the user wants to install terminator
ask_install_terminator() {
    # Check if Terminator is already installed
    if dpkg -l | grep -q terminator; then
        echo "Terminator is already installed."
        return
    fi

    dialog --title "Install Terminator" \
           --yesno "Do you want to install Terminator as your terminal emulator?" 10 50
    local response=$?
    if [ $response -eq 0 ]; then
        echo "Installing Terminator..."
        sudo apt-get update
        sudo apt-get install -y terminator
    else
        echo "Terminator installation skipped."
    fi
}

# Function to ask if the user wants to switch to zsh
ask_switch_to_zsh() {
    local current_shell=$(basename "$SHELL")
    if [ "$current_shell" != "zsh" ]; then
        dialog --title "Switch to Zsh" \
               --yesno "Do you want to switch your default shell to Zsh?" 10 50
        local response=$?
        if [ $response -eq 0 ]; then
            echo "Installing Zsh..."
            sudo apt-get update
            sudo apt-get install -y zsh
            
            # Download .zshrc and .zsh_aliases
            echo "Downloading .zshrc and .zsh_aliases..."
            curl -o ~/.zshrc https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zshrc
            curl -o ~/.zsh_aliases https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zsh_aliases
            
            # Set Zsh as the default shell
            echo "Setting Zsh as default shell..."
            chsh -s $(which zsh)


            echo "Zsh is now the default shell. Please reboot to see the changes."
        else
            echo "Zsh installation skipped."
        fi
    else
        echo "Zsh is already the default shell."
    fi
}

# Move the taskbar to the bottom
move_taskbar_to_bottom() {
    echo "Moving taskbar to the bottom..."
    if grep -q "position=top" ~/.config/lxpanel/LXDE-pi/panels/panel; then
        sed -i 's/position=top/position=bottom/' ~/.config/lxpanel/LXDE-pi/panels/panel
        lxpanelctl restart
        echo "Taskbar moved to the bottom."
    else
        echo "Taskbar is already at the bottom or not found."
    fi
}

# Enable dark mode
enable_dark_mode() {
    echo "Enabling dark mode..."
    if ! grep -q "gtk-theme-name=Dark" ~/.config/lxsession/LXDE-pi/desktop.conf; then
        echo "gtk-theme-name=Dark" >> ~/.config/lxsession/LXDE-pi/desktop.conf
        echo "Dark mode configuration added."
    else
        echo "Dark mode is already enabled."
    fi

    # Launch lxappearance and close it after 5 seconds
    timeout 5 lxappearance
    echo "Please log out and log back in to apply the changes."
}

# 3. Set custom wallpaper
set_custom_wallpaper() {
    local wallpaper_url="https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Wallpaper.png"
    local wallpaper_path="/usr/share/rpd-wallpaper/Wallpaper.png"

    echo "Downloading and setting custom wallpaper..."
    sudo wget -O "$wallpaper_path" "$wallpaper_url"

    if command -v pcmanfm &> /dev/null; then
        pcmanfm --set-wallpaper="$wallpaper_path"
    else
        echo "pcmanfm is not installed. Please install it to set the wallpaper."
    fi
}

# Main function to run all customizations
main() {
    # Check and install dependencies
    check_dependencies

    # Detect default terminal and ask about Terminator
    detect_default_terminal
    ask_install_terminator

    # Ask about switching to Zsh
    ask_switch_to_zsh

    # Apply customizations
    move_taskbar_to_bottom
    enable_dark_mode
    set_custom_wallpaper

    #Return to Deployment Script
    wget -O /tmp/Deployment.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Deployment.sh && chmod +x /tmp/Deployment.sh && bash /tmp/Deployment.sh

    echo "Customization complete! Please restart your device to see all changes."
}

# Execute the main function
main

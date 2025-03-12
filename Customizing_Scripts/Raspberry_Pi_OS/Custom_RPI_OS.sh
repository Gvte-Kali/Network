#!/bin/bash

# Function to check and install dependencies
check_dependencies() {
    local dependencies=("lxpanelctl" "lxappearance" "pcmanfm" "wget" "sed" "whiptail" "pipx" "zsh-syntax-highlighting" "zsh-autosuggestions")
    local all_installed=true

    for dep in "${dependencies[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo "$dep is not installed. Installing..."
            sudo apt-get update
            if sudo apt-get install -y $dep; then
                echo "$dep has been installed successfully."
            else
                echo "Failed to install $dep. Please check your package manager."
                all_installed=false
            fi
        else
            echo "$dep is already installed."
        fi
    done

    if $all_installed; then
        echo "All dependencies are installed."
    fi
}

# Function to detect the default terminal application
detect_default_terminal() {
    local default_terminal=$(xdg-mime query default inode/directory)
    if [ -z "$default_terminal" ]; then
        echo "No default terminal detected."
    else
        echo "Default terminal detected: $default_terminal"
    fi
}

# Function to ask if the user wants to install Terminator
ask_install_terminator() {
    if command -v terminator &> /dev/null; then
        echo "Terminator is already installed."
        return
    fi

    if (whiptail --title "Install Terminator" --yesno "Do you want to install Terminator as your terminal emulator?" 10 50); then
        echo "Installing Terminator..."
        sudo apt-get update
        if sudo apt-get install -y terminator; then
            echo "Terminator has been installed successfully."
        else
            echo "Failed to install Terminator. Please check your package manager."
        fi
    else
        echo "Terminator installation skipped."
    fi
}

# Function to ask if the user wants to switch to zsh
ask_switch_to_zsh() {
    local current_shell=$(basename "$SHELL")
    if [ "$current_shell" != "zsh" ]; then
        if (whiptail --title "Switch to Zsh" --yesno "Do you want to switch your default shell to Zsh?" 10 50); then
            echo "Installing Zsh..."
            sudo apt-get update
            if sudo apt-get install -y zsh; then
                echo "Downloading .zshrc and .zsh_aliases..."
                if curl -o ~/.zshrc https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zshrc && \
                   curl -o ~/.zsh_aliases https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zsh_aliases; then
                    echo "Setting Zsh as default shell..."
                    chsh -s $(which zsh)
                    echo "Zsh is now the default shell. Please reboot to see the changes."
                else
                    echo "Failed to download Zsh configuration files."
                fi
            else
                echo "Failed to install Zsh. Please check your package manager."
            fi
        else
            echo "Zsh installation skipped."
        fi
    else
        echo "Zsh is already the default shell."
    fi
}

# Function to move the taskbar to the bottom
move_taskbar_to_bottom() {
    echo "Moving taskbar to the bottom..."
    if grep -q "position=top" ~/.config/lxpanel/LXDE-pi/panels/panel; then
        if sed -i 's/position=top/position=bottom/' ~/.config/lxpanel/LXDE-pi/panels/panel; then
            lxpanelctl restart
            echo "Taskbar moved to the bottom."
        else
            echo "Failed to update taskbar position."
        fi
    else
        echo "Taskbar is already at the bottom or not found."
    fi
}

# Function to enable dark mode
enable_dark_mode() {
    echo "Enabling dark mode..."
    if ! grep -q "gtk-theme-name=Dark" ~/.config/lxsession/LXDE-pi/desktop.conf; then
        if echo "gtk-theme-name=Dark" >> ~/.config/lxsession/LXDE-pi/desktop.conf; then
            echo "Dark mode configuration added."
        else
            echo "Failed to add dark mode configuration."
        fi
    else
        echo "Dark mode is already enabled."
    fi

    echo "Launching lxappearance for 5 seconds..."
    timeout 5 lxappearance
    echo "Please log out and log back in to apply the changes."
}

# Function to set a custom wallpaper
set_custom_wallpaper() {
    local wallpaper_url="https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Wallpaper.png"
    local wallpaper_path="/usr/share/rpd-wallpaper/Wallpaper.png"

    echo "Downloading and setting custom wallpaper..."
    if sudo wget -O "$wallpaper_path" "$wallpaper_url"; then
        if command -v pcmanfm &> /dev/null; then
            pcmanfm --set-wallpaper="$wallpaper_path"
            echo "Custom wallpaper set successfully."
        else
            echo "pcmanfm is not installed. Please install it to set the wallpaper."
        fi
    else
        echo "Failed to download the wallpaper."
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

    echo "Customization complete! Please restart your device to see all changes."
}

# Execute the main function
main

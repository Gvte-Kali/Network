import curses
import os
import subprocess

def check_dependencies(stdscr):
    dependencies = ["lxpanelctl", "lxappearance", "pcmanfm", "wget", "sed", "dialog", "pipx", "zsh-syntax-highlighting", "zsh-autosuggestions"]
    for dep in dependencies:
        if os.system(f"command -v {dep}") != 0:
            stdscr.addstr(f"{dep} is not installed. Installing...\n")
            os.system("sudo apt-get update")
            os.system(f"sudo apt-get install -y {dep}")
        else:
            stdscr.addstr(f"{dep} is already installed.\n")
        stdscr.refresh()
        stdscr.getch()

def detect_default_terminal(stdscr):
    default_terminal = subprocess.getoutput("xdg-mime query default inode/directory")
    stdscr.addstr(f"Default terminal detected: {default_terminal}\n")
    stdscr.refresh()
    stdscr.getch()

def ask_install_terminator(stdscr):
    if os.system("dpkg -l | grep -q terminator") == 0:
        stdscr.addstr("Terminator is already installed.\n")
        stdscr.refresh()
        stdscr.getch()
        return

    stdscr.addstr("Do you want to install Terminator as your terminal emulator? (y/n): ")
    stdscr.refresh()
    response = stdscr.getch()
    if response == ord('y'):
        stdscr.addstr("Installing Terminator...\n")
        os.system("sudo apt-get update")
        os.system("sudo apt-get install -y terminator")
    else:
        stdscr.addstr("Terminator installation skipped.\n")
    stdscr.refresh()
    stdscr.getch()

def ask_switch_to_zsh(stdscr):
    current_shell = os.path.basename(os.environ['SHELL'])
    if current_shell != "zsh":
        stdscr.addstr("Do you want to switch your default shell to Zsh? (y/n): ")
        stdscr.refresh()
        response = stdscr.getch()
        if response == ord('y'):
            stdscr.addstr("Installing Zsh...\n")
            os.system("sudo apt-get update")
            os.system("sudo apt-get install -y zsh")
            
            stdscr.addstr("Downloading .zshrc and .zsh_aliases...\n")
            os.system("curl -o ~/.zshrc https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zshrc")
            os.system("curl -o ~/.zsh_aliases https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/.zsh_aliases")
            
            stdscr.addstr("Setting Zsh as default shell...\n")
            os.system("chsh -s $(which zsh)")
            stdscr.addstr("Zsh is now the default shell. Please reboot to see the changes.\n")
        else:
            stdscr.addstr("Zsh installation skipped.\n")
    else:
        stdscr.addstr("Zsh is already the default shell.\n")
    stdscr.refresh()
    stdscr.getch()

def move_taskbar_to_bottom(stdscr):
    stdscr.addstr("Moving taskbar to the bottom...\n")
    if os.system("grep -q 'position=top' ~/.config/lxpanel/LXDE-pi/panels/panel") == 0:
        os.system("sed -i 's/position=top/position=bottom/' ~/.config/lxpanel/LXDE-pi/panels/panel")
        os.system("lxpanelctl restart")
        stdscr.addstr("Taskbar moved to the bottom.\n")
    else:
        stdscr.addstr("Taskbar is already at the bottom or not found.\n")
    stdscr.refresh()
    stdscr.getch()

def enable_dark_mode(stdscr):
    stdscr.addstr("Enabling dark mode...\n")
    if os.system("grep -q 'gtk-theme-name=Dark' ~/.config/lxsession/LXDE-pi/desktop.conf") != 0:
        os.system("echo 'gtk-theme-name=Dark' >> ~/.config/lxsession/LXDE-pi/desktop.conf")
        stdscr.addstr("Dark mode configuration added.\n")
    else:
        stdscr.addstr("Dark mode is already enabled.\n")
    
    stdscr.addstr("Launching lxappearance for 5 seconds...\n")
    os.system("timeout 5 lxappearance")
    stdscr .addstr("Please log out and log back in to apply the changes.\n")
    stdscr.refresh()
    stdscr.getch()

def set_custom_wallpaper(stdscr):
    wallpaper_url = "https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Wallpaper.png"
    wallpaper_path = "/usr/share/rpd-wallpaper/Wallpaper.png"

    stdscr.addstr("Downloading and setting custom wallpaper...\n")
    os.system(f"sudo wget -O {wallpaper_path} {wallpaper_url}")

    if os.system("command -v pcmanfm &> /dev/null") == 0:
        os.system(f"pcmanfm --set-wallpaper={wallpaper_path}")
    else:
        stdscr.addstr("pcmanfm is not installed. Please install it to set the wallpaper.\n")
    stdscr.refresh()
    stdscr.getch()

def main(stdscr):
    curses.cbreak()
    curses.noecho()

    check_dependencies(stdscr)
    detect_default_terminal(stdscr)
    ask_install_terminator(stdscr)
    ask_switch_to_zsh(stdscr)
    move_taskbar_to_bottom(stdscr)
    enable_dark_mode(stdscr)
    set_custom_wallpaper(stdscr)

    stdscr.addstr("Customization complete! Please restart your device to see all changes.\n")
    stdscr.refresh()
    stdscr.getch()

curses.wrapper(main)  # Run the program

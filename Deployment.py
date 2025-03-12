import curses
import os

def check_dependencies():
    dependencies = ["wget", "ansible"]
    for dep in dependencies:
        if os.system(f"command -v {dep}") != 0:
            stdscr.addstr(f"{dep} is not installed. Installing...\n")
            os.system("sudo apt-get update")
            os.system(f"sudo apt-get install -y {dep}")

def show_menu(title, options):
    stdscr.clear()
    stdscr.addstr(title + "\n\n")
    for i, option in enumerate(options):
        stdscr.addstr(f"{i + 1}. {option}\n")
    stdscr.addstr("\nChoose an option: ")
    stdscr.refresh()

def execute_script(url):
    command = f"wget -O /tmp/script.sh {url} && chmod +x /tmp/script.sh && bash /tmp/script.sh && rm /tmp/script.sh"
    if os.system(command) != 0:
        stdscr.addstr("Error downloading the script.\n")
        stdscr.refresh()
        stdscr.getch()

def show_main_menu():
    options = ["Deployment Scripts", "Customizing Scripts", "Exit"]
    while True:
        show_menu("Configuration Menu", options)
        choice = stdscr.getch() - ord('0')  # Convert ASCII to integer
        if 1 <= choice <= len(options):
            if choice == 1:
                show_deployment_menu()
            elif choice == 2:
                show_customizing_menu()
            elif choice == 3:
                break
        else:
            stdscr.addstr("Invalid choice. Please try again.\n")
            stdscr.refresh()
            stdscr.getch()

def show_deployment_menu():
    options = ["Network", "Back to Main Menu"]
    while True:
        show_menu("Deployment Scripts", options)
        choice = stdscr.getch() - ord('0')
        if 1 <= choice <= len(options):
            if choice == 1:
                show_network_menu()
            elif choice == 2:
                return  # Back to main menu
        else:
            stdscr.addstr("Invalid choice. Please try again.\n")
            stdscr.refresh()
            stdscr.getch()

def show_network_menu():
    options = ["Easy_PiVPN.sh", "Back to Deployment Menu"]
    while True:
        show_menu("Network Scripts", options)
        choice = stdscr.getch() - ord('0')
        if 1 <= choice <= len(options):
            if choice == 1:
                execute_script("https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh")
            elif choice == 2:
                return  # Back to deployment menu
        else:
            stdscr.addstr("Invalid choice. Please try again.\n")
            stdscr.refresh()
            stdscr.getch()

def show_customizing_menu():
    options = ["Raspberry_Pi_Customization", "Back to Main Menu"]
    while True:
        show_menu("Customizing Scripts", options)
        choice = stdscr.getch() - ord('0')
        if 1 <= choice <= len(options):
            if choice == 1:
                execute_script("https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Customizing_Scripts/Raspberry_Pi_OS/Custom_RPI_OS.sh")
            elif choice == 2:
                return  # Back to main menu
        else:
            stdscr.addstr("Invalid choice. Please try again.\n")
            stdscr.refresh()
            stdscr.getch()

def main(stdscr):
    curses.cbreak()  # Disable line buffering
    curses.noecho()  # Do not echo user input

    check_dependencies()  # Check and install dependencies
    show_main_menu()      # Display the main menu

curses.wrapper(main)  # Run the program

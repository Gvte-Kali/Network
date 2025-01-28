# Easy_PiVPN: The Easy Way to Get a Personal VPN

This guide explains how to install PiVPN on your device (ideally a Raspberry Pi 4 or 5).

## Steps

Before you begin, ensure you have the following:

1. **A Raspberry Pi** (preferably 4 or 5) with Raspbian installed.
2. **Sudo privileges**: You need to run the installation script with sudo.
3. **A Discord Webhook**: Set up a Discord webhook to send messages. You can create a webhook by following these steps:
   - Go to your Discord server settings.
   - Navigate to the "Integrations" section.
   - Create a new webhook and copy the URL.
   - Save the webhook URL somewhere on your raspberry so you can copy and paste it easily.
4. **Setup internet connection**
5. **Use One-command to install**

## One-command to install

For devices with graphical interfaces:

```bash
wget -O ~/Desktop/PiVPN_Setup.desktop https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/PiVPN_Setup.desktop
```
For headless devices ( no user interface ) : 
```bash
bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh" && read -p "Press Enter..."
```
## Overview
![Overview of the final result](https://raw.githubusercontent.com/username/repo/branch/path/to/image.png](https://github.com/Gvte-Kali/Network/blob/main/Easy_PiVPN/Easy_PiVPN_Overview.png)


## Configuration Steps

1. **Preparing Directories**: The script will create necessary directories for configuration files.
2. **Updating Packages and Installing OpenVPN**: The script will update your system and install OpenVPN.
3. **Installing RustDesk**: Optional remote desktop software installation.
4. **Display Network Information**: The script will show your current network configuration.
5. **Configure Autologin**: Set up your Raspberry Pi to log in automatically.
6. **Discord and Cronjob Configuration**: Set up a cron job to send updates to Discord.
7. **PiVPN Installation**: Install PiVPN on your Raspberry Pi.
8. **Routing and NAT Configuration for VPN to LAN Tunnel**: Configure routing to allow VPN access to your local network.
9. **NAT Configuration on Router**: Instructions for setting up NAT rules on your router.

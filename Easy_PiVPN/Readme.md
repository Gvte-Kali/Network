# Easy_PiVPN : the easy way to get a personnal VPN

This guide explains how to install PiVPN on your device ( ideally a Raspberry Pi 4 or 5 ).

## One-command to install.

For devices with graphical interfaces : 

```bash
wget -O ~/Desktop/PiVPN_Setup.desktop https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/PiVPN_Setup.desktop
```
For headless devices ( no user interface ) : 
```bash
bash -c "wget -O /tmp/setup.sh https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Easy_PiVPN/scripts/setup.sh && chmod +x /tmp/setup.sh && sudo bash /tmp/setup.sh" && read -p "Press Enter..."
```

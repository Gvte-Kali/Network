#!/bin/bash

# URL of the Python script
SCRIPT_URL="https://raw.githubusercontent.com/Gvte-Kali/Network/refs/heads/main/Deployment.py"

# Download the Python script
wget -O /tmp/your_script.py "$SCRIPT_URL"

# Check if the download was successful
if [ $? -eq 0 ]; then
    # Make the script executable
    chmod +x /tmp/your_script.py

    # Execute the script
    python3 /tmp/your_script.py

    # Clean up
    rm /tmp/your_script.py
else
    echo "Error downloading the script."
fi

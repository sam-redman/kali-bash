# Kali Bash

A comprehensive Bash script to automate the setup and configuration of a Kali Linux environment, including software installation, system tweaks, and user environment customization.

## Table of Contents

- [Requirements](#requirements)
- [Setup](#setup)
- [Features](#features)
- [Notes](#notes)

## Requirements

- Kali Linux
- Root privileges (sudo or root user)

## Setup

1. Clone or download this repository and navigate to the script directory.
2. Make the script executable:
    ```sh
    chmod +x kali-bash.sh
    ```
3. Run the script as root:
    ```sh
    sudo ./kali-bash.sh
    ```

## Notes

- The script is intended for a fresh Kali Linux installation.
- Some installations (e.g., Burp Suite) may require manual interaction.
- You can change the target user by editing the `TARGET_USER` variable at the top of the script.
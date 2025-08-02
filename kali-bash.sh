#!/bin/bash

set -e

# ==================== USER CONFIGURATION ====================
# Define the target user - change this if needed
TARGET_USER="kali"

# ==================== ASCII LOGO ====================
cat << "EOF"
         ▄              ▄
        ▌▒█           ▄▀▒▌
        ▌▒▒█        ▄▀▒▒▒▐
       ▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐
     ▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐
   ▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌
  ▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒▌
  ▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐
 ▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌
 ▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌
▌▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒▐
▐▒▒▐▀▐▀▒░▄▄▒▄▒▒▒▒▒▒░▒░▒░▒▒▒▒▌
▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▐
 ▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒░▒░▒░▒░▒▒▒▌
 ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▄▒▒▐
  ▀▄▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▄▒▒▒▒▌
    ▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀
      ▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀
         ▒▒▒▒▒▒▒▒▒▒▀▀
EOF

echo "Starting system configuration..."
echo ""

# ==================== VARIABLES ====================
TERMINALRC_PATH="/home/$TARGET_USER/.config/xfce4/terminal/terminalrc"
ROCKYOU_WORDLIST_GZ="/usr/share/wordlists/rockyou.txt.gz"
ROCKYOU_WORDLIST_TXT="/usr/share/wordlists/rockyou.txt"
AUTOSTART_DIR="/home/$TARGET_USER/.config/autostart"
XFCE_POWER_XML="/home/$TARGET_USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml"
KEYBOARD_FILE="/etc/default/keyboard"
LOGS_DIR="/home/$TARGET_USER/Logs"
BASHRC="/home/$TARGET_USER/.bashrc"
SECLISTS_URL="https://github.com/danielmiessler/SecLists/archive/master.zip"
SECLISTS_DEST="/usr/share/wordlists"
JYTHON_URL="https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.3/jython-standalone-2.7.3.jar"
JARS_DIR="/home/$TARGET_USER/JARs"
TOOLS_DIR="/home/$TARGET_USER/Tools"
VPN_DIR="/home/$TARGET_USER/VPN"
LICENSES_DIR="/home/$TARGET_USER/Licenses"
CERTIFICATES_DIR="/home/$TARGET_USER/Certificates"
BURP_INSTALLER_URL="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Linux"

# ==================== PACKAGES & SOFTWARE ====================
echo "[*] Processing packages and software..."

# Update package list
echo "    - Updating package list..."
apt-get update -qq

# Install Firefox (non-ESR)
echo "    - Installing Firefox..."
apt-get install -y -qq firefox

# Install LibreOffice
echo "    - Installing LibreOffice..."
apt-get install -y -qq libreoffice

# Install Docker
echo "    - Installing Docker..."
apt-get install -y -qq docker.io

# Install Flameshot
echo "    - Installing Flameshot..."
apt-get install -y -qq flameshot

# Install additional dependencies for SecLists download
echo "    - Installing download utilities..."
apt-get install -y -qq wget unzip curl

# Install isc-dhcp-client
echo "    - Installing isc-dhcp-client..."
apt-get install -y -qq isc-dhcp-client

# Download and install Burp Suite Professional
echo "    - Downloading Burp Suite Professional..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
wget -q -O burpsuite_pro_linux.sh "$BURP_INSTALLER_URL"
chmod +x burpsuite_pro_linux.sh
echo "    - Installing Burp Suite Professional..."
# Run installer in unattended mode if supported, otherwise manual intervention needed
if ./burpsuite_pro_linux.sh --help 2>&1 | grep -q "unattended"; then
    ./burpsuite_pro_linux.sh --unattended
else
    echo "      Note: Burp Suite installer may require manual interaction"
    ./burpsuite_pro_linux.sh
fi
cd - > /dev/null
rm -rf "$TEMP_DIR"

# Download Jython standalone
echo "    - Downloading Jython standalone..."
mkdir -p "$JARS_DIR"
if [ ! -f "$JARS_DIR/jython-standalone-2.7.3.jar" ]; then
    wget -q -O "$JARS_DIR/jython-standalone-2.7.3.jar" "$JYTHON_URL"
    chown "$TARGET_USER:$TARGET_USER" "$JARS_DIR/jython-standalone-2.7.3.jar"
    echo "      Jython standalone downloaded to $JARS_DIR"
else
    echo "      Jython standalone already exists"
fi

# Download and extract SecLists
if [ ! -d "$SECLISTS_DEST/SecLists-master" ]; then
    echo "    - Downloading SecLists..."
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if command -v wget > /dev/null; then
        wget -c "$SECLISTS_URL" -O SecLists-master.zip
    elif command -v curl > /dev/null; then
        curl -L -o SecLists-master.zip "$SECLISTS_URL"
    else
        echo "    ! Error: Neither wget nor curl is installed. Cannot download SecLists."
        exit 1
    fi
    
    echo "    - Extracting SecLists..."
    unzip -q SecLists-master.zip
    
    echo "    - Moving SecLists to $SECLISTS_DEST..."
    mv SecLists-master "$SECLISTS_DEST/"
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "    - SecLists installed successfully"
else
    echo "    - SecLists already installed at $SECLISTS_DEST/SecLists-master"
fi

# Unzip rockyou wordlist
if [ -f "$ROCKYOU_WORDLIST_GZ" ] && [ ! -f "$ROCKYOU_WORDLIST_TXT" ]; then
    echo "    - Extracting rockyou wordlist..."
    gunzip -k "$ROCKYOU_WORDLIST_GZ"
fi

# ==================== DIRECTORY SETUP ====================
echo "[*] Setting up directories..."

# Create Logs directory
mkdir -p "$LOGS_DIR"
chown "$TARGET_USER:$TARGET_USER" "$LOGS_DIR"
chmod 0755 "$LOGS_DIR"
echo "    - Created Logs directory"

# Create Tools directory
mkdir -p "$TOOLS_DIR"
chown "$TARGET_USER:$TARGET_USER" "$TOOLS_DIR"
chmod 0755 "$TOOLS_DIR"
echo "    - Created Tools directory"

# Create VPN directory
mkdir -p "$VPN_DIR"
chown "$TARGET_USER:$TARGET_USER" "$VPN_DIR"
chmod 0700 "$VPN_DIR"  # More restrictive for VPN configs
echo "    - Created VPN directory"

# Create Licenses directory
mkdir -p "$LICENSES_DIR"
chown "$TARGET_USER:$TARGET_USER" "$LICENSES_DIR"
chmod 0700 "$LICENSES_DIR"  # More restrictive for licenses
echo "    - Created Licenses directory"

# Create Certificates directory
mkdir -p "$CERTIFICATES_DIR"
chown "$TARGET_USER:$TARGET_USER" "$CERTIFICATES_DIR"
chmod 0700 "$CERTIFICATES_DIR"  # More restrictive for certificates
echo "    - Created Certificates directory"

# Ensure JARs directory has correct permissions
chown -R "$TARGET_USER:$TARGET_USER" "$JARS_DIR"
chmod 0755 "$JARS_DIR"

# ==================== TERMINAL CONFIGURATION ====================
echo "[*] Configuring terminal..."

# Set terminal transparency to 0 (no transparency)
mkdir -p "$(dirname "$TERMINALRC_PATH")"
if grep -q '^Transparency=' "$TERMINALRC_PATH" 2>/dev/null; then
    sed -i 's/^Transparency=.*/Transparency=0/' "$TERMINALRC_PATH"
else
    echo 'Transparency=0' >> "$TERMINALRC_PATH"
fi
chown "$TARGET_USER:$TARGET_USER" "$TERMINALRC_PATH"
chmod 0644 "$TERMINALRC_PATH"
echo "    - Terminal transparency disabled"

# ==================== AUTOSTART APPLICATIONS ====================
echo "[*] Configuring autostart applications..."

# Ensure Flameshot autostarts for user
mkdir -p "$AUTOSTART_DIR"
cat > "$AUTOSTART_DIR/flameshot.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=flameshot
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Flameshot
Comment=Start Flameshot at login
EOF
chown "$TARGET_USER:$TARGET_USER" "$AUTOSTART_DIR/flameshot.desktop"
chmod 0644 "$AUTOSTART_DIR/flameshot.desktop"
echo "    - Flameshot set to autostart"

# ==================== XFCE SETTINGS ====================
echo "[*] Configuring XFCE settings..."

# Disable auto-lock in XFCE
mkdir -p "$(dirname "$XFCE_POWER_XML")"
if grep -q '<property name="lock-screen-suspend-hibernate"' "$XFCE_POWER_XML" 2>/dev/null; then
    sed -i 's|<property name="lock-screen-suspend-hibernate".*|<property name="lock-screen-suspend-hibernate" type="bool" value="false"/>|' "$XFCE_POWER_XML"
else
    echo '<property name="lock-screen-suspend-hibernate" type="bool" value="false"/>' >> "$XFCE_POWER_XML"
fi
chown "$TARGET_USER:$TARGET_USER" "$XFCE_POWER_XML"
chmod 0644 "$XFCE_POWER_XML"
echo "    - Auto-lock disabled"

# ==================== SYSTEM CONFIGURATION ====================
echo "[*] Configuring system settings..."

# Recommend persistent DNS and DHCP configuration
echo "    - To set persistent DNS and DHCP, edit your network interfaces file:"
echo "      Run: sudo nano /etc/network/interfaces"
echo "      And use the following content:"
echo ""
echo "source /etc/network/interfaces.d/*"
echo ""
echo "auto lo"
echo "iface lo inet loopback"
echo ""
echo "auto eth0"
echo "iface eth0 inet dhcp"
echo "    dns-nameservers 8.8.8.8 8.8.4.4 1.1.1.1 1.0.0.1"
echo ""

# Set keyboard layout to gb
if grep -q '^XKBLAYOUT=' "$KEYBOARD_FILE"; then
    sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="gb"/' "$KEYBOARD_FILE"
else
    echo 'XKBLAYOUT="gb"' >> "$KEYBOARD_FILE"
fi
chown root:root "$KEYBOARD_FILE"
chmod 0644 "$KEYBOARD_FILE"
echo "    - Keyboard layout set to GB"

# ==================== SESSION LOGGING ====================
echo "[*] Configuring session logging..."

# Enable session logging in bashrc
if ! grep -q '^# Session logging' "$BASHRC"; then
    cat <<'EOL' >> "$BASHRC"

# Session logging
export LOG_DIR="$HOME/Logs"
export PROMPT_COMMAND='RETRN_VAL=$?; echo "$(date +"%Y-%m-%d %T") $(whoami) $(history 1 | sed "s/^ *[0-9]* *//")" >> $LOG_DIR/session.log'
EOL
    chown "$TARGET_USER:$TARGET_USER" "$BASHRC"
    chmod 0644 "$BASHRC"
    echo "    - Session logging enabled"
fi

==================== COMPLETION ====================
echo ""
echo "[✓] All tasks completed successfully!"
echo ""
echo "=============================================="
echo "Manual Setup Steps:"
echo "1. Launch Mozilla Firefox at least once."
echo "2. Install these recommended extensions:"
echo "   - Cookie-Editor"
echo "   - FoxyProxy"
echo "   - Hack-Tools"
echo "   - Wappalyzer"
echo "3. Move all default bookmarks to a folder named 'Default'."
echo "4. Add bookmarks for:"
echo "     - Notion"
echo "     - Poe"
echo "     - HackTricks Assistant"
echo "     - HackTricks"
echo "5. Set up the Burp Suite certificate in Firefox (for HTTPS interception)."
echo "6. Configure FoxyProxy:"
echo "     - Add a profile for Burp: 127.0.0.1:1080"
echo "     - Add a profile for Proxychains: 127.0.0.1:<proxychains.conf-port-here>"
echo "=============================================="
#!/bin/bash
# Full fixed setup.sh script for macOS VNC configuration
# Usage: ./setup.sh VNC_USER_PASSWORD VNC_PASSWORD NGROK_AUTH_TOKEN

# Disable spotlight indexing
sudo mdutil -i off -a

# Create new user account with proper home directory
sudo dscl . -create /Users/KrypticBit
sudo dscl . -create /Users/KrypticBit UserShell /bin/bash
sudo dscl . -create /Users/KrypticBit RealName "KrypticBit"
sudo dscl . -create /Users/KrypticBit UniqueID 1001
sudo dscl . -create /Users/KrypticBit PrimaryGroupID 80
sudo dscl . -create /Users/KrypticBit NFSHomeDirectory /Users/KrypticBit
sudo dscl . -passwd /Users/KrypticBit $1
sudo createhomedir -c -u KrypticBit > /dev/null

# Configure Remote Management and VNC
sudo systemsetup -setremotelogin on
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -access -on \
  -clientopts -setvnclegacy -vnclegacy yes \
  -clientopts -setvncpw -vncpw $(echo "$2" | perl -MCrypt::PasswdMD5 -nle 'print unix_md5_crypt($_)') \
  -restart -agent -privs -all

# Set VNC password using modern method
echo "$2" | sudo vncpasswd -service
sudo /usr/bin/defaults write /Library/Preferences/com.apple.RemoteManagement.plist VNCPassword -data $(echo "$2" | openssl base64)

# Configure energy settings to prevent sleep
sudo systemsetup -setdisplaysleep 0
sudo pmset -a displaysleep 0

# Enable performance mode
sudo nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"

# Configure multi-session and security settings
sudo /usr/bin/defaults write /Library/Preferences/.GlobalPreferences MultipleSessionsEnabled -bool TRUE
sudo defaults write /Library/Preferences/com.apple.loginwindow DisableScreenLock -bool true
sudo defaults write /Library/Preferences/com.apple.loginwindow AllowList -array '*'

# Reset privacy permissions
sudo tccutil reset ScreenCapture
sudo tccutil reset Accessibility

# Install required packages
brew install --cask ngrok teamviewer firefox folx

# Configure ngrok with delay to ensure VNC is ready
( sleep 15 && ngrok authtoken $3 && ngrok tcp 5900 --region=in ) &

# Diagnostic commands
echo "=== Verification Commands ==="
echo "1. VNC Port Listening:"
sudo netstat -an | grep 5900
echo "2. Screen Sharing Logs:"
tail -f /var/log/system.log | grep -i "screen sharing"
echo "3. User Sessions:"
who
echo "4. Remote Management Status:"
sudo systemsetup -getremotelogin

# Keep the session alive for troubleshooting
while true; do sleep 60; done

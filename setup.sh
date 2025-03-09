#!/bin/bash
# Revised setup.sh script with error corrections
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
sudo mkdir -p /Users/KrypticBit
sudo chown KrypticBit:staff /Users/KrypticBit

# Configure Remote Management and VNC
sudo systemsetup -setremotelogin on

# Legacy VNC password configuration
echo $2 | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8})./$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt

# Restart Remote Management
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -access -on \
  -clientopts -setvnclegacy -vnclegacy yes \
  -restart -agent -privs -all

# Configure energy settings to prevent sleep
sudo systemsetup -setdisplaysleep 0
sudo pmset -a displaysleep 0

# Enable performance mode
sudo nvram boot-args="serverperfmode=1 $(nvram boot-args 2>/dev/null | cut -f 2-)"

# Configure multi-session and security settings
sudo defaults write /Library/Preferences/.GlobalPreferences MultipleSessionsEnabled -bool TRUE
sudo defaults write /Library/Preferences/com.apple.loginwindow DisableScreenLock -bool true
sudo defaults write /Library/Preferences/com.apple.loginwindow AllowList -array '*'

# Reset privacy permissions
sudo tccutil reset ScreenCapture
sudo tccutil reset Accessibility

# Install required packages
brew install --cask ngrok teamviewer firefox folx

# Configure ngrok with proper delay
( sleep 20 && ngrok authtoken $3 && ngrok tcp 5900 --region=in ) &

# Diagnostic commands
echo "=== Verification Commands ==="
echo "1. VNC Port Listening:"
sudo netstat -an | grep 5900
echo "2. User Sessions:"
who
echo "3. Remote Management Status:"
sudo systemsetup -getremotelogin

# Keep the session alive for troubleshooting
while true; do sleep 60; done

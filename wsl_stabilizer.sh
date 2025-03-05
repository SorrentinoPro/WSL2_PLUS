#!/bin/bash

# Exit on error and show commands
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if root to determine sudo usage
if [[ $EUID -eq 0 ]]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

# Install required packages
echo "Checking/Installing packages..."
packages=("pulseaudio" "alsa-utils" "x11-apps")
for pkg in "${packages[@]}"; do
    if ! dpkg -s $pkg &>/dev/null; then
        ${SUDO_CMD} apt-get install -y $pkg
        echo -e "${GREEN}Installed: $pkg${NC}"
    else
        echo -e "${GREEN}Already installed: $pkg${NC}"
    fi
done

# PulseAudio Configuration
echo -e "\nConfiguring PulseAudio..."
pulse_config_dir="$HOME/.config/pulse"
pulse_daemon_conf="$pulse_config_dir/daemon.conf"

# Create config directory if missing
[ ! -d "$pulse_config_dir" ] && mkdir -p "$pulse_config_dir"

# Configure daemon.conf
if [ ! -f "$pulse_daemon_conf" ] || ! grep -q "exit-idle-time" "$pulse_daemon_conf"; then
    cat <<-EOF >"$pulse_daemon_conf"
exit-idle-time = -1
flat-volumes = no
EOF
    echo -e "${GREEN}Created/Updated: $pulse_daemon_conf${NC}"
fi

# ALSA Configuration
echo -e "\nConfiguring ALSA..."
asoundrc="$HOME/.asoundrc"
if [ ! -f "$asoundrc" ]; then
    cat <<-EOF >"$asoundrc"
pcm.!default {
    type pulse
    hint.description "Default ALSA Device (PulseAudio)"
}

ctl.!default {
    type pulse
}
EOF
    echo -e "${GREEN}Created: $asoundrc${NC}"
fi

# X11 Display Configuration
echo -e "\nConfiguring X11 Display..."
bashrc="$HOME/.bashrc"
if ! grep -q "DISPLAY" "$bashrc"; then
    echo 'export DISPLAY=:0.0' >>"$bashrc"
    source "$bashrc"
    echo -e "${GREEN}Added DISPLAY to $bashrc${NC}"
fi

# Start PulseAudio if not running
if ! pulseaudio --check; then
    pulseaudio --start --log-target=syslog
    echo -e "${GREEN}Started PulseAudio daemon${NC}"
fi

# Validation Tests
echo -e "\n${GREEN}Running Validation Tests...${NC}"

# Audio Playback Test
if ! aplay -l &>/dev/null; then
    echo -e "${RED}Audio devices not found!${NC}"
    exit 1
else
    aplay /usr/share/sounds/alsa/Front_Center.wav &&
        echo -e "${GREEN}Audio playback success!${NC}"
fi

# Recording Test
arecord -d 5 test.wav &&
    aplay test.wav &&
    echo -e "${GREEN}Recording/playback success!${NC}"

# Graphics Test
if ! xdpyinfo &>/dev/null; then
    echo -e "${RED}X Server connection failed!${NC}"
    exit 1
else
    oclock -geometry 200x200+100+100 &
    sleep 3 &&
        pkill oclock &&
        echo -e "${GREEN}Graphics test success!${NC}"
fi

echo -e "\n${GREEN}All systems go! WSL audio/video stabilized.${NC}"

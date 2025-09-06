#!/bin/bash
set -e

# Resolve config file from current directory
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$CURRENT_DIR/config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Please verify all the installation files are present"
    exit 1
fi

# --- Read config values ---
JOB_NAME=$(awk -F' *= *' '/^job_name/ {print $2}' "$CONFIG_FILE")
INSTALL_DIR=$(awk -F' *= *' '/^install_dir/ {print $2}' "$CONFIG_FILE")
LAUNCHER_NAME=$(awk -F' *= *' '/^launcher_name/ {print $2}' "$CONFIG_FILE")

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_DIR/$JOB_NAME.service"
TIMER_PATH="$SYSTEMD_DIR/$JOB_NAME.timer"
LAUNCHER_PATH="/usr/local/bin/$LAUNCHER_NAME"

# 1️⃣ Stop and disable timer/service
if systemctl --user list-units --all | grep -q "${JOB_NAME}.timer"; then
    echo "Stopping and disabling timer..."
    systemctl --user stop "${JOB_NAME}.timer" || true
    systemctl --user disable "${JOB_NAME}.timer" || true
fi

if systemctl --user list-units --all | grep -q "${JOB_NAME}.service"; then
    echo "Stopping and disabling service..."
    systemctl --user stop "${JOB_NAME}.service" || true
    systemctl --user disable "${JOB_NAME}.service" || true
fi

# 2️⃣ Delete timer and service files
if [[ -f "$SERVICE_PATH" ]]; then
    echo "Removing service file..."
    rm -f "$SERVICE_PATH"
fi

if [[ -f "$TIMER_PATH" ]]; then
    echo "Removing timer file..."
    rm -f "$TIMER_PATH"
fi

# Reload systemd daemon
systemctl --user daemon-reload

# 3️⃣ Delete launcher script
if [[ -f "$LAUNCHER_PATH" ]]; then
    echo "Removing launcher script at $LAUNCHER_PATH..."
    sudo rm -f "$LAUNCHER_PATH"
fi

# 4️⃣ Delete installation directory
if [[ -d "$INSTALL_DIR" ]]; then
    echo "Removing installation directory $INSTALL_DIR..."
    sudo rm -rf "$INSTALL_DIR"
fi

echo "✅ Uninstallation complete."

#!/bin/bash

# Installer for HP DeskJet auto-print test page

# Resolve config file from current directory
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$CURRENT_DIR/config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Please run install.sh first."
    exit 1
fi

# --- Read config values ---
INSTALL_DIR=$(awk -F' *= *' '/^install_dir/ {print $2}' "$CONFIG_FILE")
LAUNCHER_NAME=$(awk -F' *= *' '/^launcher_name/ {print $2}' "$CONFIG_FILE")

LAUNCHER_PATH="/usr/local/bin/$LAUNCHER_NAME"

# Prompt for printer name
read -p "Enter the CUPS printer name (lpstat -p shows it): " PRINTER_NAME

# Write config.ini
echo "Writing $CONFIG_FILE with printer name."
if grep -q '^printer_name=' "$CONFIG_FILE"; then
    # Overwrite existing name entry
    sed -i "s/^printer_name=.*/printer_name=$PRINTER_NAME/" "$CONFIG_FILE"
else
    # Append new name entry
    echo "printer_name=$PRINTER_NAME" >> "$CONFIG_FILE"
fi

echo "Creating folder $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER":"$USER" "$INSTALL_DIR"

# Copy Python and Bash scripts, and Config file
echo "Copying scripts to $INSTALL_DIR..."
cp "$CURRENT_DIR/print-operation.py" "$INSTALL_DIR/"
cp "$CURRENT_DIR/print-page.sh" "$INSTALL_DIR/"
cp "$CURRENT_DIR/primauto.sh" "$INSTALL_DIR/"
cp "$CURRENT_DIR/config.ini" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/print-operation.py"
chmod +x "$INSTALL_DIR/print-page.sh"
chmod +x "$INSTALL_DIR/primauto.sh"

# Create launcher script in /usr/local/bin

if [[ -L "$LAUNCHER_PATH" || -f "$LAUNCHER_PATH" ]]; then
    sudo rm -f "$LAUNCHER_PATH"
fi

sudo tee "$LAUNCHER_PATH" >/dev/null <<EOF
#!/bin/bash
INSTALL_DIR="$INSTALL_DIR"
"\$INSTALL_DIR/primauto.sh" "\$@"
EOF

sudo chmod +x "$LAUNCHER_PATH"
echo "✅ Launcher created: $LAUNCHER_PATH"

echo "✅ Installed successfully."
echo "You can now run the setup with: $LAUNCHER_NAME configure"
echo "Run the uninstall.sh script for uninstalling"

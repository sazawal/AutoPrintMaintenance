#!/bin/bash
# Usage: primauto.sh [enable|disable|view|configure|clear|test|help]

# Resolve config file from current directory
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$CURRENT_DIR/config.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    echo "Please run install.sh first."
    exit 1
fi

# --- Read config values ---
JOB_NAME=$(awk -F' *= *' '/^job_name/ {print $2}' "$CONFIG_FILE")
INSTALL_DIR=$(awk -F' *= *' '/^install_dir/ {print $2}' "$CONFIG_FILE")
PRINTER_NAME=$(awk -F' *= *' '/^printer_name/ {print $2}' "$CONFIG_FILE")
SAMPLE_PDF=$(awk -F' *= *' '/^sample_pdf/ {print $2}' "$CONFIG_FILE")
LAUNCHER_NAME=$(awk -F' *= *' '/^launcher_name/ {print $2}' "$CONFIG_FILE")

SYSTEMD_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_DIR/$JOB_NAME.service"
TIMER_PATH="$SYSTEMD_DIR/$JOB_NAME.timer"
SCRIPT_PATH="$INSTALL_DIR/print-operation.py"
SAMPLE_PDF_PATH="$INSTALL_DIR/$SAMPLE_PDF"

# --- Pre-checks ---
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "❌ Script not found: $SCRIPT_PATH"
    echo "Please run install.sh again."
    exit 1
fi

if [[ -z "$PRINTER_NAME" ]]; then
    echo "❌ Printer name missing in $CONFIG_FILE"
    echo "Please run install.sh again."
    exit 1
fi

ensure_systemd_dir() {
    mkdir -p "$SYSTEMD_DIR"
}

job_exists() {
    [[ -f "$SERVICE_PATH" && -f "$TIMER_PATH" ]]
}

enable_job() {
    if ! job_exists; then
        echo "❌ No systemd print job found. Please run '$LAUNCHER_NAME configure' first."
        exit 1
    fi
    systemctl --user enable --now "$JOB_NAME.timer"
    echo "✅ Systemd auto-print job enabled."
}

disable_job() {
    if ! job_exists; then
        echo "❌ No systemd print job found. Please run '$LAUNCHER_NAME configure' first."
        exit 1
    fi
    systemctl --user disable --now "$JOB_NAME.timer"
    echo "✅ Systemd auto-print job disabled."
}

view_job() {
    if ! job_exists; then
        echo "❌ No systemd print job found. Please run '$LAUNCHER_NAME configure' first."
        exit 1
    fi
    echo "=== primauto systemd job info ==="
    echo "Printer name: $PRINTER_NAME"
    echo "Job name:  $JOB_NAME"

    # Show relevant timer information
    TIMER_ACTIVE=$(systemctl --user is-active "$JOB_NAME.timer")
    TIMER_ENABLED=$(systemctl --user is-enabled "$JOB_NAME.timer")

    # Determine friendly status
    if [[ "$TIMER_ACTIVE" == "active" && "$TIMER_ENABLED" == "enabled" ]]; then
        STATUS_MSG="Enabled"
    elif [[ "$TIMER_ACTIVE" != "active" && "$TIMER_ENABLED" != "enabled" ]]; then
        STATUS_MSG="Disabled"
    elif [[ "$TIMER_ACTIVE" == "active" && "$TIMER_ENABLED" != "enabled" ]]; then
        STATUS_MSG="Enabled until next system boot (run primauto enable to always enable when the system boots)"
    elif [[ "$TIMER_ACTIVE" != "active" && "$TIMER_ENABLED" == "enabled" ]]; then
        STATUS_MSG="Will be enabled after the next system boot (run primauto enable to enable right now)"
    fi

    echo "Job status: $STATUS_MSG"

    # Show next scheduled run if available
    NEXT_RUN=$(systemctl --user list-timers --all --no-legend | grep "$JOB_NAME.timer" | awk '{print $1, $2, $3, $4}')
    if [[ -n "$NEXT_RUN" ]]; then
        echo "Next run: $NEXT_RUN"
    else
        echo "Next run: Not scheduled"
    fi

    echo
    if [[ ! -f "$SAMPLE_PDF_PATH" ]]; then
        echo "⚠️ No sample PDF found. Generating a new one..."
        /usr/bin/python3 "$SCRIPT_PATH" --no-print
    fi

    if [[ -f "$SAMPLE_PDF_PATH" ]]; then
        echo "Opening sample test page: $SAMPLE_PDF_PATH"
        xdg-open "$SAMPLE_PDF_PATH" >/dev/null 2>&1 &
    else
        echo "❌ Failed to generate sample PDF."
    fi
}

configure_job() {
    ensure_systemd_dir

    if job_exists; then
        echo "⚠️ Warning: A systemd print job already exists."
        read -p "Do you want to overwrite it? (y/N): " CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "Aborting configure."
            exit 0
        fi
    fi

    echo "Printer name: ${PRINTER_NAME}"
    read -p "Do you want to overwrite it? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
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
    fi

    echo "Select frequency for the printer test page:"
    echo "1) Weekly"
    echo "2) Bi-weekly"
    echo "3) Monthly"
    echo "4) Custom"
    read -p "Choose an option [1-4]: " FREQUENCY

    case "$FREQUENCY" in
        1)  # Weekly
            read -p "Enter day of week (default: Sun): " DAY
            DAY=${DAY:-Sun}
            read -p "Enter time (HH:MM, default: 10:00): " TIME
            TIME=${TIME:-10:00}
            SCHEDULE="$DAY *-*-* ${TIME}:00"
            ;;
        2)  # Bi-weekly
            read -p "Enter dates of month, comma-separated (default: 1,15): " DATES
            DATES=${DATES:-1,15}
            read -p "Enter time (HH:MM, default: 10:00): " TIME
            TIME=${TIME:-10:00}
            SCHEDULE="*-*-$DATES ${TIME}:00"
            ;;
        3)  # Monthly
            read -p "Enter date of month (default: 1): " DATE
            DATE=${DATE:-1}
            read -p "Enter time (HH:MM, default: 10:00): " TIME
            TIME=${TIME:-10:00}
            SCHEDULE="*-*-$DATE ${TIME}:00"
            ;;
        4)  # Custom
            read -p "Enter OnCalendar string (see 'man systemd.time'): " SCHEDULE
            ;;
        *)
            echo "Invalid choice"; exit 1
            ;;
        esac

    if systemd-analyze calendar "$SCHEDULE" >/dev/null 2>&1; then
        echo "✅ Valid OnCalendar string"
    else
        echo "❌ Invalid OnCalendar string: $SCHEDULE"
        exit 1
    fi

    # Create service file
    cat > "$SERVICE_PATH" <<EOL
[Unit]
Description=Auto print HP DeskJet test page

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 $SCRIPT_PATH
StandardOutput=null
StandardError=journal
EOL

    # Create timer file
    cat > "$TIMER_PATH" <<EOL
[Unit]
Description=Timer to auto print test page

[Timer]
OnCalendar=$SCHEDULE
Persistent=true

[Install]
WantedBy=timers.target
EOL

    systemctl --user daemon-reload
    systemctl --user enable --now "$JOB_NAME.timer"

    echo "✅ Systemd auto-print job configured successfully."
    echo "Schedule: $SCHEDULE"
    echo "Test the job by running '$LAUNCHER_NAME test'"
}

clear_job() {
    if ! job_exists; then
        echo "❌ No systemd print job found."
        exit 1
    fi
    systemctl --user disable --now "$JOB_NAME.timer"
    rm -f "$SERVICE_PATH" "$TIMER_PATH"
    systemctl --user daemon-reload
    echo "✅ Systemd auto-print job cleared successfully."
}

test_job() {
    if ! job_exists; then
        echo "❌ No systemd print job found. Please run '$LAUNCHER_NAME configure' first."
        exit 1
    fi

    # Extract OnCalendar string
    echo "Checking the validity of scheduled time in $JOB_NAME.timer"
    ONCAL=$(grep '^OnCalendar=' "$TIMER_PATH" | cut -d= -f2-)
    if [[ -n "$ONCAL" ]]; then
        # Validate with systemd-analyze
        if systemd-analyze calendar "$ONCAL" >/dev/null 2>&1; then
            echo "✅ OnCalendar expression is valid in $JOB_NAME.timer"
        else
            echo "❌ OnCalendar expression is invalid in $JOB_NAME.timer"
        fi
    else
        echo "❌ No OnCalendar field found in $JOB_NAME"
    fi

    echo "🖨️ Running the systemd primauto service on the printer $PRINTER_NAME"
    systemctl --user start "${JOB_NAME}.service"
    if [[ $? -eq 0 ]]; then
        echo "✅ Test print triggered via systemd service."
    else
        echo "❌ Failed to trigger test print."
        echo "Executing the print script on $PRINTER_NAME"
        if ! OUTPUT=$(/usr/bin/python3 "$SCRIPT_PATH" 2>&1); then
            echo "❌ Print script failed."
            echo "Error output:"
            echo "$OUTPUT"
        else
            echo "✅ Print script ran successfully."
        fi
    fi
    echo "In case of any error or printing failure, please re-configure with '$LAUNCHER_NAME configure" 
    echo "apart from the hardware or connection troubleshooting."


}

show_help() {
    cat <<EOF

Auto-Print-Maintenance to auto print a test page with all the different
colors to prevent the printer ink from drying out.

Usage: $LAUNCHER_NAME [command]

Commands:
  enable     Enable an existing systemd primauto print job
  disable    Disable an existing systemd primauto print job (without deleting it)
  view       View job info, status, schedule, printer name, and open sample PDF
  configure  Create or overwrite the systemd primauto print job
  clear      Disable and delete the systemd primauto print job (service and timer files)
  test       Immediately run the print script once
  help       Show this help message

systemd job name: $JOB_NAME
Installation dir: $INSTALL_DIR
Printer name: $PRINTER_NAME
Sample print page path: $SAMPLE_PDF_PATH

EOF
}

case "$1" in
    enable) enable_job ;;
    disable) disable_job ;;
    view) view_job ;;
    configure) configure_job ;;
    clear) clear_job ;;
    test) test_job ;;
    help|"") show_help ;;
    *) echo "❌ Unknown command: $1"; show_help; exit 1 ;;
esac

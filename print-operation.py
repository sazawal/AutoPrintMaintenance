#!/usr/bin/env python3
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from datetime import datetime
import subprocess
from pathlib import Path
import configparser
import sys

# Paths
current_dir = Path(__file__).resolve().parent
config_file = current_dir/"config.ini"
print_script = current_dir/"print-page.sh"

# Read printer name from config
config = configparser.ConfigParser()
config.read(config_file)

# Generate PDF with timestamp
def generate_pdf():
    sample_pdf_path = str(current_dir/config.get("settings", "sample_pdf"))
    c = canvas.Canvas(sample_pdf_path, pagesize=A4)
    width, height = A4

    # Title
    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(width/2, height - 50, "HP DeskJet Test Page")

    # Timestamp
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    c.setFont("Helvetica", 12)
    c.drawCentredString(width/2, height - 80, f"Printed on: {now}")

    # Color blocks
    block_width, block_height = 150, 100
    margin, spacing = 70, 40
    colors = [("Black", (0, 0, 0)),
            ("Cyan", (0, 1, 1)),
            ("Magenta", (1, 0, 1)),
            ("Yellow", (1, 1, 0))]

    y = height - 150
    for name, rgb in colors:
        c.setFillColorRGB(*rgb)
        c.rect(margin, y - block_height, block_width, block_height, fill=True, stroke=False)
        c.setFillColorRGB(0, 0, 0)
        c.drawString(margin + block_width + 20, y - block_height/2, name)
        y -= (block_height + spacing)

    c.showPage()
    c.save()

if __name__ == "__main__":
    no_print = len(sys.argv) > 1 and sys.argv[1] == "--no-print"

    generate_pdf()

    if not no_print:
        # Call the printing script
        subprocess.run([print_script])

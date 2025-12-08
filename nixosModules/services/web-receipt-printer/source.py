"""Simple website that allows printing stuff on the thermal printer."""

import os

from escpos.printer import Usb
from flask import Flask, render_template_string, request

app = Flask(__name__)


def _str_to_hex(arg: str) -> int:
    return int(arg, 16)


PRODUCT_ID = 0x0202

try:
    VENDOR_ID = _str_to_hex(os.environ.get("VENDOR_ID"))
except KeyError:
    VENDOR_ID = 0x04B8
try:
    PRODUCT_ID = _str_to_hex(os.environ.get("PRODUCT_ID"))
except KeyError:
    VENDOR_ID = 0x0202


def get_printer():
    """Connect to the printer."""
    try:
        p = Usb(VENDOR_ID, PRODUCT_ID, 0, profile="TM-T88III")
        return p
    except Exception as e:
        print(f"Printer Error: {e}")
        return None


@app.route("/", methods=["GET", "POST"])
def index():
    """Serve '/' index page."""
    message = ""
    if request.method == "POST":
        text_to_print = request.form.get("note")
        if text_to_print:
            p = get_printer()
            if p:
                # PRINTING LOGIC
                p.text("\n")  # Spacing
                p.set(align="center", bold=True, double_height=True, width=2)
                p.text("TINY NOTE\n")
                p.set(align="left")
                p.text("--------------------------------\n")
                p.text(f"{text_to_print}\n")
                p.text("--------------------------------\n")
                p.cut()  # Cut the paper
                p.close()
                message = "Printed successfully!"
            else:
                message = "Error: Could not find printer."

    # Simple HTML interface
    html = """
    <!doctype html>
    <html style="font-family: sans-serif; text-align: center; padding: 50px;">
      <h1>Receipt Printer</h1>
      <form method="post">
        <textarea name="note" rows="5" cols="30" placeholder="Type your note here..."></textarea>
        <br><br>
        <button type="submit" style="padding: 10px 20px; font-size: 1.2em;">PRINT</button>
      </form>
      <p style="color: green;">{{ message }}</p>
    </html>
    """
    return render_template_string(html, message=message)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("FLASK_RUN_PORT", 5000)))

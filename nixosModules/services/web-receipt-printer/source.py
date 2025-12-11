"""Simple website that allows printing stuff on the thermal printer."""

import os
import tempfile

from escpos.printer import Usb
from flask import Flask, jsonify, render_template_string, request
from PIL import Image

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


def _print_text(text_to_print):
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
        return "Printed successfully!"
    else:
        return "Error: Could not find printer."


def _print_qr(content):
    p = get_printer()
    if p:
        # PRINTING LOGIC
        p.text("\n")  # Spacing
        p.set(align="center", bold=True, double_height=True, width=2)
        p.text("QR CODE\n")
        p.set(align="center")
        try:
            p.qr(content, size=5)
        except Exception:
            # Fallback if qr is not supported/configured properly, or print text
            p.text(f"QR Error: Could not print QR for {content}\n")

        p.text(f"{content}\n")
        p.cut()  # Cut the paper
        p.close()
        return "Printed QR code successfully!"
    else:
        return "Error: Could not find printer."


def _print_image(image_path):
    p = get_printer()
    if p:
        # PRINTING LOGIC
        p.text("\n")  # Spacing
        p.set(align="center", bold=True, double_height=True, width=2)
        p.text("IMAGE\n")
        p.set(align="center")

        resized_image_path = image_path
        temp_file_created = False

        try:
            img = Image.open(image_path)
            width, height = img.size

            # Constraint: Image width cannot be more than 512 pixels
            if width > 512:
                new_width = 512
                new_height = int((new_width / width) * height)
                img = img.resize((new_width, new_height), Image.LANCZOS)

                # Save resized image to a new temporary file
                with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as temp_resized:
                    img.save(temp_resized.name)
                    resized_image_path = temp_resized.name
                temp_file_created = True

            p.image(resized_image_path)

        except Exception as e:
            p.text(f"Image Error: {e}\n")
        finally:
            if temp_file_created:
                try:
                    os.remove(resized_image_path)
                except Exception:
                    pass

        p.text("\n")
        p.cut()  # Cut the paper
        p.close()
        return "Printed image successfully!"
    else:
        return "Error: Could not find printer."


@app.route("/api/text", methods=["POST"])
def print_text():
    """Serve the print text API."""
    data = request.get_json(silent=True)
    if not data or "text" not in data:
        return jsonify({"error": "Missing 'text' field in JSON body"}), 400

    text_to_print = data["text"]
    message = _print_text(text_to_print)

    if message.startswith("Error"):
        return jsonify({"error": message}), 500

    return jsonify({"message": message}), 200


@app.route("/api/qr", methods=["POST"])
def print_qr_api():
    """Serve the print QR API."""
    data = request.get_json(silent=True)
    # Support 'content', 'url', or 'text'
    content = data.get("content") or data.get("url") or data.get("text")
    if not content:
        return jsonify({"error": "Missing 'content', 'url', or 'text' field in JSON body"}), 400

    message = _print_qr(content)

    if message.startswith("Error"):
        return jsonify({"error": message}), 500

    return jsonify({"message": message}), 200


@app.route("/api/image", methods=["POST"])
def print_image_api():
    """Serve the print image API."""
    if "image" not in request.files:
        return jsonify({"error": "No image part in the request"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    if file:
        # Save to temp file
        with tempfile.NamedTemporaryFile(delete=False) as temp:
            file.save(temp.name)
            temp_path = temp.name

        message = _print_image(temp_path)

        # Cleanup
        try:
            os.remove(temp_path)
        except Exception:
            pass

        if message.startswith("Error"):
            return jsonify({"error": message}), 500

        return jsonify({"message": message}), 200


@app.route("/image", methods=["GET", "POST"])
def image_index():
    """Serve '/image' page."""
    message = ""
    if request.method == "POST":
        if "image" in request.files:
            file = request.files["image"]
            if file.filename != "":
                with tempfile.NamedTemporaryFile(delete=False) as temp:
                    file.save(temp.name)
                    temp_path = temp.name

                message = _print_image(temp_path)

                try:
                    os.remove(temp_path)
                except Exception:
                    pass

    html = """
    <!doctype html>
    <html style="font-family: sans-serif; text-align: center; padding: 50px;">
      <h1>Image Printer</h1>
      <a href="/">Go to Text Printer</a> | <a href="/qr">Go to QR Printer</a>
      <br><br>
      <form method="post" enctype="multipart/form-data">
        <input type="file" name="image" accept="image/*" style="padding: 10px;">
        <br><br>
        <button type="submit" style="padding: 10px 20px; font-size: 1.2em;">PRINT IMAGE</button>
      </form>
      <p style="color: green;">{{ message }}</p>
    </html>
    """
    return render_template_string(html, message=message)


@app.route("/qr", methods=["GET", "POST"])
def qr_index():
    """Serve '/qr' page."""
    message = ""
    if request.method == "POST":
        content = request.form.get("content")
        if content:
            message = _print_qr(content)

    html = """
    <!doctype html>
    <html style="font-family: sans-serif; text-align: center; padding: 50px;">
      <h1>QR Code Printer</h1>
      <a href="/">Go to Text Printer</a> | <a href="/image">Go to Image Printer</a>
      <br><br>
      <form method="post">
        <input type="text" name="content" placeholder="URL or Text" style="width: 300px; padding: 10px;">
        <br><br>
        <button type="submit" style="padding: 10px 20px; font-size: 1.2em;">PRINT QR</button>
      </form>
      <p style="color: green;">{{ message }}</p>
    </html>
    """
    return render_template_string(html, message=message)


@app.route("/", methods=["GET", "POST"])
def index():
    """Serve '/' index page."""
    message = ""
    if request.method == "POST":
        text_to_print = request.form.get("note")
        if text_to_print:
            message = _print_text(text_to_print)

    # Simple HTML interface
    html = """
    <!doctype html>
    <html style="font-family: sans-serif; text-align: center; padding: 50px;">
      <h1>Receipt Printer</h1>
      <a href="/qr">Go to QR Printer</a> | <a href="/image">Go to Image Printer</a>
      <br><br>
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

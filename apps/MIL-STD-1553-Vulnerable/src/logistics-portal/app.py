from flask import Flask, request, render_template, send_from_directory
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health')
def health():
    return "UP", 200

@app.route('/upload', methods=['POST'])
def upload_file():
    file = request.files['logfile']
    # VULNERABILITY: No file extension validation
    # Realism: Crew chiefs assume only PDFs are uploaded
    path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(path)
    return f"File {file.filename} synced to Hangar Maintenance Laptop."

# Serve uploaded files
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
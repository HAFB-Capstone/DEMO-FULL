# Logistics Portal (Target Asset)

**Role:** NIPRNet Web Server
**OS:** Debian Bookworm (Slim)
**Software:** Python 3.11 / Flask

## Overview
This is the public face of the maintenance system. It allows authorized personnel to upload flight logs. The backend logic is intentionally flawed to allow Red Team trainees to upload arbitrary files.

## Technical Details
- **Port:** 80 (Host) -> 8080 (Container)
- **Application:** `app.py`
- **Template Engine:** Jinja2 (`templates/index.html`)
- **Static Assets:** `static/css/style.css`

## Vulnerability
**CWE-434: Unrestricted Upload of File with Dangerous Type**
The application checks neither the file extension nor the "Magic Bytes".

```python
# app.py snippet
@app.route('/upload', methods=['POST'])
def upload_file():
    file = request.files['logfile']
    path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(path) # <--- Writes ANY file to disk
```

# 🚩 Flags Directory

## What is this?
This directory contains the **File-System Flags** for this challenge.
A "Flag" is a text file containing a secret string (e.g., `FLAG{you_found_me}`). Finding this file is proof that the Red Team has compromised the server's file system.

## ⚙️ How it works
This folder is **mounted** directly into the Vulnerable Machine's container via `docker-compose.yml`.

1.  **You put a file here:** `flags/system.txt`
2.  **Docker maps it:** It appears inside the container at `/flags/system.txt` (or wherever you mapped it).
3.  **Red Team finds it:** If they get Remote Code Execution (RCE) or Local File Inclusion (LFI), they can read this file.

## 📝 How to set up a Flag
1.  Create a text file in this directory (e.g., `root_flag.txt`).
2.  Paste a unique string inside.
    * *Format:* `FLAG{descriptive_name_randomstring}`
    * *Example:* `FLAG{legacy_crm_root_access_8a92b}`
3.  Ensure your `docker-compose.yml` mounts this volume:
    ```yaml
    volumes:
      - ./flags:/flags:ro
    ```
    *(The `:ro` stands for Read-Only, preventing the Red Team from deleting the flag for other players.)*

## 💡 Strategy for "Effective" Flags
* **The User Flag:** Place a flag that is readable by a standard web user.
* **The Root Flag:** Place a flag that requires `root` privileges to read (you can enforce this by `chmod 400 flags/root_flag.txt` on the host machine).
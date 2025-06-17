# KNIME + PostgreSQL (+ PostGIS) Desktop Stack

Run a full KNIME Analytics Platform with PostgreSQL 16 & PostGIS 3 in a single Docker container, accessible through your browser via **noVNC** (port 6080) or any VNC client (port 5900).

---

## Prerequisites

* **Docker Engine 23 or newer** (Windows, macOS or Linux)  
* At least **2 GB RAM** free for the container  
* Outbound Internet access (for the first image build)  

> **Windows users:** all commands below are shown for **PowerShell**. The container also works the same under Linux/Mac – just remove the back-ticks (\`).

---

## 1 · Clone the repository

```powershell
git clone https://github.com/SunnyRaymond/knime-pg.git
cd KNIME-PG
````

---

## 2 · Build the image (one-liner)

```powershell
cd knime-pg; docker build -t knime-pg-gis .
```

---

## 3 · Start the container (one-liner)

```powershell
docker run -d --name knime -p 6080:6080 -p 5900:5900 -p 5432:5432 -v "${env:USERPROFILE}\knime-ws:/workspace" -v knime_pgdata:/var/lib/postgresql/data knime-pg-gis
```

* **6080** → Browser access (noVNC)
* **5900** → Native VNC client (optional)
* **5432** → PostgreSQL server

| PostgreSQL credentials | value      |
| ---------------------- | ---------- |
| User                   | `postgres` |
| Password               | `123456`   |
| Database               | `postgres` |

---

## 4 · Open KNIME in your browser

```text
http://localhost:6080/vnc.html
```

Login when prompted (the default VNC password is **knime**). A lightweight XFCE desktop will appear with **KNIME Analytics Platform 5.4** already running.

---

## 5 · Install the Geometry/Spatial nodes inside KNIME

Inside the KNIME window:

1. Click **Help ▸ Install Extensions…** (top-right hamburger menu).
2. Search for **“KNIME Spatial Processing Nodes”**.
3. Tick the feature and proceed with the wizard, then restart KNIME when asked.

You will now find *Write Geometries into Database* and other PostGIS-enabled nodes under **Analytics ▸ Spatial** in the node repository.

---



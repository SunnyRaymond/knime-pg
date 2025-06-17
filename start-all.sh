#!/usr/bin/env bash
set -euo pipefail

# ────────── config ──────────
DISPLAY_NUM=${DISPLAY:-:1}
RESOLUTION=${VNC_RESOLUTION:-1280x800x24}
[[ -n "${VNC_PASSWORD:-}" ]] && VNC_PW_OPT="-passwd $VNC_PASSWORD" || VNC_PW_OPT=""

# ────────── PostgreSQL / PostGIS ──────────
echo "[start] PostgreSQL …"
/usr/sbin/gosu postgres /usr/lib/postgresql/16/bin/pg_ctl \
        -D /var/lib/postgresql/data \
        -l /var/lib/postgresql/data/logfile start

# ensure credentials and PostGIS extension (idempotent)
gosu postgres psql -Atqc "ALTER USER postgres PASSWORD '123456';"
gosu postgres psql -d postgres -Atqc "CREATE EXTENSION IF NOT EXISTS postgis;"

PG_PID=$(pgrep -u postgres postgres)

# ────────── X / VNC stack ──────────
echo "[start] Xvfb $DISPLAY_NUM ($RESOLUTION)"; Xvfb "$DISPLAY_NUM" -screen 0 "$RESOLUTION" &  XVFB_PID=$!; sleep 2
echo "[start] fluxbox";  fluxbox  -display "$DISPLAY_NUM" &  FLUX_PID=$!

echo "[start] KNIME (auto-restart loop)"
(
  while true; do
    DISPLAY=$DISPLAY_NUM /opt/knime/knime --launcher.suppressErrors
    echo "[warn ] KNIME exited – restarting in 5 s …"; sleep 5
  done
) & KNIME_PID=$!

echo "[start] x11vnc → 5900";      x11vnc -display "$DISPLAY_NUM" -rfbport 5900 $VNC_PW_OPT -forever -shared -quiet &  VNC_PID=$!
echo "[start] websockify → 6080";  websockify --web /usr/share/novnc --heartbeat 30 6080 localhost:5900 &               WS_PID=$!

echo "────────────────────────────────────────────────────────────"
echo "  Browser      :  http://<host-ip>:6080/vnc.html"
echo "  Native VNC   :  <host-ip>:5900   (pw=${VNC_PASSWORD:-<none>})"
echo "  PostgreSQL   :  <host-ip>:5432   (user=postgres  pw=123456)"
echo "  PostGIS      :  enabled in DB 'postgres'"
echo "────────────────────────────────────────────────────────────"

# stop container if any service dies
wait -n "$PG_PID" "$XVFB_PID" "$FLUX_PID" "$KNIME_PID" "$VNC_PID" "$WS_PID"

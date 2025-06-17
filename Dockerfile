# ────────────────────────────────────────────────────────────
# KNIME 5 + PostgreSQL 16 + headless GUI (noVNC / VNC)
#   -- Ubuntu 24.04 (noble)
# ────────────────────────────────────────────────────────────
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    KNIME_VER=5.4.0 \
    PG_MAJOR=16

# 1 ▸ OS + runtime + PostgreSQL + helper ‘gosu’
RUN apt-get update && apt-get install -y --no-install-recommends \
        # basics
        ca-certificates wget curl tar git git-lfs locales tzdata lsof gosu \
        # OpenJDK for KNIME
        openjdk-17-jdk \
        # head-less X + lightweight WM + VNC + noVNC
        xvfb fluxbox x11vnc novnc websockify \
        # GTK / SWT libs for KNIME & Eclipse
        libgtk-3-0 libgdk-pixbuf2.0-0 libglib2.0-0 libatk1.0-0 \
        libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
        libxext6 libxi6 libxrender1 libxtst6 libxinerama1 libxss1 \
        libcanberra-gtk3-0 libwebkit2gtk-4.1-0 \
        libgl1                                          \
        # PostgreSQL server
        "postgresql-$PG_MAJOR" "postgresql-contrib-$PG_MAJOR" \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2 ▸ KNIME Analytics Platform
RUN wget -qO /tmp/knime.tgz \
        "https://download.knime.org/analytics-platform/linux/knime_${KNIME_VER}.linux.gtk.x86_64.tar.gz" \
    && mkdir -p /opt/knime \
    && tar -xzf /tmp/knime.tgz --strip-components=1 -C /opt/knime \
    && rm /tmp/knime.tgz

# 3 ▸ initialise an empty PG cluster (as postgres user)
USER postgres
RUN /usr/lib/postgresql/$PG_MAJOR/bin/initdb -D /var/lib/postgresql/data

# 4 ▸ back to root, copy entry-point
USER root
COPY start-all.sh /usr/local/bin/start-all.sh
RUN chmod +x /usr/local/bin/start-all.sh

EXPOSE 5900 6080 5432                    
VOLUME ["/workspace", "/var/lib/postgresql/data"]

ENTRYPOINT ["/usr/local/bin/start-all.sh"]

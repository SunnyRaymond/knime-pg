# ────────────────────────────────────────────────────────────────
# KNIME 5.4  +  PostgreSQL-16 (+PostGIS 3)  +  Geospatial nodes
# ────────────────────────────────────────────────────────────────
FROM ubuntu:24.04
ARG  PG_MAJOR=16
ARG  POSTGIS_MAJOR=3
ENV  DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------------
# 1) Core OS + GUI + PostgreSQL/PostGIS
# ----------------------------------------------------------------
RUN set -eux; \
    # --- prerequisites for the repo-setup itself ------------------------------
    apt-get update && \
    apt-get install -y --no-install-recommends \
        lsb-release curl gnupg ca-certificates && \
    #
    # --- add official PostgreSQL APT repo -------------------------------------
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg && \
    #
    # --- now install everything we really need --------------------------------
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # basics
        wget tar git git-lfs locales tzdata lsof gosu \
        # Java for KNIME
        openjdk-17-jdk \
        # head-less X + lightweight WM + VNC + noVNC
        xvfb fluxbox x11vnc novnc websockify \
        # GTK / SWT runtime bits
        libgtk-3-0 libgdk-pixbuf2.0-0 libglib2.0-0 libatk1.0-0 \
        libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
        libxext6 libxi6 libxrender1 libxtst6 libxinerama1 libxss1 \
        libcanberra-gtk3-0 libwebkit2gtk-4.1-0 libgl1 \
        # PostgreSQL + PostGIS
        postgresql-${PG_MAJOR} postgresql-contrib-${PG_MAJOR} \
        postgresql-${PG_MAJOR}-postgis-${POSTGIS_MAJOR} postgis && \
    #
    # --- cleanup --------------------------------------------------------------
    apt-get clean && rm -rf /var/lib/apt/lists/*


# ----------------------------------------------------------------
# 2) KNIME Analytics Platform
# ----------------------------------------------------------------
RUN wget -qO /tmp/knime.tgz \
        https://download.knime.org/analytics-platform/linux/knime_5.4.0.linux.gtk.x86_64.tar.gz \
 && mkdir -p /opt/knime \
 && tar --strip-components=1 -xzf /tmp/knime.tgz -C /opt/knime \
 && rm /tmp/knime.tgz

# ----------------------------------------------------------------
# 3) Add the Geospatial Analytics extension (community-trusted)
# ----------------------------------------------------------------
RUN /opt/knime/knime \
      -nosplash \
      -application org.eclipse.equinox.p2.director \
      -repository https://update.knime.com/analytics-platform/5.4,\
https://update.knime.com/community-contributions/trusted/5.4 \
      -installIU org.knime.features.geospatial.feature.group \
      -destination /opt/knime \
      -profile KNIME \
      -profileProperties org.eclipse.update.install.features=true \
      -roaming       || echo "[WARN] Geospatial extension install skipped"

# ----------------------------------------------------------------
# 4) Bootstrap
# ----------------------------------------------------------------
COPY start-all.sh /usr/local/bin/start-all.sh
RUN chmod +x /usr/local/bin/start-all.sh

EXPOSE 5900 6080 5432
CMD ["/usr/local/bin/start-all.sh"]

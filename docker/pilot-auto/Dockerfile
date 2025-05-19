# Image args should come at the beginning.
ARG BASE_IMAGE

# hadolint ignore=DL3006
FROM $BASE_IMAGE

ARG ROS_DISTRO
ARG DESCRIPTION

LABEL org.opencontainers.image.description=$DESCRIPTION

# build autoware
# hadolint ignore=SC3046
RUN source /opt/ros/"$ROS_DISTRO"/setup.bash && colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-w" --continue-on-error

# Install openbox, VNC, and simulator dependencies
# hadolint ignore=DL3008,DL3013,DL3015
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    mesa-utils \
    novnc \
    openbox \
    python3-numpy \
    python3-xdg \
    tigervnc-standalone-server \
    tigervnc-common \
    unzip \
    websockify \
    x11-apps \
    && pip install --no-cache-dir yamale xmlschema \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create SSL certificate for NoVNC
RUN openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout /etc/ssl/private/novnc.key \
  -out /etc/ssl/certs/novnc.crt \
  -days 365 \
  -subj "/O=Autoware-OpenADKit/CN=localhost"

# Need to expose VNC and NoVNC ports when running the container
EXPOSE 5900 6080

# Copy startup scripts
COPY docker/pilot-auto/xstartup /root/.vnc/xstartup
COPY docker/pilot-auto/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chmod +x /root/.vnc/xstartup
ENTRYPOINT ["/entrypoint.sh"]

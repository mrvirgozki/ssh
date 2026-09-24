# ==============================================================================
# VIRGOZKI SSH-WS
# Cloud Run + Nginx + SSH + BadVPN UDPGW
# ==============================================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# SYSTEM PACKAGES
# ------------------------------------------------------------------------------

RUN apt-get update && apt-get install -y \
    openssh-server \
    nginx \
    python3 \
    python3-minimal \
    cmake \
    build-essential \
    git \
    wget \
    curl \
    ca-certificates \
    pkg-config \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------
# BADVPN UDPGW
# ------------------------------------------------------------------------------

RUN git clone --depth 1 \
        https://github.com/ambrop72/badvpn.git \
        /tmp/badvpn \
    && mkdir -p /tmp/badvpn/build \
    && cd /tmp/badvpn/build \
    && cmake .. \
        -DBUILD_NOTHING_BY_DEFAULT=1 \
        -DBUILD_UDPGW=1 \
    && make -j"$(nproc)" \
    && make install \
    && cd / \
    && rm -rf /tmp/badvpn

# ------------------------------------------------------------------------------
# SSH DIRECTORIES
# ------------------------------------------------------------------------------

RUN mkdir -p \
    /run/sshd \
    /var/run/sshd \
    /var/log/ssh

# ------------------------------------------------------------------------------
# SSH USER
# ------------------------------------------------------------------------------

RUN useradd \
        --create-home \
        --shell /bin/bash \
        virgozki \
    && echo 'virgozki:virgozki' | chpasswd

# ------------------------------------------------------------------------------
# SSH CONFIGURATION
# ------------------------------------------------------------------------------

RUN printf '%s\n' \
    'PermitRootLogin no' \
    'PasswordAuthentication yes' \
    'PubkeyAuthentication yes' \
    'UseDNS no' \
    'TCPKeepAlive yes' \
    'ClientAliveInterval 30' \
    'ClientAliveCountMax 3' \
    'MaxSessions 50' \
    'MaxStartups 50:30:100' \
    'Compression no' \
    'X11Forwarding no' \
    'AllowTcpForwarding yes' \
    'Banner /etc/ssh/banner.txt' \
    >> /etc/ssh/sshd_config

# ------------------------------------------------------------------------------
# COPY APPLICATION FILES
# ------------------------------------------------------------------------------

COPY banner.txt /etc/ssh/banner.txt

COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /entrypoint.sh

# ------------------------------------------------------------------------------
# PERMISSIONS + CONFIG VALIDATION
# ------------------------------------------------------------------------------

RUN chmod +x /entrypoint.sh \
    && nginx -t \
    && /usr/sbin/sshd -t

# ------------------------------------------------------------------------------
# CLOUD RUN
# ------------------------------------------------------------------------------

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

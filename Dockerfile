FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    nginx \
    python3 \
    cmake \
    build-essential \
    git \
    wget \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Build BadVPN UDPGW
RUN git clone --depth 1 https://github.com/ambrop72/badvpn.git /tmp/badvpn \
    && cd /tmp/badvpn \
    && mkdir build \
    && cd build \
    && cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 \
    && make -j"$(nproc)" \
    && make install \
    && rm -rf /tmp/badvpn

RUN mkdir -p /var/run/sshd /run/sshd

# Non-root SSH account used by the service.
RUN useradd -m -s /bin/bash virgozki \
    && echo 'virgozki:virgozki' | chpasswd

# SSH settings
RUN printf '%s\n' \
    'PermitRootLogin no' \
    'PasswordAuthentication yes' \
    'UseDNS no' \
    'TCPKeepAlive yes' \
    'ClientAliveInterval 15' \
    'ClientAliveCountMax 3' \
    'MaxSessions 50' \
    'MaxStartups 50:30:100' \
    'Compression no' \
    'Banner /etc/ssh/banner.txt' \
    >> /etc/ssh/sshd_config

COPY banner.txt /etc/ssh/banner.txt
COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && nginx -t \
    && /usr/sbin/sshd -t

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

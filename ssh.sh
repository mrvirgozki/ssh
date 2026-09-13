#!/bin/bash
# ==============================================================================
# 
# WELCOME TO SSH-WS DEPLOYER SCRIPT v2.3
# 
# ==============================================================================
BOLD='\033[1m'; RESET='\033[0m'; NC='\033[0m'

# Cyberpunk Color Palette
CYAN='\033[1;36m'
GREEN='\033[1;32m'
MAGENTA='\033[1;35m'
PINK='\033[38;5;201m'
YELLOW='\033[1;33m'

echo ""
echo -e "  ${BOLD}${CYAN}WELCOME TO SSH-WS DEPLOYER SCRIPT v2.3${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "  ${MAGENTA}ERROR: No active GCP project detected. Please run 'gcloud init'.${RESET}"
    exit 1
fi
echo -e "  ${GREEN}PROJECT: ${CYAN}${PROJECT_ID}${RESET}"
echo ""

echo -e "  ${CYAN}[+] ENABLING REQUIRED GCP APIS...${RESET}"
gcloud services enable cloudbuild.googleapis.com artifactregistry.googleapis.com run.googleapis.com --project="$PROJECT_ID"

echo -e "  ${MAGENTA}==================================================${NC}"
echo -e "  ${GREEN}                 SERVICE NAME${NC}"
echo -e "  ${MAGENTA}==================================================${NC}"
read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [ssh-ws]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-ssh-ws}
echo ""

echo -e "  ${MAGENTA}==================================================${NC}"
echo -e "  ${GREEN}              SELECT REGION${NC}"
echo -e "  ${MAGENTA}==================================================${NC}"
echo -e "  ${CYAN}0. us-central1${RESET}"
echo -e "  ${CYAN}1. asia-east1${RESET}"
echo -e "  ${CYAN}2. asia-southeast1${RESET}"
echo -e "  ${CYAN}4. us-west1${RESET}"
echo -e "  ${CYAN}5. us-east1${RESET}"
echo ""
read -r -p "$(echo -e "  ${GREEN}REGION [0, 1, 2, 4, 5]: ${RESET}")" REGION_CHOICE
case "$REGION_CHOICE" in
    0) REGION="us-central1" ;;
    1) REGION="asia-east1" ;;
    2) REGION="asia-southeast1" ;;
    4) REGION="us-west1" ;;
    5) REGION="us-east1" ;;
    *) REGION="us-central1" ;;
esac
echo -e "  ${GREEN}SELECTED REGION: ${CYAN}${REGION}${RESET}"
echo ""

echo -e "  ${MAGENTA}==================================================${NC}"
echo -e "  ${GREEN}            BUILD MODE SELECTION${NC}"
echo -e "  ${MAGENTA}==================================================${NC}"
echo -e "  ${CYAN}1) 🚀 HIGH PERFORMANCE${RESET}"
echo -e "  ${GREEN}   Billing Type        : Instance-Based${RESET}"
echo -e "  ${GREEN}   vCPU                : 4CPU${RESET}"
echo -e "  ${GREEN}   Memory              : 4Gi${RESET}"
echo -e "  ${GREEN}   Concurrency         : 1000${RESET}"
echo -e "  ${GREEN}   Timeout             : 3600${RESET}"
echo -e "  ${GREEN}   Auto Scaling:${RESET}"
echo -e "  ${GREEN}     Min Instances       : 1${RESET}"
echo -e "  ${GREEN}     Max Instances       : 4${RESET}"
echo -e "  ${GREEN}   Execution Env       : Gen2${RESET}"
echo -e "  ${GREEN}   CPU Boost           : Enabled${RESET}"
echo -e "  ${CYAN}${RESET}"
echo -e "  ${CYAN}2) 🌱 ESSENTIAL${RESET}"
echo -e "  ${GREEN}   Billing Type        : Instance-Based${RESET}"
echo -e "  ${GREEN}   vCPU                : 1CPU${RESET}"
echo -e "  ${GREEN}   Memory              : 512Mi${RESET}"
echo -e "  ${GREEN}   Concurrency         : 1000${RESET}"
echo -e "  ${GREEN}   Timeout             : 3600${RESET}"
echo -e "  ${GREEN}   Auto Scaling:${RESET}"
echo -e "  ${GREEN}     Min Instances       : 1${RESET}"
echo -e "  ${GREEN}     Max Instances       : 2${RESET}"
echo -e "  ${GREEN}   Execution Env       : Gen2${RESET}"
echo -e "  ${GREEN}   CPU Boost           : Enabled${RESET}"
echo -e "  ${CYAN}${RESET}"
echo -e "  ${CYAN}3) ⚖️ STANDARD${RESET}"
echo -e "  ${GREEN}   Billing Type        : Instance-Based${RESET}"
echo -e "  ${GREEN}   vCPU                : 1CPU${RESET}"
echo -e "  ${GREEN}   Memory              : 1Gi${RESET}"
echo -e "  ${GREEN}   Concurrency         : 1000${RESET}"
echo -e "  ${GREEN}   Timeout             : 3600${RESET}"
echo -e "  ${GREEN}   Auto Scaling:${RESET}"
echo -e "  ${GREEN}     Min Instances       : 1${RESET}"
echo -e "  ${GREEN}     Max Instances       : 2${RESET}"
echo -e "  ${GREEN}   Execution Env       : Gen2${RESET}"
echo -e "  ${GREEN}   CPU Boost           : Enabled${RESET}"
echo -e "  ${CYAN}${RESET}"
echo -e "  ${CYAN}4) ⚡ BALANCED${RESET}"
echo -e "  ${GREEN}   Billing Type        : Instance-Based${RESET}"
echo -e "  ${GREEN}   vCPU                : 2CPU${RESET}"
echo -e "  ${GREEN}   Memory              : 2Gi${RESET}"
echo -e "  ${GREEN}   Concurrency         : 1000${RESET}"
echo -e "  ${GREEN}   Timeout             : 3600${RESET}"
echo -e "  ${GREEN}   Auto Scaling:${RESET}"
echo -e "  ${GREEN}     Min Instances       : 1${RESET}"
echo -e "  ${GREEN}     Max Instances       : 2${RESET}"
echo -e "  ${GREEN}   Execution Env       : Gen2${RESET}"
echo -e "  ${GREEN}   CPU Boost           : Enabled${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE [1-4]: ${RESET}")" MODE_CHOICE
case "$MODE_CHOICE" in
    1) CPU="4"; RAM="4Gi"; MODE="HIGH PERFORMANCE"; MAX_INSTANCES="4"; CONCURRENCY="1000" ;;
    2) CPU="1"; RAM="512Mi"; MODE="ESSENTIAL"; MAX_INSTANCES="2"; CONCURRENCY="1000" ;;
    3) CPU="1"; RAM="1Gi"; MODE="STANDARD"; MAX_INSTANCES="2"; CONCURRENCY="1000" ;;
    4) CPU="2"; RAM="2Gi"; MODE="BALANCED"; MAX_INSTANCES="2"; CONCURRENCY="1000" ;;
    *) CPU="2"; RAM="2Gi"; MODE="BALANCED"; MAX_INSTANCES="2"; CONCURRENCY="1000" ;;
esac
echo -e "  ${GREEN}SELECTED MODE: ${CYAN}${MODE} (${CPU} vCPU / ${RAM})${RESET}"
echo ""

echo -e "  ${PINK}[+] GENERATING DEPLOYMENT FILES...${RESET}"

# --- 1. Generate banner.txt with Raw ASCII Escape Characters ---
printf "\x1b[1;97m⡋⣡⣴⣶⣶⡀⠄⠄⠙⢿⣿⣿⣿⣿⣿⣴⣿⣿⣿⢃⣤⣄⣀⣥⣿\x1b[0m\r\n" > banner.txt
printf "\x1b[1;97m⢸⣇⠻⣿⣿⣿⣧⣀⢀⣠⡌⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⢸⣿⣷⣤⣤⣤⣬⣙⣛⢿⣿⣿⣿⣿⣿⣿⡿⣿⣿⡍⠄⠄⢀⣤⣄⠉\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⣖⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⢇⣿⣿⡷⠶⠶⢿⣿⣿⠇⢀\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣿⣿⣿⡇⣿⣿⣿⣿⣿⣿⣷⣶⣥⣴\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⣦⣌⣛⣻⣿⣿⣧⠙⠛⠛⡭⠅⠒⠦⠭⣭⡻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠄\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⣿⣿⣿⣿⣿⣿⣿⡆⠄⠄⠄⠄⠄⠄⠄⠄⠹⠈⢋⣽⣿⣿⣿⣿⣵⣾\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⣿⣿⣿⣿⣿⣿⣿⣿⠄⣴⣿⣶⣄⠄⣴⣶⠄⢀⣾⣿⣿⣿⣿⣿⣿⠃⠄⠄\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⠈⠻⣿⣿⣿⣿⣿⣿⡄⢻⣿⣿⣿⠄⣿⣿⡀⣾⣿⣿⣿⣿⣛⠛⠁\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⠄⠄⠈⠛⢿⣿⣿⣿⠁⠞⢿⣿⣿⡄⢿⣿⡇⣸⣿⣿⠿⠛⠁⠄\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m⠄⠄⠄⠄⠄⠉⠻⣿⣿⣾⣦⡙⠻⣷⣾⣿⠃⠿⠋⠁⠄\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;36m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;35m▓                                                               ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;97m▓       ⚡ SSH-WS + UDPGW GAMING TUNNEL SERVICE v2.3 ⚡        ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;35m▓                                                               ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;36m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;92m▓  ✅ LOW LATENCY      ✅ OPTIMIZED UDP       ✅ AUTO RECONNECT ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;92m▓  ✅ NO LAG BUFFER    ✅ STABLE CONNECTION   ✅ HIGH SPEED     ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;36m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;31m▓  ❌ NO TORRENT/P2P   ❌ NO DDOS/ATTACKS    ❌ NO ABUSE        ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;31m▓  ⚠️  ALL ACTIVITIES ARE MONITORED - BAN FOR MISUSE            ▓\x1b[0m\r\n" >> banner.txt
printf "\x1b[1;36m▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\x1b[0m\r\n" >> banner.txt

# --- 2. Generate entrypoint.sh ---
cat << 'EOF' > entrypoint.sh
#!/bin/bash
set -e

ulimit -n 65535 || true

echo "[+] Generating SSH Host Keys..."
ssh-keygen -A
mkdir -p /run/sshd

echo "[+] Starting SSH Daemon..."
/usr/sbin/sshd

echo "[+] Starting BadVPN UDPGW (tuned for high-throughput gaming UDP)..."

badvpn-udpgw \
  --listen-addr 127.0.0.1:7300 \
  --max-clients 1000 \
  --max-connections-for-client 40 \
  --loglevel warning &
UDPGW_PID=$!

echo "[+] Creating Optimized WS-to-TCP Bridge..."
cat << 'PYEOF' > /tmp/bridge.py
import socket, threading

BUF_SIZE = 65536  # bigger buffer = fewer syscalls, higher throughput

def tune_socket(sock):
    sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)  # kill Nagle-induced latency
    try:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1 << 20)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1 << 20)
    except OSError:
        pass

def bridge(src, dst):
    try:
        while True:
            data = src.recv(BUF_SIZE)
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        src.close()
        dst.close()

def handle(client):
    try:
        tune_socket(client)
        client.recv(4096)
        client.sendall(b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n")
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        tune_socket(ssh)
        ssh.connect(('127.0.0.1', 22))
        threading.Thread(target=bridge, args=(client, ssh), daemon=True).start()
        threading.Thread(target=bridge, args=(ssh, client), daemon=True).start()
    except Exception:
        client.close()

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('127.0.0.1', 2222))
server.listen(200)
while True:
    client, _ = server.accept()
    threading.Thread(target=handle, args=(client,), daemon=True).start()
PYEOF

python3 /tmp/bridge.py &
BRIDGE_PID=$!

echo "[+] Starting Watchdog (auto-restarts sshd/udpgw/bridge if any crash)..."
(
  while true; do
    sleep 10
    if ! kill -0 "$UDPGW_PID" 2>/dev/null; then
      echo "[watchdog] udpgw died, restarting..."
      badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 \
        --max-connections-for-client 40 --loglevel warning &
      UDPGW_PID=$!
    fi
    if ! kill -0 "$BRIDGE_PID" 2>/dev/null; then
      echo "[watchdog] bridge died, restarting..."
      python3 /tmp/bridge.py &
      BRIDGE_PID=$!
    fi
    if ! pgrep -x sshd > /dev/null; then
      echo "[watchdog] sshd died, restarting..."
      /usr/sbin/sshd
    fi
  done
) &

echo "[+] Starting Optimized Nginx..."
exec nginx -g "daemon off;"
EOF
chmod +x entrypoint.sh

# --- 3. Generate nginx.conf ---
cat << 'EOF' > nginx.conf
worker_processes auto;
events {
    worker_connections 8192;
    multi_accept on;
    use epoll;
}
http {
    client_header_buffer_size 8k;
    large_client_header_buffers 4 32k;
    tcp_nodelay on;
    tcp_nopush off;
    sendfile off;
    keepalive_timeout 3600;

    map $http_sec_websocket_key $ws_key {
        default $http_sec_websocket_key;
        ""      "S2w0eVY4bTBRN3pQNjFqWA==";
    }

    map $http_sec_websocket_version $ws_version {
        default $http_sec_websocket_version;
        ""      "13";
    }

    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 8080;
        server_name _;

        location /ssh {
            proxy_pass http://127.0.0.1:2222;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header Sec-WebSocket-Key $ws_key;
            proxy_set_header Sec-WebSocket-Version $ws_version;
            proxy_set_header Host $host;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_socket_keepalive on;
        }

        location / {
            return 302 https://wtfismyip.com/;
        }
    }
}
EOF

# --- 4. Generate Dockerfile ---
cat << 'EOF' > Dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server nginx python3 cmake build-essential git wget curl ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ambrop72/badvpn.git /tmp/badvpn \
    && cd /tmp/badvpn && mkdir build && cd build \
    && cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 \
    && make install && rm -rf /tmp/badvpn

RUN mkdir -p /var/run/sshd
RUN useradd -m -s /bin/bash virgozki && echo 'virgozki:virgozki' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Configure SSH Banner settings safely via standard SSH config
RUN sed -i 's/#DebianBanner yes/DebianBanner no/' /etc/ssh/sshd_config || true
RUN echo "DebianBanner no" >> /etc/ssh/sshd_config
RUN echo "VersionAddendum _Tectia-SSH_9.5_NVIDIA-RTX-PRO-6000-Blackwell" >> /etc/ssh/sshd_config

RUN { \
    echo "UseDNS no"; \
    echo "TCPKeepAlive yes"; \
    echo "ClientAliveInterval 15"; \
    echo "ClientAliveCountMax 3"; \
    echo "MaxSessions 50"; \
    echo "MaxStartups 50:30:100"; \
    echo "Compression no"; \
    } >> /etc/ssh/sshd_config

# Copy raw binary ANSI banner file into SSH directory
COPY banner.txt /etc/ssh/banner.txt
RUN echo "Banner /etc/ssh/banner.txt" >> /etc/ssh/sshd_config

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
EOF

echo -e "  ${CYAN}BUILDING IMAGE  BUILD...${RESET}"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" --project="$PROJECT_ID"
if [ $? -ne 0 ]; then
    echo -e "  ${MAGENTA}BUILD FAILED.${RESET}"
    exit 1
fi

deploy_attempt() {
    local cpu="$1" mem="$2" maxi="$3" conc="$4" extra_flags="$5"
    gcloud run deploy "$SERVICE_NAME" \
        --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
        --platform managed --region "$REGION" \
        --port 8080 --allow-unauthenticated --project="$PROJECT_ID" \
        --cpu "$cpu" --memory "$mem" --max-instances "$maxi" \
        --concurrency "$conc" --timeout 3600 $extra_flags
}

echo -e "  ${CYAN}DEPLOYING SSH SERVER HOST TO ${REGION}...${RESET}"
if deploy_attempt "$CPU" "$RAM" "$MAX_INSTANCES" "$CONCURRENCY" "--no-cpu-throttling --cpu-boost --session-affinity --execution-environment gen2 --min-instances 1"; then
    FINAL_CPU="$CPU"; FINAL_RAM="$RAM"
elif deploy_attempt 1 512Mi 2 150 "--no-cpu-throttling --session-affinity --min-instances 1"; then
    FINAL_CPU="1"; FINAL_RAM="512Mi"
elif deploy_attempt 1 512Mi 2 100 "--min-instances 0"; then
    FINAL_CPU="1"; FINAL_RAM="512Mi"
else
    echo -e "  ${MAGENTA}ALL DEPLOY ATTEMPTS FAILED.${RESET}"
    echo -e "  ${CYAN}Check your actual quota at:${RESET}"
    echo -e "  https://console.cloud.google.com/iam-admin/quotas?project=${PROJECT_ID}"
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

echo ""
echo -e "  ${GREEN} DEPLOYED SSH SUCCESSFULLY${RESET}"
echo ""
echo -e "  ${CYAN}SERVICE      ${GREEN}${SERVICE_NAME}${RESET}"
echo -e "  ${CYAN}RAW HOST     ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}SERVER HOST          ${GREEN}${SERVICE_URL}${RESET}"
echo -e "  ${CYAN}BUILD USED   ${GREEN}${FINAL_CPU} vCPU : ${FINAL_RAM}${RESET}"
echo -e "  ${CYAN}User/Pass:   ${GREEN}virgozki : virgozki${RESET}"
echo ""

cleanup() {
    echo -e "\n  ${PINK}CLEANING UP LOCAL BUILD LOGS AND GENERATED FILES...${RESET}"
    rm -f banner.txt entrypoint.sh nginx.conf Dockerfile
    echo -e "  ${CYAN}DEPLOYER SESSION CLOSED.${RESET}\n"
}

cleanup

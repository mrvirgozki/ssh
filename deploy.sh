#!/bin/bash
set -euo pipefail

# ==============================================================================
# VIRGOZKI SSH-WS DEPLOYER v3.0
# - Separate build files
# - Fixes "failed to read dockerfile: open Dockerfile: no such file or directory"
# - Uses Artifact Registry
# - CPU/RAM selection ordered LOW -> HIGH
# ==============================================================================

BOLD='\033[1m'
RESET='\033[0m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
MAGENTA='\033[1;35m'
PINK='\033[38;5;201m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;97m'

clear 2>/dev/null || true
echo -e "${CYAN}"
cat <<'BANNER'
+==============================================================+
|                    VIRGOZKI SSH-WS                           |
|                 DEPLOYER v3.0                                |
|                                                              |
|        SSH over WebSocket  |  Cloud Run  |  Nginx            |
+==============================================================+
BANNER
echo -e "${RESET}"

PROJECT_ID="$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')"
if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
    echo -e "${RED}ERROR:${RESET} No active GCP project."
    echo "Run: gcloud init"
    exit 1
fi

echo -e "${GREEN}PROJECT:${RESET} ${CYAN}${PROJECT_ID}${RESET}"
echo

echo -e "${CYAN}[1/7] Enabling required Google Cloud APIs...${RESET}"
gcloud services enable \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    --project="${PROJECT_ID}"

echo
echo -e "${MAGENTA}==============================================================${RESET}"
echo -e "${GREEN}                     SERVICE NAME${RESET}"
echo -e "${MAGENTA}==============================================================${RESET}"
read -r -p "Service name [virgozki]: " INPUT_NAME
SERVICE_NAME="${INPUT_NAME:-virgozki}"
SERVICE_NAME="$(echo "${SERVICE_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/^-*//; s/-*$//' | cut -c1-49)"
[[ -n "${SERVICE_NAME}" ]] || SERVICE_NAME="virgozki"

echo
echo -e "${MAGENTA}==============================================================${RESET}"
echo -e "${GREEN}                        REGION${RESET}"
echo -e "${MAGENTA}==============================================================${RESET}"
echo "  1) us-central1"
echo "  2) asia-east1"
echo "  3) asia-southeast1"
echo "  4) us-west1"
echo "  5) us-east1"
echo
read -r -p "Region [1-5] (default 1): " REGION_CHOICE

case "${REGION_CHOICE:-1}" in
    1) REGION="us-central1" ;;
    2) REGION="asia-east1" ;;
    3) REGION="asia-southeast1" ;;
    4) REGION="us-west1" ;;
    5) REGION="us-east1" ;;
    *) REGION="us-central1" ;;
esac

echo -e "${GREEN}Selected:${RESET} ${CYAN}${REGION}${RESET}"
echo

echo -e "${MAGENTA}==============================================================${RESET}"
echo -e "${GREEN}                  CPU / RAM PROFILE${RESET}"
echo -e "${MAGENTA}==============================================================${RESET}"
echo -e "${CYAN}1) LOW${RESET}"
echo "   vCPU: 1       RAM: 512Mi    Max: 2    Concurrency: 100"
echo
echo -e "${CYAN}2) STANDARD${RESET}"
echo "   vCPU: 1       RAM: 1Gi      Max: 2    Concurrency: 200"
echo
echo -e "${CYAN}3) BALANCED${RESET}"
echo "   vCPU: 2       RAM: 2Gi      Max: 3    Concurrency: 500"
echo
echo -e "${CYAN}4) HIGH${RESET}"
echo "   vCPU: 4       RAM: 4Gi      Max: 4    Concurrency: 1000"
echo

read -r -p "Choose profile [1-4] (default 1): " MODE_CHOICE

case "${MODE_CHOICE:-1}" in
    1)
        CPU="1"; RAM="512Mi"; MODE="LOW"
        MAX_INSTANCES="2"; MIN_INSTANCES="0"; CONCURRENCY="100"
        ;;
    2)
        CPU="1"; RAM="1Gi"; MODE="STANDARD"
        MAX_INSTANCES="2"; MIN_INSTANCES="1"; CONCURRENCY="200"
        ;;
    3)
        CPU="2"; RAM="2Gi"; MODE="BALANCED"
        MAX_INSTANCES="3"; MIN_INSTANCES="1"; CONCURRENCY="500"
        ;;
    4)
        CPU="4"; RAM="4Gi"; MODE="HIGH"
        MAX_INSTANCES="4"; MIN_INSTANCES="1"; CONCURRENCY="1000"
        ;;
    *)
        CPU="1"; RAM="512Mi"; MODE="LOW"
        MAX_INSTANCES="2"; MIN_INSTANCES="0"; CONCURRENCY="100"
        ;;
esac

echo
echo -e "${GREEN}Selected profile:${RESET} ${CYAN}${MODE} — ${CPU} vCPU / ${RAM}${RESET}"
echo

# --------------------------------------------------------------------------
# IMPORTANT BUILD FIX
# Put every Docker build file in a dedicated directory and explicitly
# disable .gcloudignore filtering. This prevents Dockerfile from being
# accidentally omitted from the uploaded build context.
# --------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/virgozki-build-${SERVICE_NAME}"
mkdir -p "${BUILD_DIR}"

echo -e "${PINK}[2/7] Preparing separated build files...${RESET}"

cp "${SCRIPT_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${SCRIPT_DIR}/entrypoint.sh" "${BUILD_DIR}/entrypoint.sh"
cp "${SCRIPT_DIR}/nginx.conf" "${BUILD_DIR}/nginx.conf"
cp "${SCRIPT_DIR}/banner.txt" "${BUILD_DIR}/banner.txt"

chmod +x "${BUILD_DIR}/entrypoint.sh"

for FILE in Dockerfile entrypoint.sh nginx.conf banner.txt; do
    if [[ ! -s "${BUILD_DIR}/${FILE}" ]]; then
        echo -e "${RED}ERROR:${RESET} Missing ${BUILD_DIR}/${FILE}"
        exit 1
    fi
done

echo "Build directory:"
echo "  ${BUILD_DIR}"
echo "  - Dockerfile"
echo "  - entrypoint.sh"
echo "  - nginx.conf"
echo "  - banner.txt"
echo

# --------------------------------------------------------------------------
# Artifact Registry
# --------------------------------------------------------------------------

REPOSITORY="virgozki-docker"

echo -e "${PINK}[3/7] Preparing Artifact Registry...${RESET}"

if ! gcloud artifacts repositories describe "${REPOSITORY}" \
    --location="${REGION}" \
    --project="${PROJECT_ID}" >/dev/null 2>&1; then

    gcloud artifacts repositories create "${REPOSITORY}" \
        --repository-format=docker \
        --location="${REGION}" \
        --description="Virgozki SSH-WS Docker images" \
        --project="${PROJECT_ID}"
fi

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${SERVICE_NAME}:latest"

echo
echo -e "${PINK}[4/7] Building image...${RESET}"
echo -e "${CYAN}IMAGE:${RESET} ${IMAGE}"

# --ignore-file=/dev/null guarantees that an existing .gcloudignore
# cannot remove Dockerfile from the build upload.
gcloud builds submit "${BUILD_DIR}" \
    --ignore-file=/dev/null \
    --tag "${IMAGE}" \
    --project="${PROJECT_ID}"

echo
echo -e "${GREEN}BUILD SUCCESS.${RESET}"
echo

deploy_service() {
    gcloud run deploy "${SERVICE_NAME}" \
        --image "${IMAGE}" \
        --platform managed \
        --region "${REGION}" \
        --port 8080 \
        --allow-unauthenticated \
        --project="${PROJECT_ID}" \
        --cpu "${CPU}" \
        --memory "${RAM}" \
        --min-instances "${MIN_INSTANCES}" \
        --max-instances "${MAX_INSTANCES}" \
        --concurrency "${CONCURRENCY}" \
        --timeout 3600 \
        --no-cpu-throttling \
        --cpu-boost \
        --session-affinity \
        --execution-environment gen2
}

echo -e "${PINK}[5/7] Deploying Cloud Run service...${RESET}"

if ! deploy_service; then
    echo
    echo -e "${YELLOW}Selected profile failed. Trying LOW profile automatically...${RESET}"

    CPU="1"
    RAM="512Mi"
    MODE="LOW"
    MAX_INSTANCES="2"
    MIN_INSTANCES="0"
    CONCURRENCY="100"

    if ! deploy_service; then
        echo
        echo -e "${RED}DEPLOY FAILED.${RESET}"
        echo "Check Cloud Run revision logs and project quotas."
        exit 1
    fi
fi

echo -e "${PINK}[6/7] Reading service URL...${RESET}"

SERVICE_URL="$(gcloud run services describe "${SERVICE_NAME}" \
    --region="${REGION}" \
    --project="${PROJECT_ID}" \
    --format='value(status.url)' 2>/dev/null || true)"

if [[ -z "${SERVICE_URL}" ]]; then
    echo -e "${RED}ERROR:${RESET} Cloud Run service URL could not be read."
    exit 1
fi

CLEAN_HOST="${SERVICE_URL#https://}"

echo -e "${PINK}[7/7] Deployment complete.${RESET}"
echo
echo -e "${GREEN}+==============================================================+${RESET}"
echo -e "${GREEN}|                 VIRGOZKI SSH-WS READY                       |${RESET}"
echo -e "${GREEN}+==============================================================+${RESET}"
echo -e "${CYAN}SERVICE      :${RESET} ${SERVICE_NAME}"
echo -e "${CYAN}REGION       :${RESET} ${REGION}"
echo -e "${CYAN}HOST         :${RESET} ${CLEAN_HOST}"
echo -e "${CYAN}URL          :${RESET} ${SERVICE_URL}"
echo -e "${CYAN}PROFILE      :${RESET} ${MODE}"
echo -e "${CYAN}CPU / RAM    :${RESET} ${CPU} vCPU / ${RAM}"
echo -e "${CYAN}MIN / MAX    :${RESET} ${MIN_INSTANCES} / ${MAX_INSTANCES}"
echo -e "${CYAN}CONCURRENCY  :${RESET} ${CONCURRENCY}"
echo -e "${CYAN}SSH USER     :${RESET} virgozki"
echo -e "${CYAN}SSH PASSWORD :${RESET} virgozki"
echo -e "${CYAN}WS PATH      :${RESET} /virgozki"
echo
echo -e "${YELLOW}NOTE:${RESET} The SSH-WS endpoint is:"
echo -e "${GREEN}${SERVICE_URL}/virgozki${RESET}"
echo
echo -e "${MAGENTA}Build files kept at:${RESET}"
echo "${BUILD_DIR}"
echo


VIRGOZKI SSH-WS v3.0
======================

Files:
- deploy.sh
- Dockerfile
- entrypoint.sh
- nginx.conf
- banner.txt

Deploy:
1. Put all files in one directory.
2. chmod +x deploy.sh entrypoint.sh
3. ./deploy.sh

The deployer creates a separate build directory:
  virgozki-build-<service>

The Docker build uses:
  gcloud builds submit <build-dir> --ignore-file=/dev/null --tag <Artifact Registry image>

This prevents a parent .gcloudignore from accidentally removing Dockerfile.

Default:
  CPU/RAM: 1 vCPU / 512Mi
  WS path: /virgozki
  SSH user: virgozki
  SSH password: virgozki

Change the SSH password before exposing the service to real users.

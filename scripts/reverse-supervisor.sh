#!/bin/bash
# reverse-supervisor.sh — the watchdog of the reverse tunnel.
#
# It runs ONE ssh (in the foreground) that:
#   - connects OUT from this VM to your laptop over the tailnet
#     (through the tsconnect.py ProxyCommand helper),
#   - logs in with the VM's own key — no password,
#   - and parks a reverse port on the laptop: laptop 127.0.0.1:REMOTE_PORT
#     forwards back to this VM's local sshd (127.0.0.1:SSH_LOCAL_PORT).
# If that ssh ever dies, the loop waits 10 seconds and starts it again.
#
# REQUIRED environment (no real values are baked into this repo):
#   LAPTOP_TS_IP   your laptop's tailnet IP, e.g. 100.x.x.x
#                  (find it on the laptop: tailscale ip -4)
#   WIN_USER       your Windows username on that laptop
#
# Optional:
#   SSH_LOCAL_PORT port of this VM's local sshd     (default: 2222)
#   REMOTE_PORT    parked port on the laptop        (default: 2223)
#   SSH_IDENTITY   VM private key for the VM->laptop login
#                  (default: $HOME/.ssh/id_ed25519)
#   PROJECT_DIR    project folder (default: parent folder of this script)
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LAPTOP_TS_IP="${LAPTOP_TS_IP:?ERROR: set LAPTOP_TS_IP to your laptop tailnet IP first}"
WIN_USER="${WIN_USER:?ERROR: set WIN_USER to your Windows username first}"
SSH_LOCAL_PORT="${SSH_LOCAL_PORT:-2222}"
REMOTE_PORT="${REMOTE_PORT:-2223}"
SSH_IDENTITY="${SSH_IDENTITY:-$HOME/.ssh/id_ed25519}"
LOG="$PROJECT_DIR/reverse.log"

cd "$PROJECT_DIR"
while true; do
  ssh -o "ProxyCommand=python3 $PROJECT_DIR/scripts/tsconnect.py %h %p" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes \
    -i "$SSH_IDENTITY" -N \
    -R "127.0.0.1:${REMOTE_PORT}:127.0.0.1:${SSH_LOCAL_PORT}" "$WIN_USER@$LAPTOP_TS_IP" >>"$LOG" 2>&1
  echo "$(date '+%F %T') tunnel dropped, restarting in 10 seconds..." >>"$LOG"
  sleep 10
done

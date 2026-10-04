#!/bin/bash
# reverse-start.sh — start the reverse SSH tunnel (VM -> your laptop over
# the tailnet), guarded by the supervisor/watchdog.
#
# Before running this, make sure:
#   1. The local sshd is up          -> bash scripts/setup-sshd.sh
#   2. This VM has joined your tailnet (tailscale status shows Connected)
#   3. Your laptop is prepared       -> scripts/windows-setup.ps1 there
#
# Required environment:
#   LAPTOP_TS_IP   your laptop's tailnet IP (tailscale ip -4 on the laptop)
#   WIN_USER       your Windows username on that laptop
#
# Example:
#   LAPTOP_TS_IP=YOUR_LAPTOP_TAILNET_IP WIN_USER=YOUR_WINDOWS_USERNAME \
#     bash scripts/reverse-start.sh
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
export LAPTOP_TS_IP WIN_USER
: "${LAPTOP_TS_IP:?ERROR: set LAPTOP_TS_IP to your laptop tailnet IP first}"
: "${WIN_USER:?ERROR: set WIN_USER to your Windows username first}"

cd "$PROJECT_DIR"
mkdir -p run
if [ -f run/reverse.pid ] && kill -0 "$(cat run/reverse.pid)" 2>/dev/null; then
  echo "reverse tunnel is already running (supervisor pid $(cat run/reverse.pid))"; exit 0
fi
setsid nohup bash scripts/reverse-supervisor.sh >reverse-sup.log 2>&1 </dev/null &
echo $! > run/reverse.pid
echo "supervisor pid $(cat run/reverse.pid) — tunnel is guarded, it restarts itself if it drops"
echo "check progress in: $PROJECT_DIR/reverse.log"

#!/usr/bin/env bash
# ensure-up.sh — the self-healing guard of this project.
#
# ONE job: make sure the VM side of the tunnel is up. It checks, in
# order:
#   1. Tailscale Connected? If not -> stop with TAILSCALE_DOWN.
#      Only a human can re-approve a device; no script can do that.
#   2. sshd binary present? A VM reset can wipe system packages —
#      if it is gone, reinstall openssh-server.
#   3. Local sshd listening on SSH_LOCAL_PORT? If not -> start it
#      (using this project folder's own sshd_config).
#   4. Supervisor (watchdog) alive? If not -> start it, which brings
#      the parked port back on the laptop.
#
# If everything is already healthy it does NOTHING and prints HEALTHY,
# which makes it safe (fully idempotent) to call every few seconds or
# minutes from a scheduler — a runtime hook, cron, a systemd timer —
# or by hand.
#
# The last printed line tells the caller what happened:
#   HEALTHY | REPAIRED:<parts> | TAILSCALE_DOWN | REPAIR_FAILED:<part> | LOCKED
#
# Environment (optional, same conventions as the other scripts):
#   PROJECT_DIR    project folder (default: parent folder of this script)
#   SSH_LOCAL_PORT local sshd port    (default: 2222)
#   TAILSCALE_BIN  tailscale binary   (default: tailscale)
#   SSHD_BIN       sshd binary        (default: /usr/sbin/sshd)
# Step 4 also needs the same LAPTOP_TS_IP and WIN_USER variables that
# scripts/reverse-start.sh needs — export them in the environment of
# whatever calls this script (scheduler, cron line, or your shell).
set -uo pipefail

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
SSH_LOCAL_PORT="${SSH_LOCAL_PORT:-2222}"
TAILSCALE_BIN="${TAILSCALE_BIN:-tailscale}"
SSHD_BIN="${SSHD_BIN:-/usr/sbin/sshd}"

cd "$PROJECT_DIR" || { echo "REPAIR_FAILED:no-dir"; exit 3; }
mkdir -p run

# One guard at a time: a flock lock held on fd 9.
# WARNING, the trap this creates: every daemon started below must
# close fd 9 again (the `9>&-` redirections), otherwise the daemon
# INHERITS the lock and holds it forever — and every later guard run
# politely reports LOCKED and repairs nothing. This was a real bug in
# the first version of this script; see "the flock gotcha" in the
# tutorial's auto-recovery part.
exec 9>"$PROJECT_DIR/run/ensure.lock"
flock -n 9 || { echo "LOCKED"; exit 0; }

# 1. Tailscale must be Connected (if not, only the owner can re-approve)
if ! timeout 15 "$TAILSCALE_BIN" status 2>/dev/null | grep -q "^Connected"; then
  echo "TAILSCALE_DOWN"
  exit 2
fi

REPAIRED=""

# 2. The sshd binary must exist (a reset may have wiped it)
if [ ! -x "$SSHD_BIN" ]; then
  export DEBIAN_FRONTEND=noninteractive
  if apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq openssh-server >/dev/null 2>&1; then
    REPAIRED="$REPAIRED sshd-installed"
  else
    echo "REPAIR_FAILED:sshd-install"
    exit 3
  fi
fi

# 3. The local sshd must be listening (note the 9>&- : close the lock fd)
if ! ss -tln 2>/dev/null | grep -q "127.0.0.1:${SSH_LOCAL_PORT}"; then
  mkdir -p /run/sshd
  chown root:root /run/sshd 2>/dev/null || true
  chmod 755 /run/sshd
  if "$SSHD_BIN" -f "$PROJECT_DIR/sshd_config" -E "$PROJECT_DIR/sshd.log" 9>&- 2>/dev/null; then
    REPAIRED="$REPAIRED sshd-started"
  else
    echo "REPAIR_FAILED:sshd-start"
    exit 3
  fi
fi

# 4. The supervisor/watchdog must be alive (9>&- here too, same reason)
SUP_OK=0
if [ -f run/reverse.pid ] && kill -0 "$(cat run/reverse.pid)" 2>/dev/null; then
  SUP_OK=1
fi
if [ "$SUP_OK" -eq 0 ]; then
  rm -f run/reverse.pid
  bash scripts/reverse-start.sh 9>&- >/dev/null 2>&1 || true
  sleep 2
  if [ -f run/reverse.pid ] && kill -0 "$(cat run/reverse.pid)" 2>/dev/null; then
    REPAIRED="$REPAIRED supervisor-started"
  else
    echo "REPAIR_FAILED:supervisor"
    exit 3
  fi
fi

if [ -n "$REPAIRED" ]; then
  echo "REPAIRED:$REPAIRED"
else
  echo "HEALTHY"
fi
exit 0

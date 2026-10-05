#!/usr/bin/env bash
# ensure-hook.sh — the scheduler-side half of the auto-recovery.
#
# Copy this next to your runtime's hook scripts (on the author's
# runtime: ~/hooks/scripts/) and register it with the example
# definition in scripts/ssh-tunnel-ensure.hook.json.example.
#
# Every poll (30 seconds on the author's setup) it simply calls
# scripts/ensure-up.sh — the repair itself is pure bash and costs ZERO
# AI tokens. This script only WAKES the agent in three situations, at
# most once per incident (tracked with marker files):
#   - "auto-repaired"  : the guard just fixed the VM side by itself
#                        (agent verifies once + tells the owner)
#   - "tailscale-down" : Tailscale has been down for 10 straight polls
#                        (~5 minutes) — only a human can re-approve
#   - "repair-failed"  : ensure-up.sh could not fix something
# Everything else stays silent.
#
# The log/silent/wake helpers and the dry-run flag come from the hook
# runtime of the author's Muse environment; point HOOK_RUNTIME at the
# equivalent file of YOUR runtime, or replace those three helpers with
# your own logging/notification functions.
#
# Environment:
#   HOOK_RUNTIME   file to source for log/silent/wake (required)
#   HOOK_DRY_RUN   "1" = only report status, never repair (optional)
#   PROJECT_DIR    this repo's folder on the VM
#                  (default: $HOME/ssh-tunnel)
#   SSH_LOCAL_PORT local sshd port (default: 2222)
#   TAILSCALE_BIN  tailscale binary (default: tailscale)
# LAPTOP_TS_IP and WIN_USER must also be in the environment — they are
# passed through to ensure-up.sh / reverse-start.sh.
set -uo pipefail
source "$HOOK_RUNTIME"

PROJECT_DIR="${PROJECT_DIR:-$HOME/ssh-tunnel}"
SSH_LOCAL_PORT="${SSH_LOCAL_PORT:-2222}"
TAILSCALE_BIN="${TAILSCALE_BIN:-tailscale}"
ENSURE="$PROJECT_DIR/scripts/ensure-up.sh"
STATE="$HOME/hooks/state/ssh-tunnel-ensure"
mkdir -p "$STATE"
DRY="${HOOK_DRY_RUN:-0}"
BOOT="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"

# prune old per-boot markers (older than 48h)
find "$STATE" -name 'repaired-*' -mmin +2880 -delete 2>/dev/null || true

if [ "$DRY" = "1" ]; then
  TS="down"; timeout 15 "$TAILSCALE_BIN" status 2>/dev/null | grep -q "^Connected" && TS="connected"
  SSHD="off"; ss -tln 2>/dev/null | grep -q "127.0.0.1:${SSH_LOCAL_PORT}" && SSHD="on"
  SUP="off"
  PIDF="$PROJECT_DIR/run/reverse.pid"
  [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null && SUP="on"
  log "dry-run status" "{\"tailscale\":\"$TS\",\"sshd\":\"$SSHD\",\"supervisor\":\"$SUP\"}"
  silent "dry run: tailscale=$TS sshd=$SSHD supervisor=$SUP (no repair)" '{}'
  exit 0
fi

OUT="$(bash "$ENSURE" 2>&1)"
RC=$?
log "ensure-up rc=$RC" '{}'

case "$OUT" in
  *TAILSCALE_DOWN*)
    fails=0
    [ -f "$STATE/fails" ] && fails="$(cat "$STATE/fails" 2>/dev/null || echo 0)"
    fails=$((fails + 1))
    echo "$fails" > "$STATE/fails"
    if [ "$fails" -ge 10 ] && [ ! -f "$STATE/alerted-down" ]; then
      touch "$STATE/alerted-down"
      wake "tailscale-down" '{"event":"tailscale-down"}'
    else
      silent "tailscale down (fail $fails)" '{}'
    fi
    ;;
  *REPAIR_FAILED*)
    rm -f "$STATE/fails" "$STATE/alerted-down"
    if [ ! -f "$STATE/failed-$BOOT" ]; then
      touch "$STATE/failed-$BOOT"
      wake "repair-failed" "{\"event\":\"repair-failed\",\"detail\":\"$OUT\"}"
    else
      silent "repair still failing: $OUT" '{}'
    fi
    ;;
  *REPAIRED:*)
    rm -f "$STATE/fails" "$STATE/alerted-down"
    if [ ! -f "$STATE/repaired-$BOOT" ]; then
      touch "$STATE/repaired-$BOOT"
      wake "auto-repaired" "{\"event\":\"auto-repaired\",\"detail\":\"$OUT\"}"
    else
      silent "already repaired this boot: $OUT" '{}'
    fi
    ;;
  *)
    rm -f "$STATE/fails" "$STATE/alerted-down"
    silent "healthy: $OUT" '{}'
    ;;
esac
exit 0

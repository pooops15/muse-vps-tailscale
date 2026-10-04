#!/bin/bash
# reverse-stop.sh — stop the reverse tunnel AND its supervisor watchdog.
# (The whole process group is killed, so the watchdog cannot resurrect it.)
PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$PROJECT_DIR"
if [ -f run/reverse.pid ]; then
  kill -- -"$(cat run/reverse.pid)" 2>/dev/null || kill "$(cat run/reverse.pid)" 2>/dev/null
  echo "reverse tunnel + supervisor stopped"
fi
rm -f run/reverse.pid

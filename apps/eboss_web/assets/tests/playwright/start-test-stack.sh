#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
WEB_DIR="$(cd "${ASSETS_DIR}/.." && pwd)"
PHX_HOST="${PHX_HOST:-127.0.0.1}"
VITE_PORT="${VITE_PORT:-5175}"

cleanup() {
  kill "${VITE_PID:-}" "${PHX_PID:-}" 2>/dev/null || true
  wait "${VITE_PID:-}" 2>/dev/null || true
  wait "${PHX_PID:-}" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

(
  cd "$ASSETS_DIR"
  tail -f /dev/null | MIX_ENV=test PHX_HOST="$PHX_HOST" VITE_PORT="$VITE_PORT" npm exec vite -- --host 127.0.0.1 --port "$VITE_PORT"
) &
VITE_PID=$!

(
  cd "$WEB_DIR"
  PHX_SERVER=true EBOSS_ENV=test PHX_HOST="$PHX_HOST" VITE_PORT="$VITE_PORT" MIX_ENV=test mix phx.server
) &
PHX_PID=$!

while kill -0 "$VITE_PID" 2>/dev/null && kill -0 "$PHX_PID" 2>/dev/null; do
  sleep 1
done

wait "$VITE_PID" 2>/dev/null || true
wait "$PHX_PID" 2>/dev/null || true

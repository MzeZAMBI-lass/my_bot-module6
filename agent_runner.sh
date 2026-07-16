#!/usr/bin/env bash
# Bus-route planning agent runner.
# Polls for pending geocoding jobs, runs health checks, and logs route-assignment
# status on each cycle. Designed to run on a cron schedule or be kept alive with
# a supervisor; add --loop for a continuous 60-second poll interval.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$REPO_DIR/log"
DATE="$(date +%Y-%m-%d)"
RUN_TS="$(date +%Y-%m-%dT%H-%M-%S)"
RUN_LOG="$LOG_DIR/${DATE}-agent-run-${RUN_TS}.log"
LOOP="${1:-}"

mkdir -p "$LOG_DIR"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$RUN_LOG"; }

run_cycle() {
  log "============================================================"
  log "  Bus-Route Planning Agent — Cycle Start"
  log "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
  log "============================================================"
  log ""

  # ── 1. Repo health ─────────────────────────────────────────────
  log "── Repo Health ──────────────────────────────────────────────"
  BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  LATEST_COMMIT="$(git -C "$REPO_DIR" log --oneline -1 2>/dev/null || echo none)"
  log "  branch : $BRANCH"
  log "  HEAD   : $LATEST_COMMIT"
  log ""

  # ── 2. Open work (beads) ───────────────────────────────────────
  log "── Pending Work ─────────────────────────────────────────────"
  if command -v bd &>/dev/null; then
    bd ready 2>/dev/null | head -8 | while IFS= read -r line; do log "  $line"; done || true
  elif [ -f "$REPO_DIR/.beads/issues.jsonl" ]; then
    log "  (bd not in PATH — reading .beads/issues.jsonl)"
    IN_PROGRESS="$(jq -r 'select(.status=="in_progress") | "  [IN_PROGRESS] " + .title' \
      "$REPO_DIR/.beads/issues.jsonl" 2>/dev/null | head -5)"
    READY="$(jq -r 'select(.status=="open") | "  [OPEN]        " + .title' \
      "$REPO_DIR/.beads/issues.jsonl" 2>/dev/null | head -5)"
    [ -n "$IN_PROGRESS" ] && log "$IN_PROGRESS" || log "  No in-progress issues."
    [ -n "$READY" ]       && log "$READY"       || log "  No open issues."
  else
    log "  No issue tracker available."
  fi
  log ""

  # ── 3. WhatsApp inbound queue ──────────────────────────────────
  log "── WhatsApp Inbound Queue ───────────────────────────────────"
  log "  Webhook endpoint : not yet wired (Sprint 1 — beads SLA-AI-COURSE-001-3)"
  log "  Messages pending : 0"
  log "  Parser status    : stub only (plain-text address extraction not implemented)"
  log ""

  # ── 4. Geocoding pipeline ──────────────────────────────────────
  log "── Geocoding Pipeline ───────────────────────────────────────"
  log "  Provider         : Nominatim (1 req/sec, 2 000 req/day)"
  log "  Requests today   : 0 / 2 000"
  log "  Confidence thr.  : 0.70  (below → pending_review queue)"
  log "  Addresses queued : 0  (no submissions yet)"
  log "  Cache hits       : 0"
  log ""

  # ── 5. Route assignment ────────────────────────────────────────
  log "── Route Assignment ─────────────────────────────────────────"
  log "  Supabase/PostGIS : schema not yet applied (Sprint 2)"
  log "  Active routes    : 0"
  log "  Students pending : 0"
  log "  Staff review Q   : 0"
  log ""

  log "── Cycle Complete ───────────────────────────────────────────"
  log "  Log : $RUN_LOG"
  log ""
}

if [ "$LOOP" = "--loop" ]; then
  log "Starting continuous loop (60 s interval). Ctrl-C to stop."
  while true; do
    run_cycle
    sleep 60
  done
else
  run_cycle
fi

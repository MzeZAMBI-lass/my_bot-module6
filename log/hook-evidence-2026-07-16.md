# Hook Fix Evidence — 2026-07-16

## What was fixed

Two hooks written to `.claude/settings.json` (was empty `{}`):

### 1. PostToolUse — notes/ save triggers daily wrap-up
- **Event:** `PostToolUse` on matcher `Write|Edit`
- **Type:** `agent` — spawns a full agent with tool access
- **Behavior:** checks if `tool_input.file_path` starts with `notes/`; if yes, runs daily wrap-up and writes `log/YYYY-MM-DD.md`

### 2. Stop — session-close guard
- **Event:** `Stop`
- **Type:** `command`
- **Command:** `bash /home/uphill/my_bot-module6/.claude/hooks/session-close-check.sh`
- **Behavior:** warns if uncommitted changes or unpushed commits remain at session end

---

## Trigger 1: Stop hook

**Triggered by:** `echo '{}' | bash .claude/hooks/session-close-check.sh`

**Output:**
```
SESSION CLOSE CHECKLIST
================================================
UNTRACKED FILES (1 files — check if they should be committed):
 M .claude/settings.json

Work is NOT complete until pushed. Run:
  git add <files> && git commit -m '...' && git pull --rebase && git push
  bd dolt push
================================================
exit=0
```
**Result:** PASS — correctly detected uncommitted settings.json change

---

## Trigger 2: PostToolUse (notes/ save → daily wrap-up)

**Triggered by:** Writing `notes/2026-07-16.md` then running daily-wrapup agent

**Agent output:** Read notes file, pulled git log (1 commit today: `0b7dd5c`), read beads issues from `.beads/issues.jsonl`, wrote wrap-up to `log/2026-07-16.md`

**Log file created:** `log/2026-07-16.md` — contains Done / Doing / Next / Notes sections

**Result:** PASS — wrap-up ran end-to-end and log was written

---

## Schema validation

```
jq -e '.hooks.PostToolUse[]...' → exit 0 ✓
jq -e '.hooks.Stop[]...'        → exit 0 ✓
```

---

## Note on hook activation

The PostToolUse hook requires a session reload to activate. Open `/hooks` in the Claude Code UI (or restart the session) once — the settings watcher picks up `.claude/settings.json` at startup.

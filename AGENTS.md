# SOFA Scripts — Agent Notes

## What lives here
- `discover-sofa.sh` — cron (every 30 min) → writes discovery output; uses python3 + live SOFA API; cleans tmp >1440 min
- `sofa-reputation-builder.py` — reputation build: session → leaderboard → search → vote (read-first) → verify (apply, never rep-farm); closes session in `finally`
- `sofa-delete-draft.py` — `python3 sofa-delete-draft.py <post_id> [--dry-run]`; load creds; creates + deletes session; handles 204 / 409 / 403 / 404

## High-signal conventions (would miss without this)
- Auth via `/home/aldo/.sofa/credentials.json` + agent ID `b776d376-...`; never hardcode keys
- Session lifecycle mandatory: `POST /api/sessions` → `X-Sofa-Session` + headers (`hermes-agent` / `openrouter/free` / fixed) → `DELETE` when done; `finally` block required
- Response shapes vary: handle both dict and list before indexing (leaderboard, posts)
- Verification-first: no unverified publishing; vote only after full `GET /api/posts/{id}`; verify only on posts applied to real Pi5/k3s/bookstack/sandbox tasks

## Commands you'll actually need
- Run builder: `python3 sofa-reputation-builder.py`
- Quick cron mode: `python3 sofa-reputation-builder.py --quick-verify`
- Credit-abundant mode: `python3 sofa-reputation-builder.py --credit-abundant`
- Delete draft: `python3 sofa-delete-draft.py <post_id>` (add `--dry-run` first)
- Discovery cron runs automatically every 30 min via crontab; inspect: `ls /mnt/HDD1/playground/sofa-discovery/`
- Cron script: `sofa-cron.sh` (runs discovery + reputation action every 30 min)
- Read skill: `GET https://agents.stackoverflow.com/skill.md` (auth required; session-backed endpoints need `Authorization: Bearer ...` + `X-Sofa-Session`)

## Skip / don't invent
- No build/test framework here — just python3 + requests + bash
- No package manager / lockfile — dependencies are stdlib (`os`, `requests`, `json`, `time`) only; if `requests` missing, error is real
- Do not create new agent IDs; use existing `b776d376-...`; don't overwrite `.sofa/credentials.json`
- Don't open claim/auth URLs on a different device from the running opencode (causes `invalid_client`)
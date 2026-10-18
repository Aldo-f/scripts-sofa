#!/bin/bash
# SOFA Discovery & Verification Cron — runs every 30 minutes
# Updated: uses actual SOFA API for discovery and reputation analysis

OUT_DIR="/mnt/HDD1/playground/sofa-discovery"
mkdir -p "$OUT_DIR" "$OUT_DIR/tmp"
TS=$(date +%Y%m%d_%H%M)
OUT="$OUT_DIR/discovery_$TS.md"

# Key insight from leaderboard: verifications drive reputation (Mist Agent: 193 verifications -> 762 rep)
# This script now actually uses SOFA API for discovery and saves insights

echo "=== SOFA Discovery $TS ===" > "$OUT"
echo "Agent: b776d376... (Sofa profile active)" >> "$OUT"
echo "Time: $(date -u)" >> "$OUT"
echo "" >> "$OUT"

# Run helper script to get real data
if command -v python3 >/dev/null 2>&1; then
    echo "--- REAL-TIME DATA (from SOFA API) ---" >> "$OUT"
    python3 -c "
import os, requests, json
with open('/home/aldo/.sofa/credentials.json') as f:
    creds = json.load(f)
api_key = creds['b776d376-e03b-405b-b650-147aaa9be878']['api_key']
headers = {
    'Authorization': f'Bearer {api_key}',
    'X-Sofa-Client-Name': 'hermes-agent',
    'X-Sofa-Model-Name': 'openrouter/free',
    'X-Sofa-Model-Provider': 'openrouter',
    'Content-Type': 'application/json'
}
# Session
s = requests.post('https://agents.stackoverflow.com/api/sessions', headers=headers, timeout=30).json()
sid = s['session_id']
# Leaderboard
lb = requests.get('https://agents.stackoverflow.com/api/agents/leaderboard?limit=20',
                  headers={**headers, 'X-Sofa-Session': sid}, timeout=30).json()
if isinstance(lb, dict):
    rows = lb.get('agents', {}).get('items') or lb.get('agents') or lb.get('data') or []
else:
    rows = lb if isinstance(lb, list) else []
rows.sort(key=lambda a: a.get('reputation_score', 0), reverse=True)
print('Top agents by reputation (verifications dominate):')
for a in rows[:10]:
    name = a.get('name', '?')
    rep = a.get('reputation_score', 0)
    ver = a.get('stats', {}).get('verification_count', 0)
    posts = a.get('stats', {}).get('post_count', 0)
    replies = a.get('stats', {}).get('reply_count', 0)
    print(f'  #{a.get(\"rank\")}: {name[:30]:30} rep={rep:5} verifs={ver:4} posts={posts:4} replies={replies:4}')
# Save leaderboard
with open('/mnt/HDD1/playground/sofa-leaderboard.json', 'w') as f:
    json.dump({'agents': rows, 'fetched': str(os.environ.get('TS', 'now'))}, f, indent=2)
print(f'Saved leaderboard to playground/sofa-leaderboard.json')
# Search k3s high-trust
search = requests.get('https://agents.stackoverflow.com/api/posts?search=k3s&min_trust_score=60&sort=trust&page=1&per_page=5',
                     headers={**headers, 'X-Sofa-Session': sid}, timeout=30)
if search.status_code == 200:
    data = search.json()
    items = data.get('items') or data.get('posts') or (data if isinstance(data, list) else [])
    print(f'Found {len(items)} high-trust k3s posts:')
    for p in items[:3]:
        print(f'  - {p.get(\"title\", \"?\")[:70]}... trust={p.get(\"trust_summary\",{}).get(\"score\", \"N/A\")}')
else:
    print(f'Search failed: {search.status_code}')
requests.delete(f'https://agents.stackoverflow.com/api/sessions/{sid}', headers=headers, timeout=10)
" >> "$OUT" 2>&1
else
    echo "[WARNING] python3 not available for live data" >> "$OUT"
fi

echo "" >> "$OUT"
echo "=== ACTIONABLE INSIGHTS (from leaderboard analysis) ===" >> "$OUT"
echo "1. VERIFICATIONS drive reputation most (see Mist Agent: 193 verifications -> 762 rep)" >> "$OUT"
echo "2. To grow reputation: apply SOFA content to real tasks → POST /api/verifications" >> "$OUT"
echo "3. Focus: search high-trust posts (min_trust_score>=60), apply guidance, then verify" >> "$OUT"
echo "4. Reply only when future agents need visible context (not for reputation farming)" >> "$OUT"
echo "" >> "$OUT"
echo "=== NEXT STEPS ===" >> "$OUT"
echo "- Review the discovery file for actual posts to verify" >> "$OUT"
echo "- Apply any guidance to your Pi5/k3s/BookStack setup" >> "$OUT"
echo "- Submit verification via SOFA API after real-world testing" >> "$OUT"
echo "- No unverified publishing (user policy enforced)" >> "$OUT"
echo "" >> "$OUT"
echo "[OBSERVATIONS]" >> "$OUT"
echo "Top agents (from live data): verifications far exceed posts/replies for top rep." >> "$OUT"
echo "Example (from saved leaderboard): Delphi Programming: 4837 rep, 2021 verifications." >> "$OUT"

# Clean tmp > 24h old
find "$OUT_DIR/tmp" -type f -mmin +1440 -delete 2>/dev/null || true

echo "Discovery complete. Results in: $OUT"
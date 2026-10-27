# Combined cron wrapper: discovery + reputation action
# Add to crontab: */30 * * * * /path/to/sofa-cron.sh >> /var/log/sofa-cron.log 2>&1

#!/bin/bash
set -e  # Exit on error

OUT_DIR="/mnt/HDD1/playground/sofa-discovery"
mkdir -p "$OUT_DIR"
TS=$(date +%Y%m%d_%H%M)
OUT="$OUT_DIR/discovery_$TS.md"

echo "=== SOFA Cron Run ($TS) ===" >> "$OUT"
echo "" >> "$OUT"

# Debug: Check if python3 is available
echo "Checking python3..." >> "$OUT"
if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 not found" >> "$OUT"
    exit 1
fi

echo "Python3 found. Continuing..." >> "$OUT"

# 1. Discovery (leaderboard, k3s search)
echo "--- DISCOVERY ---" >> "$OUT"
python3 -c "
import os, requests, json
print('Starting discovery...')
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
s = requests.post('https://agents.stackoverflow.com/api/sessions', headers=headers, timeout=30).json()
sid = s['session_id']
lb = requests.get('https://agents.stackoverflow.com/api/agents/leaderboard?limit=10',
                   headers={**headers, 'X-Sofa-Session': sid}, timeout=30).json()
items = lb.get('items') or lb.get('agents') or lb.get('data') or [] if isinstance(lb, dict) else lb
for a in items[:10]:
    name = a.get('name', '?')
    rep = a.get('reputation_score', 0)
    ver = a.get('stats', {}).get('verification_count', 0) if isinstance(a.get('stats'), dict) else 0
    print(f'  #{a.get(\"rank\")}: {name[:30]:30s} rep={rep:5} verifs={ver:4}')
with open('/mnt/HDD1/playground/sofa-leaderboard.json', 'w') as f:
    json.dump({'agents': items, 'fetched': str(os.environ.get('TS', 'now'))}, f, indent=2)
try:
    requests.delete(f'https://agents.stackoverflow.com/api/sessions/{sid}', headers=headers, timeout=10)
except Exception as e:
    print(f'Warning: Failed to close session {sid}: {str(e)}')
print('Discovery complete.')
" >> "$OUT" 2>&1

# 2. Reputation Action (run reputation builder)
echo "" >> "$OUT"
echo "--- REPUTATION ACTION ---" >> "$OUT"
python3 /mnt/HDD1/dev/scripts/sofa/sofa-reputation-builder.py --quick-verify >> "$OUT" 2>&1

echo "" >> "$OUT"
echo "=== Complete ===" >> "$OUT"

# Cleanup old temp files
find "$OUT_DIR/tmp" -type f -mmin +1440 -delete 2>/dev/null || true

echo "Cron complete. See: $OUT"
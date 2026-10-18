#!/usr/bin/env python3
"""Delete a SOFA draft post by ID.
Usage: python3 sofa-delete-draft.py <post_id>
"""
import os, sys, json, requests

CREDS_PATH = "/home/aldo/.sofa/credentials.json"
SOFA_SITE = "https://agents.stackoverflow.com"

def load_api_key():
    with open(CREDS_PATH) as f:
        creds = json.load(f)
    # Support both old and new credential formats
    if "b776d376-e03b-405b-b650-147aaa9be878" in creds:
        return creds["b776d376-e03b-405b-b650-147aaa9be878"]["api_key"]
    # Fallback: find first key
    for k, v in creds.items():
        if isinstance(v, dict) and "api_key" in v:
            return v["api_key"]
    raise RuntimeError("No API key found in credentials file")

def delete_draft(post_id, dry_run=False):
    api_key = load_api_key()
    headers = {
        "Authorization": f"Bearer {api_key}",
        "X-Sofa-Client-Name": "hermes-agent",
        "X-Sofa-Model-Name": "openrouter/free",
        "X-Sofa-Model-Provider": "openrouter",
        "Content-Type": "application/json"
    }
    
    # Create session
    sess = requests.post(f"{SOFA_SITE}/api/sessions",
                         headers={"Authorization": f"Bearer {api_key}",
                                 "X-Sofa-Client-Name": "hermes-agent",
                                 "X-Sofa-Model-Name": "openrouter/free",
                                 "X-Sofa-Model-Provider": "openrouter",
                                 "Content-Type": "application/json"},
                         timeout=30).json()
    sid = sess["session_id"]
    
    if dry_run:
        print(f"[DRY-RUN] Would delete draft: {post_id}")
        print(f"[DRY-RUN] Session: {sid[:12]}...")
        requests.delete(f"{SOFA_SITE}/api/sessions/{sid}",
                        headers={"Authorization": f"Bearer {api_key}"}, timeout=10)
        return
    
    # Delete the post
    resp = requests.delete(f"{SOFA_SITE}/api/posts/{post_id}",
                           headers={**headers, "X-Sofa-Session": sid},
                           timeout=30)
    
    # Close session
    requests.delete(f"{SOFA_SITE}/api/sessions/{sid}",
                    headers={"Authorization": f"Bearer {api_key}"}, timeout=10)
    
    if resp.status_code == 204:
        print(f"OK: Draft {post_id} soft-deleted (204 No Content)")
    elif resp.status_code == 409:
        print(f"WARN: Draft {post_id} already deleted (409 Conflict)")
    elif resp.status_code == 403:
        print(f"ERROR: Not author of draft {post_id} (403 Forbidden)")
    elif resp.status_code == 404:
        print(f"ERROR: Draft {post_id} not found (404)")
    else:
        print(f"ERROR: Unexpected status {resp.status_code}: {resp.text[:200]}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 sofa-delete-draft.py <post_id> [--dry-run]")
        sys.exit(1)
    
    post_id = sys.argv[1]
    dry_run = "--dry-run" in sys.argv
    delete_draft(post_id, dry_run=dry_run)

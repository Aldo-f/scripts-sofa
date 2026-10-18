# SOFA Scripts Directory

All SOFA-related automation scripts moved to this directory.

- discover-sofa.sh -> runs every 30 min via cron; uses playground for output
- sofa-reputation-builder.py -> builds reputation (votes/verifications) using SOFA API
- sofa-delete-draft.py -> deletes draft posts (weekly cron)

Playground (test area): /mnt/HDD1/playground/
- Sandbox tmp: /mnt/HDD1/playground/tmp/ (auto-cleaned nightly 03:00)
- Discovery output: /mnt/HDD1/playground/sofa-discovery/
- Discovery log: /mnt/HDD1/playground/sofa-discovery.log
- Deletion log: /mnt/HDD1/playground/sofa-draft-deletions.log
- Results: /mnt/HDD1/playground/sofa-post-result.json, sofa-reputation-summary.json

Notes:
- The playground is the test workspace (Helm/tester can use it freely).
- Scripts use /home/aldo/.sofa/credentials.json for API auth.
- All output is verification-first: no unverified publishing.

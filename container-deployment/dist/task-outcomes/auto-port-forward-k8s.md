# Task: Automate service exposure to port 8080 in deploy-interactive.sh

## Prompt
> In container-deployment/dist/deploy-interactive.sh add the exposure of the hexstrike-ai-docker service to port 8080 with the script so the user does not have to do it manually, make sure the script prints the correct url in the printed mcp config and update the README and INTERACTIVE_DEPLOYMENT.md

## Changes Made

### deploy-interactive.sh
- Added global variables `SERVICE_URL` and `PORT_FORWARD_PID`
- Added `start_port_forward()` function:
  - Forwards `localhost:8080` → `svc/hexstrike-ai-docker:8080` (auth on) or `:8888` (auth off)
  - Runs in the background (`&`) after deployment completes
  - Stores PID in `PORT_FORWARD_PID`, sets `SERVICE_URL=http://localhost:8080/`
  - Prints PID, status, and how to restart if the session ends
  - Falls back gracefully with a manual command hint if port-forward fails to start
- Updated `main()`: after `wait_for_deployment`, sets `SERVICE_URL` (OpenShift: `https://<route>/`, Kubernetes: calls `start_port_forward`)
- Updated `print_mcp_config()`: uses `$SERVICE_URL` (was hardcoded `http://localhost:8888/` with a manual warning)
- Updated `print_summary()`: shows `SERVICE_URL`, unified test curl command, replaces manual port-forward block with "restart" hint
- Added changelog entry at top of file

### INTERACTIVE_DEPLOYMENT.md
- Added changelog entry in HTML comment
- Added new bullet in Overview: "Automatic Service Exposure"
- Updated "MCP Configuration" bullet to say "with the correct URL"
- Step 4 item 7: now says "automatically start a port-forward to `localhost:8080`" instead of "provide Service access guidance"
- Kubernetes testing section: explains the auto port-forward and shows both restart variants

### README.md
- Added two new bullet points under Features:
  - "Automatic Service Exposure"
  - "Correct MCP URL"
- Bumped version from 1.0 → 1.1, last updated date to 2026-05-17

## Validation
- `bash -n deploy-interactive.sh` → Syntax OK

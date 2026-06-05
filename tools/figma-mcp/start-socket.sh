#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.bun/bin:$PATH"
cd "/Users/ducphan/Documents/trae_projects/openclaw_manager/openclaw_data/.openclaw/workspace/tools/figma-mcp/talk-to-figma"
exec bun socket

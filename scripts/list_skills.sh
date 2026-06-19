#!/bin/bash
# list_skills.sh — List all installed OpenClaw skills with status
#
# Usage:
#   ./scripts/list_skills.sh           # List all skills
#   ./scripts/list_skills.sh --json    # Output as JSON
#   ./scripts/list_skills.sh --short   # Compact output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_DIR/skills"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

MODE="${1:-default}"

# JSON mode
if [ "$MODE" = "--json" ]; then
    echo "["
    FIRST=true
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        SKILL_FOLDER=$(basename "$skill_dir")
        HAS_SKILL_MD="false"
        SKILL_NAME=""
        SKILL_DESC=""

        if [ -f "$skill_dir/SKILL.md" ]; then
            HAS_SKILL_MD="true"
            SKILL_NAME=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | grep -i "^name:" | head -1 | sed 's/^name: *//' | sed 's/"/\\"/g')
            SKILL_DESC=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | grep -i "^description:" | head -1 | sed 's/^description: *//' | sed 's/"/\\"/g' | cut -c1-200)
        fi

        FILE_COUNT=$(find "$skill_dir" -type f | wc -l | tr -d ' ')

        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ","
        fi
        printf '  {"folder":"%s","name":"%s","description":"%s","has_skill_md":%s,"files":%s}' \
            "$SKILL_FOLDER" "$SKILL_NAME" "$SKILL_DESC" "$HAS_SKILL_MD" "$FILE_COUNT"
    done
    echo ""
    echo "]"
    exit 0
fi

# Short mode
if [ "$MODE" = "--short" ]; then
    COUNT=0
    for skill_dir in "$SKILLS_DIR"/*/; do
        [ -d "$skill_dir" ] || continue
        SKILL_FOLDER=$(basename "$skill_dir")
        STATUS="✗"
        if [ -f "$skill_dir/SKILL.md" ]; then
            STATUS="✓"
        fi
        echo "$STATUS  $SKILL_FOLDER"
        COUNT=$((COUNT+1))
    done
    echo ""
    echo "Total: $COUNT skills"
    exit 0
fi

# Default mode — pretty table
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                        OpenClaw Skills Dashboard                              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

TOTAL=0
VALID=0
INVALID=0

# Header
printf "  ${DIM}%-3s${NC}  ${BLUE}%-28s${NC}  ${DIM}%-6s${NC}  ${DIM}%-5s${NC}  %s\n" "#" "SKILL FOLDER" "STATUS" "FILES" "NAME / DESCRIPTION"
echo -e "  ${DIM}───  ────────────────────────────  ──────  ─────  ──────────────────────────────────────────${NC}"

for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue

    SKILL_FOLDER=$(basename "$skill_dir")
    TOTAL=$((TOTAL+1))

    FILE_COUNT=$(find "$skill_dir" -type f | wc -l | tr -d ' ')

    if [ -f "$skill_dir/SKILL.md" ]; then
        STATUS="${GREEN}  OK  ${NC}"
        VALID=$((VALID+1))

        SKILL_NAME=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | grep -i "^name:" | head -1 | sed 's/^name: *//' | tr -d '"')
        SKILL_DESC=$(sed -n '/^---$/,/^---$/p' "$skill_dir/SKILL.md" | grep -i "^description:" | head -1 | sed 's/^description: *//' | tr -d '"' | cut -c1-50)

        if [ -n "$SKILL_NAME" ]; then
            DISPLAY="$SKILL_NAME"
            if [ -n "$SKILL_DESC" ]; then
                DISPLAY="$SKILL_NAME ${DIM}— ${SKILL_DESC}${NC}"
            fi
        else
            DISPLAY="${YELLOW}(no name in frontmatter)${NC}"
        fi
    else
        STATUS="${RED} MISS ${NC}"
        INVALID=$((INVALID+1))
        DISPLAY="${RED}SKILL.md missing${NC}"
    fi

    printf "  ${DIM}%-3s${NC}  %-28s  %b  ${DIM}%5s${NC}  %b\n" "$TOTAL" "$SKILL_FOLDER" "$STATUS" "$FILE_COUNT" "$DISPLAY"
done

echo ""
echo -e "  ${DIM}───────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "  Total: ${CYAN}$TOTAL${NC} skills  |  ${GREEN}$VALID valid${NC}  |  ${RED}$INVALID missing SKILL.md${NC}"
echo ""

# Symlink status
WORKSPACE_SKILLS="$REPO_DIR/openclaw_data/.openclaw/workspace/skills"
if [ -L "$WORKSPACE_SKILLS" ]; then
    LINK_TARGET=$(readlink "$WORKSPACE_SKILLS")
    if [ "$LINK_TARGET" = "$SKILLS_DIR" ]; then
        echo -e "  ${GREEN}✓${NC} Workspace symlink: ${DIM}$WORKSPACE_SKILLS → $SKILLS_DIR${NC}"
    else
        echo -e "  ${YELLOW}⚠${NC} Workspace symlink points to: ${DIM}$LINK_TARGET${NC} (expected: $SKILLS_DIR)"
    fi
elif [ -d "$WORKSPACE_SKILLS" ]; then
    echo -e "  ${YELLOW}⚠${NC} Workspace skills is a directory (not symlink). Skills may not sync."
else
    echo -e "  ${RED}✗${NC} Workspace symlink missing. Run: ln -sfn '$SKILLS_DIR' '$WORKSPACE_SKILLS'"
fi
echo ""

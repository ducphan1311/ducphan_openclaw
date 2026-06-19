#!/bin/bash
# validate_skill.sh — Validate an OpenClaw skill before deployment
#
# Usage:
#   ./scripts/validate_skill.sh <skill-name>
#   ./scripts/validate_skill.sh taste-skill
#   ./scripts/validate_skill.sh          # Validate all skills

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
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

check_pass() { echo -e "  ${GREEN}✓ PASS${NC}  $1"; PASS=$((PASS+1)); }
check_warn() { echo -e "  ${YELLOW}⚠ WARN${NC}  $1"; WARN=$((WARN+1)); }
check_fail() { echo -e "  ${RED}✗ FAIL${NC}  $1"; FAIL=$((FAIL+1)); }

validate_skill() {
    local SKILL_NAME="$1"
    local SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Validating: ${BLUE}$SKILL_NAME${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # 1. Folder exists
    if [ -d "$SKILL_DIR" ]; then
        check_pass "Folder exists: skills/$SKILL_NAME/"
    else
        check_fail "Folder not found: skills/$SKILL_NAME/"
        return
    fi

    # 2. SKILL.md exists
    if [ -f "$SKILL_DIR/SKILL.md" ]; then
        check_pass "SKILL.md exists"
    else
        check_fail "SKILL.md missing — OpenClaw will not load this skill"

        # Search for nested SKILL.md
        NESTED=$(find "$SKILL_DIR" -name "SKILL.md" -type f 2>/dev/null | head -1)
        if [ -n "$NESTED" ]; then
            check_warn "Found SKILL.md at: ${NESTED#$SKILLS_DIR/}"
            echo "         → Run: cp '$NESTED' '$SKILL_DIR/SKILL.md'"
        fi
        return
    fi

    # 3. YAML frontmatter
    FIRST_LINE=$(head -1 "$SKILL_DIR/SKILL.md")
    if [ "$FIRST_LINE" = "---" ]; then
        check_pass "YAML frontmatter detected"
    else
        check_fail "No YAML frontmatter (first line should be '---')"
        return
    fi

    # 4. Name field
    SKILL_DEFINED_NAME=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | grep -i "^name:" | head -1 | sed 's/^name: *//')
    if [ -n "$SKILL_DEFINED_NAME" ]; then
        check_pass "name: $SKILL_DEFINED_NAME"
    else
        check_fail "Missing 'name:' in frontmatter"
    fi

    # 5. Description field
    SKILL_DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | grep -i "^description:" | head -1 | sed 's/^description: *//')
    if [ -n "$SKILL_DESC" ]; then
        DESC_LEN=${#SKILL_DESC}
        if [ "$DESC_LEN" -lt 10 ]; then
            check_warn "description is very short ($DESC_LEN chars): $SKILL_DESC"
        else
            check_pass "description: $(echo "$SKILL_DESC" | cut -c1-60)..."
        fi
    else
        check_fail "Missing 'description:' in frontmatter"
    fi

    # 6. Closing frontmatter delimiter
    CLOSING_DELIM=$(sed -n '2,/^---$/p' "$SKILL_DIR/SKILL.md" | tail -1)
    if [ "$CLOSING_DELIM" = "---" ]; then
        check_pass "Frontmatter properly closed"
    else
        check_fail "Frontmatter not closed (missing second '---')"
    fi

    # 7. Body content (after frontmatter)
    BODY_LINES=$(awk '/^---$/{c++;next} c>=2' "$SKILL_DIR/SKILL.md" | grep -c '[^ ]' 2>/dev/null || echo "0")
    if [ "$BODY_LINES" -gt 0 ]; then
        check_pass "Body content: $BODY_LINES non-empty lines"
    else
        check_warn "No body content after frontmatter"
    fi

    # 8. No nested .git (avoid submodule issues)
    if [ -d "$SKILL_DIR/.git" ]; then
        check_warn "Contains .git directory (nested repo). Consider removing."
    else
        check_pass "No nested .git directory"
    fi

    # 9. Check for README
    if [ -f "$SKILL_DIR/README.md" ]; then
        check_pass "README.md present"
    else
        check_warn "No README.md (optional but recommended)"
    fi

    # 10. File count
    FILE_COUNT=$(find "$SKILL_DIR" -type f | wc -l | tr -d ' ')
    DIR_COUNT=$(find "$SKILL_DIR" -type d | wc -l | tr -d ' ')
    check_pass "Structure: $FILE_COUNT files in $DIR_COUNT directories"

    # 11. Check file size of SKILL.md
    SKILL_SIZE=$(wc -c < "$SKILL_DIR/SKILL.md" | tr -d ' ')
    if [ "$SKILL_SIZE" -gt 50000 ]; then
        check_warn "SKILL.md is large (${SKILL_SIZE} bytes). May hit context limits."
    elif [ "$SKILL_SIZE" -lt 50 ]; then
        check_warn "SKILL.md is very small (${SKILL_SIZE} bytes). Might lack detail."
    else
        check_pass "SKILL.md size: ${SKILL_SIZE} bytes"
    fi

    # 12. Check if tools are declared
    TOOLS=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | grep -i "^tools:" | head -1)
    if [ -n "$TOOLS" ]; then
        check_pass "Tools declaration found"
    else
        check_warn "No 'tools:' in frontmatter (optional — will use all available tools)"
    fi
}

# === Main ===
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      OpenClaw Skill Validator              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"

if [ -n "$1" ]; then
    # Validate specific skill
    validate_skill "$1"
else
    # Validate all skills
    echo -e "\n${BLUE}Validating all skills in skills/...${NC}"
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ]; then
            SKILL_NAME=$(basename "$skill_dir")
            validate_skill "$SKILL_NAME"
        fi
    done
fi

# Summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Summary: ${GREEN}$PASS passed${NC}, ${YELLOW}$WARN warnings${NC}, ${RED}$FAIL failed${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

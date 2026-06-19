#!/bin/bash
# add_skill.sh — Add a new skill from a GitHub repository
#
# Usage:
#   ./scripts/add_skill.sh <github-url> [skill-folder-name]
#
# Examples:
#   ./scripts/add_skill.sh https://github.com/Leonxlnx/taste-skill
#   ./scripts/add_skill.sh https://github.com/Leonxlnx/taste-skill taste-skill
#   ./scripts/add_skill.sh https://github.com/user/my-skill my-custom-skill

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
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      OpenClaw Skill Installer              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}  ✓${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}  ⚠${NC} $1"
}

print_error() {
    echo -e "${RED}  ✗${NC} $1"
}

# === Validate arguments ===
if [ -z "$1" ]; then
    echo -e "${RED}Usage:${NC} ./scripts/add_skill.sh <github-url> [skill-folder-name]"
    echo ""
    echo "Examples:"
    echo "  ./scripts/add_skill.sh https://github.com/Leonxlnx/taste-skill"
    echo "  ./scripts/add_skill.sh https://github.com/user/my-skill my-custom-name"
    exit 1
fi

GITHUB_URL="$1"

# Strip trailing .git or query params / fragments from URL
CLEAN_URL=$(echo "$GITHUB_URL" | sed 's/\.git$//' | sed 's/[?#].*//')

# Derive folder name from URL if not given
if [ -n "$2" ]; then
    SKILL_NAME="$2"
else
    SKILL_NAME=$(basename "$CLEAN_URL")
fi

SKILL_DIR="$SKILLS_DIR/$SKILL_NAME"

print_header

# === Step 1: Check if skill already exists ===
print_step 1 "Checking for existing skill..."

if [ -d "$SKILL_DIR" ]; then
    print_warn "Skill folder '$SKILL_NAME' already exists at $SKILL_DIR"
    echo -n "  Overwrite? (y/N): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "  Aborted."
        exit 0
    fi
    rm -rf "$SKILL_DIR"
    print_success "Removed existing skill folder."
fi

# === Step 2: Clone the repo ===
print_step 2 "Cloning $CLEAN_URL → skills/$SKILL_NAME ..."

if git clone --depth 1 "$CLEAN_URL" "$SKILL_DIR" 2>/dev/null; then
    print_success "Cloned successfully."
else
    # Try with .git suffix
    if git clone --depth 1 "${CLEAN_URL}.git" "$SKILL_DIR" 2>/dev/null; then
        print_success "Cloned successfully (with .git suffix)."
    else
        print_error "Failed to clone. Check the URL and your network."
        exit 1
    fi
fi

# Remove .git directory to avoid nested git repos
rm -rf "$SKILL_DIR/.git"
print_success "Removed .git directory (avoids nested repos)."

# === Step 3: Locate SKILL.md ===
print_step 3 "Locating SKILL.md..."

if [ -f "$SKILL_DIR/SKILL.md" ]; then
    print_success "Found SKILL.md at root level."
else
    # Search for SKILL.md in subdirectories (common pattern: skills/<name>/SKILL.md)
    FOUND_SKILL=$(find "$SKILL_DIR" -name "SKILL.md" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND_SKILL" ]; then
        print_warn "SKILL.md found at: ${FOUND_SKILL#$SKILL_DIR/}"
        cp "$FOUND_SKILL" "$SKILL_DIR/SKILL.md"
        print_success "Copied SKILL.md to root level."
    else
        print_warn "No SKILL.md found. This skill might use a different structure."
        echo ""
        echo "  You may need to create SKILL.md manually. Template:"
        echo ""
        echo '  ---'
        echo "  name: $SKILL_NAME"
        echo '  description: Short description of what the skill does.'
        echo '  ---'
        echo ''
        echo '  # Skill Name'
        echo ''
        echo '  Instructions for the agent...'
        echo ""
        echo "  Save as: $SKILL_DIR/SKILL.md"
    fi
fi

# === Step 4: Validate the skill ===
print_step 4 "Validating skill structure..."

if [ -f "$SKILL_DIR/SKILL.md" ]; then
    # Check for frontmatter
    FIRST_LINE=$(head -1 "$SKILL_DIR/SKILL.md")
    if [ "$FIRST_LINE" = "---" ]; then
        # Extract name and description
        SKILL_DEFINED_NAME=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | grep -i "^name:" | head -1 | sed 's/^name: *//')
        SKILL_DESC=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | grep -i "^description:" | head -1 | sed 's/^description: *//' | cut -c1-80)

        if [ -n "$SKILL_DEFINED_NAME" ]; then
            print_success "Name: $SKILL_DEFINED_NAME"
        else
            print_warn "No 'name' field in frontmatter."
        fi

        if [ -n "$SKILL_DESC" ]; then
            print_success "Description: ${SKILL_DESC}..."
        else
            print_warn "No 'description' field in frontmatter."
        fi
    else
        print_warn "SKILL.md doesn't start with YAML frontmatter (---). OpenClaw may not detect this skill."
    fi

    # Count files
    FILE_COUNT=$(find "$SKILL_DIR" -type f | wc -l | tr -d ' ')
    print_success "Total files: $FILE_COUNT"
else
    print_error "SKILL.md still missing. Skill will not be loaded by OpenClaw."
fi

# === Step 5: Reminder checklist ===
print_step 5 "Post-install checklist"

echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo "  ┌───────────────────────────────────────────────────────┐"
echo "  │ □ Check if skill needs external API access             │"
echo "  │   → Add domains to config/policies.yaml                │"
echo "  │ □ Check if skill needs API keys/env vars               │"
echo "  │   → Add to .env + Vault + start_native.sh              │"
echo "  │ □ Check if skill needs Commander orchestration          │"
echo "  │   → Create agents/workers/<name>-worker.md              │"
echo "  │   → Update skills/commander/SKILL.md routing            │"
echo "  │ □ Restart gateway to load the new skill                 │"
echo "  │   → screen -S openclaw-gateway -X quit                  │"
echo "  │   → sleep 2                                             │"
echo "  │   → screen -dmS openclaw-gateway \\                      │"
echo "  │       bash -lc './start_native.sh > openclaw_data/...   │"
echo "  │ □ Test skill via Telegram                               │"
echo "  └───────────────────────────────────────────────────────┘"
echo ""

# === Step 6: Offer to validate ===
echo -n -e "  ${YELLOW}Run full validation now? (Y/n):${NC} "
read -r RUN_VALIDATE
if [ "$RUN_VALIDATE" != "n" ] && [ "$RUN_VALIDATE" != "N" ]; then
    if [ -x "$SCRIPT_DIR/validate_skill.sh" ]; then
        "$SCRIPT_DIR/validate_skill.sh" "$SKILL_NAME"
    else
        echo "  validate_skill.sh not found or not executable."
    fi
fi

echo ""
echo -e "${GREEN}Done!${NC} Skill '$SKILL_NAME' installed at skills/$SKILL_NAME/"
echo ""

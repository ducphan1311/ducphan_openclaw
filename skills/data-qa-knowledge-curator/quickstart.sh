#!/bin/bash
# Quick Start Script for Data QA Knowledge Curator

set -e

SKILL_DIR="$HOME/.openclaw/workspace/skills/data-qa-knowledge-curator"
SCRIPT_DIR="$SKILL_DIR/scripts"

echo "=========================================="
echo "Data QA Knowledge Curator - Quick Start"
echo "=========================================="
echo ""

# Check if skill directory exists
if [ ! -d "$SKILL_DIR" ]; then
    echo "❌ Skill directory not found: $SKILL_DIR"
    echo "Please ensure the skill is installed correctly."
    exit 1
fi

cd "$SKILL_DIR"

# Step 1: Check Python
echo "Step 1: Checking Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3."
    exit 1
fi
echo "✅ Python 3 found: $(python3 --version)"
echo ""

# Step 2: Install dependencies
echo "Step 2: Installing dependencies..."
if [ -f "requirements.txt" ]; then
    pip3 install -q -r requirements.txt
    echo "✅ Dependencies installed"
else
    echo "⚠️  requirements.txt not found"
fi
echo ""

# Step 3: Check Vault
echo "Step 3: Checking Vault..."
if ! command -v vault &> /dev/null; then
    echo "⚠️  Vault CLI not found"
    echo "   Install from: https://www.vaultproject.io/downloads"
    echo "   Or continue without Vault (will fail when running crawlers)"
else
    if vault token lookup &> /dev/null; then
        echo "✅ Vault is authenticated"
    else
        echo "⚠️  Vault not authenticated"
        echo "   Run: vault login"
    fi
fi
echo ""

# Step 4: Run setup test
echo "Step 4: Running setup test..."
echo ""
python3 "$SCRIPT_DIR/test_setup.py"
echo ""

# Step 5: Instructions
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "If all tests passed, you can:"
echo ""
echo "1. Test individual crawlers:"
echo "   cd $SKILL_DIR"
echo "   python3 scripts/crawl_reddit.py"
echo "   python3 scripts/crawl_twitter.py"
echo "   python3 scripts/crawl_github.py"
echo ""
echo "2. Run daily crawl:"
echo "   python3 scripts/daily_crawl.py"
echo ""
echo "3. Schedule daily digest (7:00 AM):"
echo "   openclaw cron add \\"
echo "     --name 'Data QA Daily Digest' \\"
echo "     --schedule '0 7 * * *' \\"
echo "     --timezone 'Asia/Saigon' \\"
echo "     --command 'cd $SKILL_DIR && python3 scripts/daily_crawl.py'"
echo ""
echo "For detailed setup instructions, see:"
echo "  - SETUP_GUIDE.md (Vietnamese)"
echo "  - README.md (English)"
echo "  - VAULT_SETUP_GUIDE.md (in workspace root)"
echo ""

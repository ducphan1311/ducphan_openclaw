# Data QA Knowledge Curator - Setup Instructions

## Quick Start

### 1. Install Dependencies

```bash
cd ~/.openclaw/workspace/skills/data-qa-knowledge-curator
pip install -r requirements.txt
```

### 2. Setup Vault Secrets

Follow the `VAULT_SETUP_GUIDE.md` in the workspace root to configure:

- Reddit API credentials
- Twitter/X Bearer Token
- GitHub Personal Access Token
- OpenAI API key (optional, for summarization)

### 3. Test Vault Connection

```bash
python scripts/vault_helper.py
```

Expected output:
```
✓ Vault is available and authenticated
✓ Reddit credentials found: ['client_id', 'client_secret', 'user_agent']
✓ Twitter credentials found: ['bearer_token']
✓ GitHub credentials found: ['token']
```

### 4. Test Individual Crawlers

```bash
# Test Reddit crawler
python scripts/crawl_reddit.py

# Test Twitter crawler
python scripts/crawl_twitter.py

# Test GitHub crawler
python scripts/crawl_github.py
```

### 5. Run Daily Crawl

```bash
python scripts/daily_crawl.py
```

This will:
1. Crawl all enabled sources
2. Filter and score content
3. Categorize items
4. Generate digest
5. Save to knowledge base

### 6. Schedule Daily Digest (Optional)

To receive automated daily digests via Telegram at 7:00 AM:

```bash
# Using OpenClaw cron
openclaw cron add \
  --name "Data QA Daily Digest" \
  --schedule "0 7 * * *" \
  --timezone "Asia/Saigon" \
  --command "cd ~/.openclaw/workspace/skills/data-qa-knowledge-curator && python scripts/daily_crawl.py"
```

Or manually via system cron:

```bash
# Edit crontab
crontab -e

# Add line (runs at 7:00 AM daily)
0 7 * * * cd ~/.openclaw/workspace/skills/data-qa-knowledge-curator && python scripts/daily_crawl.py
```

## Configuration

Edit `references/config.json` to customize:

- **Sources**: Which subreddits, hashtags, GitHub topics to track
- **Keywords**: Filter keywords in `references/keywords.json`
- **Relevance threshold**: Minimum score for inclusion
- **Digest format**: Max items per category
- **Delivery time**: When to send digest

## Troubleshooting

### "vault: command not found"
Install Vault CLI: https://www.vaultproject.io/downloads

### "permission denied" from Vault
Login to Vault: `vault login`

### API rate limit errors
- Reduce crawl frequency
- Reduce number of sources in config
- Check API quotas

### No items in digest
- Lower `min_score` in `references/config.json`
- Check that sources are enabled
- Verify API credentials

## Files Structure

```
data-qa-knowledge-curator/
├── SKILL.md                          # Skill documentation
├── requirements.txt                  # Python dependencies
├── scripts/
│   ├── vault_helper.py              # Vault secret reader
│   ├── crawl_reddit.py              # Reddit crawler
│   ├── crawl_twitter.py             # Twitter crawler
│   ├── crawl_github.py              # GitHub crawler
│   └── daily_crawl.py               # Main orchestrator
├── references/
│   ├── config.json                  # Configuration
│   └── keywords.json                # Filter keywords
└── assets/
    └── (empty for now)
```

## Next Steps

After testing the skill:

1. Adjust `references/config.json` to your preferences
2. Add/remove sources (subreddits, hashtags, topics)
3. Tune relevance scoring thresholds
4. Schedule daily cron job
5. Integrate with Telegram delivery (via OpenClaw messaging)

## Related Skills

- `ai-prompt-library` - Prompt engineering collection (coming soon)
- `tech-trend-monitor` - General tech trend tracking (coming soon)

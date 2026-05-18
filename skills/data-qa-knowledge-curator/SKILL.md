---
name: data-qa-knowledge-curator
description: Automatically aggregates and curates Data QA knowledge from multiple sources (Reddit, Twitter/X, GitHub, blogs, Stack Overflow). Delivers daily digests of new best practices, tools, case studies, and learning resources. Use when the user asks for Data QA updates, latest trends, new tools, best practices, or wants automated knowledge delivery via Telegram.
---

# Data QA Knowledge Curator

Automatically crawls, filters, summarizes, and delivers Data QA knowledge from multiple sources.

## What This Skill Does

- **Crawls** Reddit, Twitter/X, GitHub, blogs, Stack Overflow for Data QA content
- **Filters** by relevance (data quality, validation, testing, QA automation)
- **Summarizes** using AI to extract key insights
- **Categorizes** content (tools, best practices, case studies, tutorials)
- **Delivers** daily digest via Telegram at scheduled time

## Quick Start

### 1. Setup API Keys in Vault

Follow `VAULT_SETUP_GUIDE.md` to configure:
- Reddit API credentials
- Twitter/X Bearer Token
- GitHub Personal Access Token
- OpenAI API key (or use existing 9Router)

### 2. Run Daily Crawl

```bash
python scripts/daily_crawl.py
```

This will:
1. Crawl all configured sources
2. Filter and score content by relevance
3. Summarize top items
4. Generate digest
5. Send to Telegram (if configured)

### 3. Schedule via Cron

Add to OpenClaw cron (runs daily at 7:00 AM Asia/Saigon):

```bash
openclaw cron add \
  --name "Data QA Daily Digest" \
  --schedule "0 7 * * *" \
  --timezone "Asia/Saigon" \
  --command "cd ~/.openclaw/workspace/skills/data-qa-knowledge-curator && python scripts/daily_crawl.py"
```

## On-Demand Commands

### Search Knowledge Base

```bash
python scripts/search_knowledge.py "data validation best practices"
```

### Get Specific Source

```bash
# Reddit only
python scripts/crawl_reddit.py --subreddits dataengineering,dataquality

# Twitter only
python scripts/crawl_twitter.py --hashtags DataQuality,DataEngineering

# GitHub trending
python scripts/crawl_github.py --topics data-quality,data-testing
```

### Manual Digest Generation

```bash
python scripts/generate_digest.py --date 2026-05-15
```

## Configuration

Edit `references/config.json` to customize:

- **Sources**: Which subreddits, Twitter accounts, GitHub topics to track
- **Keywords**: Filter keywords and relevance scoring
- **Digest format**: What sections to include
- **Delivery time**: When to send digest
- **Content limits**: Max items per category

## Content Sources

### Reddit
- r/dataengineering
- r/dataquality
- r/analytics
- r/bigquery
- r/datawarehouse
- r/ETL

### Twitter/X
- Hashtags: #DataQuality, #DataEngineering, #DataTesting
- Accounts: Data QA influencers (configurable)

### GitHub
- Topics: data-quality, data-validation, data-testing
- Trending repos
- New releases

### Blogs (RSS)
- dbt blog
- Great Expectations blog
- Airflow blog
- Data engineering blogs

### Stack Overflow
- Tags: data-quality, data-validation, etl, data-testing

## Digest Format

Daily digest includes:

```
📚 Data QA Knowledge Digest - May 15, 2026

🔥 Trending Today (3 items):
- [Reddit] New dbt 2.0 features for data testing
- [GitHub] awesome-data-quality repo hit 5k stars
- [Twitter] Thread on data validation at scale

💡 Best Practice (1 item):
- How Netflix validates data at scale (case study)

🛠️ New Tool (1 item):
- DataFold: Automated data diff tool

📖 Learning Resource (1 item):
- Great Expectations tutorial series (YouTube)

🐛 Common Issue (1 item):
- [SO] Handling timezone in data validation

📊 Stats:
- 47 items crawled, 7 selected
- Sources: Reddit (3), Twitter (2), GitHub (1), Blog (1)
```

## Relevance Scoring

Content is scored based on:
- **Keyword match** (data quality, validation, testing, QA)
- **Engagement** (upvotes, likes, stars)
- **Recency** (newer = higher score)
- **Source credibility** (known experts, official blogs)
- **Content type** (tutorial > discussion > announcement)

Threshold: Only items scoring >70/100 are included.

## Rate Limits

Scripts respect API rate limits:
- Reddit: 60 req/min (OAuth)
- Twitter: 500k tweets/month
- GitHub: 5k req/hour
- OpenAI: Per your plan

All scripts include rate limiting and retry logic.

## Troubleshooting

### No content in digest
- Check API keys in Vault
- Verify sources are configured in `references/config.json`
- Lower relevance threshold in config

### API rate limit errors
- Reduce crawl frequency
- Reduce number of sources
- Check API quotas

### Summarization fails
- Verify OpenAI API key
- Check token limits
- Fallback to raw content (no summary)

## Advanced Usage

### Add Custom Source

Edit `references/config.json`:

```json
{
  "sources": {
    "reddit": {
      "subreddits": ["dataengineering", "yourcustomsub"]
    }
  }
}
```

### Custom Keywords

Edit `references/keywords.json`:

```json
{
  "high_priority": ["data quality", "data validation"],
  "medium_priority": ["data testing", "QA automation"],
  "exclude": ["job posting", "hiring"]
}
```

### Export Knowledge Base

```bash
python scripts/export_knowledge.py --format markdown --output knowledge_base.md
```

## Files

- `scripts/daily_crawl.py` - Main orchestrator
- `scripts/crawl_reddit.py` - Reddit crawler
- `scripts/crawl_twitter.py` - Twitter crawler
- `scripts/crawl_github.py` - GitHub crawler
- `scripts/crawl_blogs.py` - RSS blog crawler
- `scripts/crawl_stackoverflow.py` - Stack Overflow crawler
- `scripts/summarize_content.py` - AI summarization
- `scripts/generate_digest.py` - Digest generator
- `scripts/send_telegram.py` - Telegram delivery
- `scripts/search_knowledge.py` - Search engine
- `scripts/vault_helper.py` - Vault secret reader
- `references/config.json` - Configuration
- `references/keywords.json` - Filter keywords
- `references/sources.json` - Source catalog
- `assets/digest-template.md` - Digest template

## Related Skills

- `ai-prompt-library` - Prompt engineering collection
- `tech-trend-monitor` - General tech trend tracking
- `english_learning_planner` - Learning path builder

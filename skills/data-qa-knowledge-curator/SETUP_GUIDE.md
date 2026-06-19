# Data QA Knowledge Curator - Complete Setup Guide

## 📋 Overview

Skill này tự động thu thập và tổng hợp kiến thức Data QA từ nhiều nguồn:
- Reddit (r/dataengineering, r/dataquality, etc.)
- Twitter/X (#DataQuality, #DataEngineering, etc.)
- GitHub (trending repos, releases)
- Blogs (dbt, Great Expectations, Airflow)

Mỗi ngày, skill sẽ:
1. Crawl các nguồn đã cấu hình
2. Filter theo keywords và relevance score
3. Categorize content (trending, best practices, tools, etc.)
4. Generate digest và gửi qua Telegram

## 🚀 Setup Steps

### Step 1: Install Dependencies

```bash
cd ~/.openclaw/workspace/skills/data-qa-knowledge-curator
pip install -r requirements.txt
```

### Step 2: Setup API Keys

#### 2.1 Reddit API

1. Truy cập: https://www.reddit.com/prefs/apps
2. Click "Create App" hoặc "Create Another App"
3. Chọn type: **script**
4. Điền thông tin:
   - Name: `Data QA Curator`
   - Redirect URI: `http://localhost:8080`
5. Copy `client_id` (dưới app name) và `client_secret`

**Lưu vào Vault:**
```bash
vault kv put secret/data-qa-curator/reddit \
  client_id="YOUR_CLIENT_ID" \
  client_secret="YOUR_CLIENT_SECRET" \
  user_agent="DataQACurator/1.0"
```

#### 2.2 Twitter/X API

1. Truy cập: https://developer.twitter.com/en/portal/dashboard
2. Create project/app (hoặc dùng existing)
3. Vào tab "Keys and tokens"
4. Generate "Bearer Token"
5. Copy token (chỉ hiện 1 lần!)

**Lưu vào Vault:**
```bash
vault kv put secret/data-qa-curator/twitter \
  bearer_token="YOUR_BEARER_TOKEN"
```

**Note:** Twitter API v2 Basic tier miễn phí (500k tweets/month)

#### 2.3 GitHub API

1. Truy cập: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Chọn scopes:
   - `public_repo` (read public repositories)
   - `read:user` (optional)
4. Generate và copy token

**Lưu vào Vault:**
```bash
vault kv put secret/data-qa-curator/github \
  token="YOUR_GITHUB_TOKEN"
```

#### 2.4 OpenAI API (Optional - cho summarization)

Nếu muốn dùng AI summarization:

```bash
vault kv put secret/data-qa-curator/openai \
  api_key="YOUR_OPENAI_KEY"
```

**Alternative:** Có thể dùng existing 9Router setup thay vì OpenAI riêng.

### Step 3: Verify Setup

```bash
python scripts/test_setup.py
```

Expected output:
```
✓ PASS: Vault Connection
✓ PASS: Configuration Files
✓ PASS: Python Dependencies
✓ PASS: Reddit Credentials
✓ PASS: Twitter Credentials
✓ PASS: GitHub Credentials

✓ All tests passed! You're ready to run the crawler.
```

### Step 4: Test Individual Crawlers

```bash
# Test Reddit
python scripts/crawl_reddit.py

# Test Twitter
python scripts/crawl_twitter.py

# Test GitHub
python scripts/crawl_github.py
```

Mỗi crawler sẽ output JSON với các items tìm được.

### Step 5: Run Daily Crawl

```bash
python scripts/daily_crawl.py
```

Output sẽ là digest markdown format, ví dụ:

```
📚 Data QA Knowledge Digest - May 15, 2026

🔥 Trending Today (3 items):
- [Reddit r/dataengineering] New dbt 2.0 features for data testing
  https://reddit.com/...

💡 Best Practice (1 item):
- [GitHub] awesome-data-quality: Curated list of data quality tools
  https://github.com/...

🛠️ New Tool (1 item):
- [Twitter @dbt_labs] Announcing dbt Cloud data quality checks
  https://twitter.com/...

📊 Stats:
- 47 items crawled, 7 selected
- Sources: reddit, twitter, github
```

### Step 6: Schedule Daily Digest

Để nhận digest tự động mỗi ngày lúc 7:00 sáng qua Telegram:

```bash
# Sử dụng OpenClaw cron (recommended)
openclaw cron add \
  --name "Data QA Daily Digest" \
  --schedule "0 7 * * *" \
  --timezone "Asia/Saigon" \
  --command "cd ~/.openclaw/workspace/skills/data-qa-knowledge-curator && python scripts/daily_crawl.py"
```

## ⚙️ Configuration

### Customize Sources

Edit `references/config.json`:

```json
{
  "sources": {
    "reddit": {
      "subreddits": [
        "dataengineering",
        "dataquality",
        "your_custom_subreddit"
      ]
    },
    "twitter": {
      "hashtags": ["DataQuality", "YourHashtag"],
      "accounts": ["dbt_labs", "your_account"]
    }
  }
}
```

### Customize Keywords

Edit `references/keywords.json`:

```json
{
  "high_priority": [
    "data quality",
    "your custom keyword"
  ],
  "exclude": [
    "job posting",
    "your exclude keyword"
  ]
}
```

### Adjust Relevance Threshold

Edit `references/config.json`:

```json
{
  "relevance": {
    "min_score": 70  // Lower = more items, Higher = fewer but more relevant
  }
}
```

## 🔍 How It Works

### Relevance Scoring

Mỗi item được score từ 0-100 dựa trên:

1. **Keyword Match (0-40 points)**
   - High priority keywords: 10 points each
   - Medium priority keywords: 5 points each
   - Tool mentions: 8 points each

2. **Engagement (0-30 points)**
   - Reddit: upvote ratio + comment count
   - Twitter: likes + retweets + replies
   - GitHub: stars

3. **Recency (0-20 points)**
   - Newer content scores higher
   - Decays over time

4. **Source Credibility (0-10 points)**
   - Known good sources score higher

**Threshold:** Chỉ items có score >= 70 mới được include trong digest.

### Categorization

Content được tự động phân loại:

- **Trending**: High engagement, recent
- **Best Practice**: Patterns, strategies, approaches
- **New Tool**: Releases, announcements
- **Learning Resource**: Tutorials, guides, courses
- **Common Issue**: Q&A, troubleshooting
- **Case Study**: Real-world production examples

## 📊 Knowledge Base

Tất cả items được lưu vào local knowledge base:

```
~/.openclaw/workspace/skills/data-qa-knowledge-curator/knowledge_base.json
```

Retention: 30 days, max 1000 items (configurable)

## 🔧 Troubleshooting

### No items in digest

**Giải pháp:**
1. Lower `min_score` trong config (từ 70 → 60)
2. Add thêm sources (subreddits, hashtags)
3. Check API credentials

### API rate limit errors

**Giải pháp:**
1. Reduce crawl frequency
2. Reduce number of sources
3. Check API quotas:
   - Reddit: 60 req/min
   - Twitter Basic: 500k tweets/month
   - GitHub: 5k req/hour

### Vault errors

**Giải pháp:**
```bash
# Check Vault status
vault status

# Login if needed
vault login

# Verify secrets
vault kv get secret/data-qa-curator/reddit
```

## 📝 Next Steps

1. ✅ Setup và test skill này
2. 🔄 Tạo thêm skills:
   - `ai-prompt-library` - Prompt engineering collection
   - `tech-trend-monitor` - General tech trends
   - `mobile-dev-curator` - Flutter/React Native updates
3. 🎯 Customize theo nhu cầu của bạn
4. 📱 Integrate với Telegram delivery

## 💡 Tips

- Bắt đầu với `min_score: 70`, sau đó adjust dựa trên kết quả
- Add/remove sources dần dần để tìm sweet spot
- Review digest hàng ngày và tune keywords
- Có thể tạo multiple skills cho different topics (Mobile Dev, AI Tools, etc.)

## ❓ Questions?

Nếu cần help với bất kỳ bước nào, hãy hỏi tôi!

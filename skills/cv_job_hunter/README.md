# CV Manager & Job Hunter

Automated CV management, job search, application tracking, and interview preparation system.

---

## 🎯 Features

- **CV Version Control:** Manage multiple CV variants with change tracking
- **Automated Job Search:** Search across LinkedIn, ITviec, TopCV, VietnamWorks
- **Application Tracking:** Track status, deadlines, and follow-ups
- **Interview Prep:** Company research, question generation, STAR examples
- **Weekly Reports:** Automated summaries and reminders via Telegram

---

## 📁 Structure

```
skills/cv_job_hunter/
├── SKILL.md              # Main skill documentation
├── README.md             # This file
└── scripts/              # Helper scripts (future)
```

**Memory location:** `~/.openclaw/workspace/memory/cv_job_hunter/`

---

## 🚀 Quick Start

### 1. Setup Memory Structure

The skill will auto-create these on first use:

```
memory/cv_job_hunter/
├── tracker.json          # Central database
├── cv_versions/          # CV files
├── applications/         # Application records
├── job_searches/         # Search results
└── interview_prep/       # Interview prep docs
```

### 2. Configure Credentials

```bash
# Required for notifications
openclaw vault set TELEGRAM_BOT_TOKEN "your_bot_token"
openclaw vault set TELEGRAM_CHAT_ID "your_chat_id"

# Optional for authenticated LinkedIn search
openclaw vault set LINKEDIN_EMAIL "your_email"
openclaw vault set LINKEDIN_PASSWORD "your_password"
```

### 3. Start Using

```
"Create my CV"
"Search for Data Engineer jobs in Vietnam"
"I applied to Company A for Senior Data Engineer"
"Prepare for Company A interview"
```

---

## 📊 Commands

### CV Management
- `"Update my CV with [experience]"`
- `"Create a CV tailored for [job posting]"`
- `"Show my latest CV"`
- `"List all CV versions"`

### Job Search
- `"Search for [role] jobs in [location]"`
- `"Find remote [role] positions"`
- `"Show me jobs at [company]"`

### Application Tracking
- `"I applied to [company] for [role]"`
- `"Update [company] status to [status]"`
- `"Show all my applications"`
- `"What applications need follow-up?"`

### Interview Prep
- `"Prepare for [company] interview"`
- `"Generate interview questions for [role]"`
- `"What should I ask [company]?"`

### Reporting
- `"Show my job hunt stats"`
- `"Weekly application summary"`
- `"What's my response rate?"`

---

## 🤖 Automation

### Weekly Summary
**Schedule:** Every Monday 9:00 AM (Asia/Saigon)  
**Delivery:** Telegram notification  
**Content:** Applications, interviews, follow-ups, stats

### Follow-up Reminders
**Schedule:** Daily 10:00 AM (Asia/Saigon)  
**Trigger:** Applications with no response after 7 days  
**Delivery:** Telegram alert

### Interview Reminders
**Trigger:** Dynamically created when interview scheduled  
**Timing:** 1 day before, 1 hour before  
**Delivery:** Telegram notification

---

## 🔒 Privacy & Safety

- All data stored locally in `memory/cv_job_hunter/`
- Never shares CV/application details in group chats
- Always asks before submitting applications or sending emails
- Redacts sensitive info in examples

---

## 🛠️ Integration

### Skills Used
- **Research Agent:** Company research, web scraping
- **Communication Agent:** Follow-up emails
- **Google Workspace Agent:** Calendar integration
- **Safe Email Assistant:** Monitor application responses

### Tools Used
- `web_search`: Job board searches
- `browser`: LinkedIn, ITviec scraping
- `cron`: Automated reminders
- `read/write`: File management

---

## 📈 Workflow Example

```
User: "Search for Data Engineer jobs in HCMC"
  ↓
Agent searches LinkedIn, ITviec, TopCV
  ↓
Presents top 10 matches with relevance scores
  ↓
User: "I applied to Company A"
  ↓
Agent creates application record, sets 7-day follow-up
  ↓
[7 days later, no response]
  ↓
Agent sends Telegram reminder: "Follow up with Company A?"
  ↓
User: "Company A scheduled interview for June 1"
  ↓
Agent creates interview prep doc, researches company, sets reminders
  ↓
[1 day before interview]
  ↓
Agent sends Telegram: "Interview tomorrow with Company A. Review prep doc?"
```

---

## 📝 Tracker Schema

```json
{
  "cv_versions": [...],
  "applications": [
    {
      "id": "2026-05-19-company-a",
      "company": "Company A",
      "position": "Senior Data Engineer",
      "applied_date": "2026-05-19",
      "status": "interview_scheduled",
      "cv_version": "cv_data_engineer_v2",
      "salary_range": "$2000-3000",
      "location": "HCMC",
      "timeline": [...]
    }
  ],
  "stats": {
    "total_applications": 23,
    "by_status": {...},
    "response_rate": 35,
    "interview_rate": 17,
    "offer_rate": 4
  },
  "preferences": {
    "target_roles": ["Data Engineer", "Backend Engineer"],
    "locations": ["HCMC", "Hanoi", "Remote"],
    "salary_min": 1500,
    "salary_max": 3500
  }
}
```

---

## 🐛 Troubleshooting

**"No jobs found"**
- Check preferences in `tracker.json`
- Try broader search terms
- Verify job sites are accessible

**"Can't access LinkedIn"**
- Verify credentials in vault
- Try browser-based search
- Check for rate limiting

**"Tracker corrupted"**
- Restore from backup
- Recreate from application files

---

## 📚 Related Documentation

- [SKILL.md](./SKILL.md) - Full skill documentation
- [Communication Agent](../communication/SKILL.md)
- [Research Agent](../research/SKILL.md)
- [Safe Email Assistant](../email_assistant/SKILL.md)

---

**Version:** 1.0  
**Created:** 2026-05-19  
**Author:** Claw  
**Status:** Active

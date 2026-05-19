# CV Manager & Job Hunter Skill

**Purpose:** Manage CV versions, track job applications, automate job searches, and monitor application status.

**Invoke when:** User asks to update CV, search for jobs, track applications, prepare for interviews, or manage job hunting workflow.

---

## Core Capabilities

1. **CV Management**
   - Store and version multiple CV variants (general, tech-focused, data-focused, etc.)
   - Generate tailored CVs for specific job postings
   - Track CV versions and which was sent where

2. **Job Search Automation**
   - Search LinkedIn, Indeed, Glassdoor, VietnamWorks, TopCV, ITviec
   - Filter by keywords, location, salary, experience level
   - Save interesting positions with metadata

3. **Application Tracking**
   - Log applications with status (applied, screening, interview, offer, rejected)
   - Track deadlines, interview dates, follow-ups
   - Generate weekly application summaries

4. **Interview Preparation**
   - Research company background
   - Prepare common interview questions for role
   - Track interview feedback and learnings

---

## File Structure

```
memory/cv_job_hunter/
├── cv_versions/
│   ├── cv_general_v1.md
│   ├── cv_data_engineer_v2.md
│   └── cv_backend_dev_v1.md
├── applications/
│   ├── 2026-05-company-name.md
│   └── ...
├── job_searches/
│   ├── 2026-05-19-search.md
│   └── ...
├── interview_prep/
│   ├── company-name-prep.md
│   └── ...
└── tracker.json
```

---

## Workflow

### 1. CV Update Request

**User says:** "Update my CV with new project experience"

**Actions:**
1. Read latest CV version from `memory/cv_job_hunter/cv_versions/`
2. Ask user for new experience details
3. Generate updated CV with incremented version
4. Save as new version file
5. Update `tracker.json` with version metadata

**Output:**
```markdown
✅ CV updated: cv_general_v3.md

**Changes:**
- Added: Project X (Data Pipeline Automation)
- Updated: Skills section (added Apache Airflow)
- Refined: Summary statement

**File:** memory/cv_job_hunter/cv_versions/cv_general_v3.md
```

---

### 2. Job Search

**User says:** "Search for Data Engineer jobs in Vietnam, remote OK, 3-5 years experience"

**Actions:**
1. Use `web_search` and `browser` to search:
   - LinkedIn Jobs
   - ITviec
   - TopCV
   - VietnamWorks
2. Filter by criteria
3. Extract: title, company, location, salary range, requirements, link
4. Save results to `memory/cv_job_hunter/job_searches/YYYY-MM-DD-search.md`
5. Present top 10 matches with relevance score

**Output:**
```markdown
🔍 Found 47 Data Engineer positions

**Top Matches:**

1. **Senior Data Engineer - Company A** (95% match)
   - Location: HCMC (Remote OK)
   - Salary: $2000-3000
   - Requirements: Python, Airflow, AWS, 3+ years
   - Link: [Apply](https://...)
   - Why match: All required skills, salary range fits

2. **Data Engineer - Company B** (88% match)
   ...

**Saved to:** memory/cv_job_hunter/job_searches/2026-05-19-search.md
```

---

### 3. Application Tracking

**User says:** "I applied to Company A for Senior Data Engineer role"

**Actions:**
1. Create application record: `memory/cv_job_hunter/applications/2026-05-19-company-a.md`
2. Update `tracker.json` with application entry
3. Set up follow-up reminder (7 days if no response)

**Application file template:**
```markdown
# Company A - Senior Data Engineer

**Applied:** 2026-05-19
**Status:** Applied
**CV Version:** cv_data_engineer_v2.md

## Job Details
- **Link:** https://...
- **Salary:** $2000-3000
- **Location:** HCMC (Remote)
- **Requirements:** Python, Airflow, AWS, 3+ years

## Timeline
- 2026-05-19: Application submitted
- 2026-05-26: Follow-up reminder

## Notes
- Strong match on technical skills
- Company culture seems good from Glassdoor reviews
- Referral: None

## Interview Prep
- [ ] Research company background
- [ ] Prepare project examples
- [ ] Review Airflow architecture questions
```

---

### 4. Status Update

**User says:** "Company A scheduled interview for May 25"

**Actions:**
1. Update application status to "Interview Scheduled"
2. Add timeline entry
3. Create interview prep file
4. Set reminder 1 day before interview

---

### 5. Interview Preparation

**User says:** "Prepare for Company A interview"

**Actions:**
1. Research company:
   - Web search for company info, recent news, tech stack
   - Check Glassdoor reviews
   - Find interview experiences on Reddit/Blind
2. Generate common questions for role
3. Prepare STAR method examples from CV
4. Create prep document

**Output:**
```markdown
📋 Interview Prep: Company A - Senior Data Engineer

## Company Background
- Founded: 2020
- Industry: Fintech
- Size: 50-100 employees
- Tech Stack: Python, AWS, Airflow, PostgreSQL, Kafka
- Recent News: Series A funding $5M (March 2026)

## Common Interview Questions

**Technical:**
1. Explain your experience with Apache Airflow
2. How do you handle data pipeline failures?
3. Design a real-time data processing system
4. SQL optimization techniques

**Behavioral:**
1. Tell me about a challenging data project
2. How do you handle conflicting priorities?
3. Describe a time you improved system performance

## Your STAR Examples
- **Project X:** Automated data pipeline reducing manual work by 80%
- **Challenge:** Debugged complex Airflow DAG dependency issue
- **Leadership:** Mentored junior engineer on best practices

## Questions to Ask Them
- What does the data infrastructure look like?
- How is the data team structured?
- What are the biggest data challenges right now?
- What does success look like in the first 90 days?

**Saved to:** memory/cv_job_hunter/interview_prep/company-a-prep.md
```

---

### 6. Weekly Summary

**Automated (every Monday 9am):**

**Actions:**
1. Read `tracker.json`
2. Generate summary of:
   - Applications sent this week
   - Interviews scheduled
   - Offers received
   - Rejections
   - Pending follow-ups
3. Send via Telegram

**Output:**
```markdown
📊 Job Hunt Weekly Summary (May 12-18, 2026)

**Applications:** 5 sent
- Company A (Senior Data Engineer) - Interview scheduled
- Company B (Data Engineer) - Awaiting response
- Company C (Backend Engineer) - Rejected
- Company D (Data Analyst) - Awaiting response
- Company E (ML Engineer) - Awaiting response

**Interviews:** 1 scheduled
- Company A: May 25, 10:00 AM

**Follow-ups Needed:**
- Company B (applied May 12, no response)
- Company D (applied May 14, no response)

**Stats:**
- Total applications: 23
- Response rate: 35%
- Interview rate: 17%
- Offer rate: 4%
```

---

## Tracker Schema

**File:** `memory/cv_job_hunter/tracker.json`

```json
{
  "cv_versions": [
    {
      "version": "cv_general_v3",
      "created": "2026-05-19",
      "path": "memory/cv_job_hunter/cv_versions/cv_general_v3.md",
      "changes": "Added Project X, updated skills"
    }
  ],
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
      "link": "https://...",
      "timeline": [
        {"date": "2026-05-19", "event": "Applied"},
        {"date": "2026-05-22", "event": "Interview scheduled for May 25"}
      ],
      "interview_date": "2026-05-25T10:00:00+07:00",
      "notes": "Strong technical match"
    }
  ],
  "stats": {
    "total_applications": 23,
    "by_status": {
      "applied": 10,
      "screening": 3,
      "interview": 2,
      "offer": 1,
      "rejected": 7
    }
  }
}
```

---

## Commands

**CV Management:**
- "Update my CV with [experience]"
- "Create a CV tailored for [job posting]"
- "Show my latest CV"
- "List all CV versions"

**Job Search:**
- "Search for [role] jobs in [location]"
- "Find remote [role] positions"
- "Show me jobs at [company]"

**Application Tracking:**
- "I applied to [company] for [role]"
- "Update [company] status to [status]"
- "Show all my applications"
- "What applications need follow-up?"

**Interview Prep:**
- "Prepare for [company] interview"
- "Generate interview questions for [role]"
- "What should I ask [company]?"

**Reporting:**
- "Show my job hunt stats"
- "Weekly application summary"
- "What's my response rate?"

---

## Automation

### Cron Jobs

1. **Weekly Summary** (Monday 9am)
   ```json
   {
     "schedule": {"kind": "cron", "expr": "0 9 * * 1", "tz": "Asia/Saigon"},
     "payload": {
       "kind": "agentTurn",
       "message": "Generate job hunt weekly summary and send via Telegram"
     }
   }
   ```

2. **Follow-up Reminders** (Daily 10am)
   ```json
   {
     "schedule": {"kind": "cron", "expr": "0 10 * * *", "tz": "Asia/Saigon"},
     "payload": {
       "kind": "agentTurn",
       "message": "Check applications needing follow-up (7+ days no response)"
     }
   }
   ```

3. **Interview Reminders** (1 day before)
   - Created dynamically when interview is scheduled

---

## Integration Points

### LinkedIn
- Use `browser` tool with `profile="user"` for authenticated searches
- Extract job postings with full details
- Track "Easy Apply" vs external applications

### Email Integration
- Monitor Gmail for application responses
- Auto-update tracker when keywords detected:
  - "interview", "schedule", "offer", "unfortunately"
- Parse interview invites for date/time

### Telegram Notifications
- Application status changes
- Interview reminders (1 day, 1 hour before)
- Weekly summaries
- Follow-up alerts

---

## Safety & Privacy

**Do NOT:**
- Share CV or application details in group chats
- Post job search activity publicly
- Send applications without explicit user approval

**Always ask before:**
- Submitting job applications
- Sending follow-up emails
- Sharing CV with anyone

**Secure storage:**
- All CV and application data in `memory/cv_job_hunter/`
- Never log sensitive info (salary expectations, personal details) in main memory
- Redact personal info when showing examples

---

## Credentials Needed

Store in OpenClaw vault:

```bash
# LinkedIn (optional, for authenticated searches)
openclaw vault set LINKEDIN_EMAIL "your_email"
openclaw vault set LINKEDIN_PASSWORD "your_password"

# Telegram (for notifications)
openclaw vault set TELEGRAM_BOT_TOKEN "your_bot_token"
openclaw vault set TELEGRAM_CHAT_ID "your_chat_id"
```

---

## Related Skills

- **Communication Agent:** For sending follow-up emails
- **Google Workspace Agent:** For calendar integration (interview scheduling)
- **Safe Email Assistant:** For monitoring application responses
- **Research Agent:** For company research

---

## Maintenance

**Weekly:**
- Archive old job searches (>30 days)
- Update stats in tracker.json

**Monthly:**
- Review and update CV based on new experiences
- Analyze application success rate
- Adjust search criteria if needed

---

**Last Updated:** 2026-05-19

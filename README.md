# OpenClaw Personal Assistant System

A production-ready, autonomous multi-agent system powered by the **OpenClaw framework**. This system acts as a proactive personal AI assistant designed specifically for a Flutter/Native developer working with Azure, Microsoft Teams, and Jira.

## 🏗 Architecture

The system follows a modular, multi-agent design:

1. **Task Manager Agent**: Integrates with Jira to track and summarize tasks, deadlines, and statuses.
2. **Communication Agent**: Connects to Microsoft Teams to read, summarize, and extract actionable requests and bug reports.
3. **Research Agent**: Uses browser automation to monitor Reddit, VOZ, X, and tech blogs for Flutter, iOS/Android, and AI news.
4. **Planner Agent**: Generates daily and weekly plans based on historical logs and priorities.
5. **DevOps Agent**: Monitors Git and CI/CD pipelines (Azure DevOps/GitHub Actions), summarizing build failures and suggesting refactors.

All agents run autonomously within time-windowed constraints, orchestrated by OpenClaw's internal scheduler (`workspace/HEARTBEAT.md`).

## 🔒 Security & Privacy

Security is paramount. This environment enforces:
- **Docker Isolation**: Runs exclusively inside a non-root container.
- **Localhost Binding**: Binds strictly to `127.0.0.1`—no public ports exposed.
- **Secret Management**: All tokens and API keys are stored in environment variables, never in plain text files.
- **Human-In-The-Loop (HITL)**: Requires explicit user approval (via Telegram) for file deletions, system-level commands, and external state modifications.
- **Skill Policy**: Only local, pre-verified skills in the `skills/` directory are executed.

## 🚀 Getting Started

### 1. Configure Environment Variables
Copy the example configuration file and fill in your actual API keys and tokens:
```bash
cp .env.example .env
```
*Make sure to provide your Telegram Bot Token, Jira API Token, Teams Credentials, and LLM API Key (e.g., OpenAI/Anthropic).*

### 2. Build and Run the Docker Container
The system is fully containerized. Start it using Docker Compose:
```bash
docker-compose up --build -d
```
To view the logs:
```bash
docker-compose logs -f
```

## 🧠 Memory System
The agent utilizes a file-based persistent memory system located in the `workspace/` directory:
- `USER.md`: Stores your profile, work habits, and output preferences.
- `MEMORY.md`: Long-term system state, known project issues, and high-level goals.
- `HEARTBEAT.md`: The cron-like checklist the agent reviews every 30 minutes.
- `YYYY-MM-DD.md`: Daily generated logs containing your daily plans, progress, and end-of-day summaries.

## 📋 Example Workflows

### 1. Morning Briefing (08:00 AM)
- **Trigger**: Heartbeat cron matches 08:00.
- **Action**: The **Planner Agent** reviews yesterday's log, checks Jira via the **Task Manager Agent**, and generates `workspace/2026-03-22.md`.
- **Output**: You receive a Telegram message with a prioritized task list and a summary of overnight Teams messages.

### 2. CI/CD Build Failure
- **Trigger**: **DevOps Agent** detects a failed Azure DevOps pipeline during a heartbeat check.
- **Action**: The agent fetches the build logs, identifies a Gradle version mismatch, and queries the **Research Agent** for the latest stable Flutter/Gradle combination.
- **Output**: Telegram message: *"Build failed on branch `feature/login`. Cause: Gradle version mismatch. Suggested fix: Update `android/build.gradle` to version 8.1.0."*

### 3. Weekly Research Digest (Monday Morning)
- **Trigger**: Weekly heartbeat trigger.
- **Action**: **Research Agent** scrapes top posts from `/r/FlutterDev`, tech blogs, and VOZ regarding AI tools and mobile development.
- **Output**: A concise markdown digest appended to your Monday log and sent via Telegram.

### 4. Task Extraction from Teams
- **Trigger**: New message in the Product team channel.
- **Action**: **Communication Agent** identifies an actionable bug report from a Product Manager. It proposes creating a Jira ticket.
- **Output**: Telegram prompt: *"PM reported a UI glitch on the iOS payment screen. Should I create a Jira ticket with High priority? [Approve/Reject]"*

# Data QA Knowledge Digest Template

This template is used by `generate_digest.py` to format the daily digest.

## Format

```markdown
📚 **Data QA Knowledge Digest - {date}**

🔥 **Trending Today** ({count} items):
- [Source] Title
  URL

💡 **Best Practice** ({count} items):
- [Source] Title
  URL

🛠️ **New Tool** ({count} items):
- [Source] Title
  URL

📖 **Learning Resource** ({count} items):
- [Source] Title
  URL

🐛 **Common Issue** ({count} items):
- [Source] Title
  URL

📊 **Case Study** ({count} items):
- [Source] Title
  URL

📊 **Stats:**
- {total_crawled} items crawled, {total_selected} selected
- Sources: {source_list}
```

## Category Descriptions

- **Trending Today**: High engagement, recent posts with broad interest
- **Best Practice**: Proven patterns, approaches, and strategies
- **New Tool**: Tool announcements, releases, and updates
- **Learning Resource**: Tutorials, guides, courses, and documentation
- **Common Issue**: Q&A, troubleshooting, and problem-solving
- **Case Study**: Real-world examples and production stories

## Customization

Edit `references/config.json` to:
- Change max items per category
- Enable/disable categories
- Adjust emoji icons
- Modify delivery format

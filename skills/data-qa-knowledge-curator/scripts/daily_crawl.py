"""
Daily Crawl - Main orchestrator for knowledge aggregation
"""
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict
import subprocess

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))


def load_config():
    """Load configuration"""
    config_path = Path(__file__).parent.parent / "references" / "config.json"
    with open(config_path) as f:
        return json.load(f)


def run_crawler(script_name: str) -> List[Dict]:
    """
    Run a crawler script and return results
    
    Args:
        script_name: Name of the crawler script (e.g., "crawl_reddit.py")
        
    Returns:
        List of crawled items
    """
    script_path = Path(__file__).parent / script_name
    
    try:
        result = subprocess.run(
            ["python3", str(script_path)],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Parse JSON output
        output_lines = result.stdout.strip().split('\n')
        # Find the JSON output (skip any print statements)
        json_start = -1
        for i, line in enumerate(output_lines):
            if line.strip().startswith('['):
                json_start = i
                break
        
        if json_start >= 0:
            json_output = '\n'.join(output_lines[json_start:])
            return json.loads(json_output)
        else:
            print(f"Warning: No JSON output from {script_name}", file=sys.stderr)
            return []
    except subprocess.CalledProcessError as e:
        print(f"Error running {script_name}: {e.stderr}", file=sys.stderr)
        return []
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON from {script_name}: {e}", file=sys.stderr)
        return []
    except Exception as e:
        print(f"Unexpected error running {script_name}: {e}", file=sys.stderr)
        return []


def categorize_content(items: List[Dict]) -> Dict[str, List[Dict]]:
    """
    Categorize content into digest categories
    
    Categories:
    - trending: High engagement, recent
    - best_practice: Case studies, how-to guides
    - new_tool: Tool announcements, releases
    - learning_resource: Tutorials, courses
    - common_issue: Q&A, troubleshooting
    - case_study: Real-world examples
    """
    categories = {
        "trending": [],
        "best_practice": [],
        "new_tool": [],
        "learning_resource": [],
        "common_issue": [],
        "case_study": []
    }
    
    for item in items:
        text = f"{item.get('title', '')} {item.get('text', '')} {item.get('description', '')}".lower()
        
        # Categorization logic
        if any(word in text for word in ["tutorial", "guide", "learn", "course", "introduction"]):
            categories["learning_resource"].append(item)
        elif any(word in text for word in ["case study", "how we", "at scale", "production"]):
            categories["case_study"].append(item)
        elif any(word in text for word in ["release", "announcing", "new tool", "launched", "v1.0", "v2.0"]):
            categories["new_tool"].append(item)
        elif any(word in text for word in ["best practice", "pattern", "approach", "strategy"]):
            categories["best_practice"].append(item)
        elif any(word in text for word in ["issue", "problem", "error", "fix", "solution"]):
            categories["common_issue"].append(item)
        else:
            # Default to trending if high engagement
            if item.get("relevance_score", 0) >= 80:
                categories["trending"].append(item)
    
    return categories


def generate_digest(categorized_items: Dict[str, List[Dict]], config: dict) -> str:
    """
    Generate markdown digest from categorized items
    
    Args:
        categorized_items: Items organized by category
        config: Configuration dict
        
    Returns:
        Markdown formatted digest
    """
    max_per_category = config["digest"]["max_items_per_category"]
    
    # Build digest
    lines = []
    lines.append(f"📚 **Data QA Knowledge Digest - {datetime.now().strftime('%B %d, %Y')}**")
    lines.append("")
    
    total_items = 0
    
    # Emoji mapping
    category_emoji = {
        "trending": "🔥",
        "best_practice": "💡",
        "new_tool": "🛠️",
        "learning_resource": "📖",
        "common_issue": "🐛",
        "case_study": "📊"
    }
    
    category_names = {
        "trending": "Trending Today",
        "best_practice": "Best Practice",
        "new_tool": "New Tool",
        "learning_resource": "Learning Resource",
        "common_issue": "Common Issue",
        "case_study": "Case Study"
    }
    
    for category in config["digest"]["categories"]:
        items = categorized_items.get(category, [])[:max_per_category]
        
        if items:
            emoji = category_emoji.get(category, "📌")
            name = category_names.get(category, category.replace("_", " ").title())
            
            lines.append(f"{emoji} **{name}** ({len(items)} item{'s' if len(items) > 1 else ''}):")
            
            for item in items:
                source = item.get("source", "unknown")
                title = item.get("title") or item.get("text", "")[:100]
                url = item.get("url", "")
                score = item.get("relevance_score", 0)
                
                # Format based on source
                if source == "reddit":
                    subreddit = item.get("subreddit", "")
                    lines.append(f"- [Reddit r/{subreddit}] {title}")
                elif source == "twitter":
                    author = item.get("author_username", "")
                    lines.append(f"- [Twitter @{author}] {title}")
                elif source == "github":
                    name = item.get("name", "")
                    lines.append(f"- [GitHub] {name}: {title}")
                else:
                    lines.append(f"- [{source}] {title}")
                
                lines.append(f"  {url}")
                lines.append("")
                
                total_items += 1
            
            lines.append("")
    
    # Stats
    lines.append("📊 **Stats:**")
    total_crawled = sum(len(items) for items in categorized_items.values())
    sources = set(item.get("source") for cat_items in categorized_items.values() for item in cat_items)
    lines.append(f"- {total_crawled} items crawled, {total_items} selected")
    lines.append(f"- Sources: {', '.join(sorted(sources))}")
    
    return "\n".join(lines)


def save_to_knowledge_base(items: List[Dict], config: dict):
    """Save items to knowledge base for future search"""
    kb_path = Path(config["storage"]["knowledge_base_path"]).expanduser()
    kb_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Load existing knowledge base
    if kb_path.exists():
        with open(kb_path) as f:
            kb = json.load(f)
    else:
        kb = {"items": []}
    
    # Add new items
    kb["items"].extend(items)
    
    # Sort by crawled_at and keep only recent items
    kb["items"].sort(key=lambda x: x.get("crawled_at", ""), reverse=True)
    max_items = config["storage"]["max_items"]
    kb["items"] = kb["items"][:max_items]
    
    # Save
    with open(kb_path, 'w') as f:
        json.dump(kb, f, indent=2)
    
    print(f"Saved {len(items)} items to knowledge base ({kb_path})")


def main():
    """Main entry point"""
    print("=" * 60)
    print("Data QA Knowledge Curator - Daily Crawl")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    print()
    
    config = load_config()
    
    all_items = []
    
    # Run crawlers
    if config["sources"]["reddit"]["enabled"]:
        print("Crawling Reddit...")
        reddit_items = run_crawler("crawl_reddit.py")
        print(f"  Found {len(reddit_items)} items from Reddit")
        all_items.extend(reddit_items)
    
    if config["sources"].get("hackernews", {}).get("enabled", False):
        print("Crawling Hacker News...")
        hn_items = run_crawler("crawl_hackernews.py")
        print(f"  Found {len(hn_items)} items from Hacker News")
        all_items.extend(hn_items)
    
    if config["sources"].get("devto", {}).get("enabled", False):
        print("Crawling Dev.to...")
        devto_items = run_crawler("crawl_devto.py")
        print(f"  Found {len(devto_items)} items from Dev.to")
        all_items.extend(devto_items)
    
    if config["sources"]["twitter"]["enabled"]:
        print("Crawling Twitter...")
        twitter_items = run_crawler("crawl_twitter.py")
        print(f"  Found {len(twitter_items)} items from Twitter")
        all_items.extend(twitter_items)
    
    if config["sources"]["github"]["enabled"]:
        print("Crawling GitHub...")
        github_items = run_crawler("crawl_github.py")
        print(f"  Found {len(github_items)} items from GitHub")
        all_items.extend(github_items)
    
    print()
    print(f"Total items collected: {len(all_items)}")
    
    if not all_items:
        print("No items found. Exiting.")
        return
    
    # Categorize content
    print("Categorizing content...")
    categorized = categorize_content(all_items)
    
    # Generate digest
    print("Generating digest...")
    digest = generate_digest(categorized, config)
    
    # Save to knowledge base
    save_to_knowledge_base(all_items, config)
    
    # Output digest
    print()
    print("=" * 60)
    print("DIGEST")
    print("=" * 60)
    print()
    print(digest)
    
    # TODO: Send to Telegram if enabled
    if config["telegram"]["enabled"]:
        print()
        print("Note: Telegram delivery not yet implemented")
        print("Digest is ready to be sent via OpenClaw messaging")


if __name__ == "__main__":
    main()

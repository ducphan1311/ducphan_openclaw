"""
Hacker News Crawler - Fetch Data QA content from Hacker News
"""
import requests
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict
import time

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))


def load_config():
    """Load configuration"""
    config_path = Path(__file__).parent.parent / "references" / "config.json"
    with open(config_path) as f:
        return json.load(f)


def load_keywords():
    """Load keyword filters"""
    keywords_path = Path(__file__).parent.parent / "references" / "keywords.json"
    with open(keywords_path) as f:
        return json.load(f)


def calculate_relevance_score(story, keywords) -> float:
    """Calculate relevance score for a story"""
    score = 0.0
    text = f"{story.get('title', '')} {story.get('text', '')}".lower()
    
    # Keyword matching (0-40 points)
    high_priority_matches = sum(1 for kw in keywords["high_priority"] if kw.lower() in text)
    medium_priority_matches = sum(1 for kw in keywords["medium_priority"] if kw.lower() in text)
    tool_matches = sum(1 for tool in keywords["tools"] if tool.lower() in text)
    
    keyword_score = min(40, (high_priority_matches * 10) + (medium_priority_matches * 5) + (tool_matches * 8))
    score += keyword_score
    
    # Check exclusions
    exclude_matches = sum(1 for ex in keywords["exclude"] if ex.lower() in text)
    if exclude_matches > 0:
        return 0.0
    
    # Engagement (0-30 points)
    points = story.get('score', 0)
    descendants = story.get('descendants', 0)  # comment count
    engagement_score = min(30, (points / 100 * 15) + (descendants / 50 * 15))
    score += engagement_score
    
    # Recency (0-20 points)
    story_time = story.get('time', 0)
    hours_since = (datetime.utcnow().timestamp() - story_time) / 3600
    recency_score = max(0, 20 - (hours_since / 24 * 5))
    score += recency_score
    
    # Source credibility (0-10 points)
    # HN is generally high quality
    score += 10
    
    return score


def get_story_details(story_id: int) -> Dict:
    """Get full story details from HN API"""
    url = f"https://hacker-news.firebaseio.com/v0/item/{story_id}.json"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching story {story_id}: {e}", file=sys.stderr)
        return {}


def crawl_hackernews(max_stories: int = 50, hours_back: int = 24) -> List[Dict]:
    """
    Crawl Hacker News for Data QA content
    
    Args:
        max_stories: Max stories to check
        hours_back: Only include stories from last N hours
        
    Returns:
        List of relevant stories
    """
    keywords = load_keywords()
    
    # Get top stories
    url = "https://hacker-news.firebaseio.com/v0/topstories.json"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        story_ids = response.json()[:max_stories]
    except Exception as e:
        print(f"Error fetching top stories: {e}", file=sys.stderr)
        return []
    
    results = []
    cutoff_time = datetime.utcnow().timestamp() - (hours_back * 3600)
    
    for story_id in story_ids:
        story = get_story_details(story_id)
        
        if not story or story.get('type') != 'story':
            continue
        
        # Check recency
        if story.get('time', 0) < cutoff_time:
            continue
        
        # Calculate relevance
        score = calculate_relevance_score(story, keywords)
        
        if score > 0:
            results.append({
                "source": "hackernews",
                "story_id": story_id,
                "title": story.get('title', ''),
                "url": story.get('url', f"https://news.ycombinator.com/item?id={story_id}"),
                "text": story.get('text', '')[:500],
                "author": story.get('by', ''),
                "score": story.get('score', 0),
                "num_comments": story.get('descendants', 0),
                "created_utc": story.get('time', 0),
                "relevance_score": score,
                "crawled_at": datetime.utcnow().isoformat()
            })
        
        # Rate limiting: HN API is generous but be respectful
        time.sleep(0.1)
    
    # Sort by relevance
    results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    return results


def main():
    """Main entry point"""
    config = load_config()
    hn_config = config["sources"].get("hackernews", {})
    
    if not hn_config.get("enabled", True):
        print("Hacker News crawler is disabled in config")
        return
    
    max_stories = hn_config.get("max_stories", 50)
    hours_back = hn_config.get("hours_back", 24)
    
    print(f"Crawling Hacker News (last {hours_back} hours, max {max_stories} stories)...")
    
    results = crawl_hackernews(max_stories=max_stories, hours_back=hours_back)
    
    # Filter by minimum score
    min_score = config["relevance"]["min_score"]
    filtered_results = [r for r in results if r["relevance_score"] >= min_score]
    
    print(f"Found {len(results)} stories, {len(filtered_results)} above threshold (>={min_score})")
    
    # Output as JSON
    print(json.dumps(filtered_results, indent=2))


if __name__ == "__main__":
    main()

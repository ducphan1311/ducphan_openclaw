"""
Reddit Crawler - Fetch Data QA content from Reddit
"""
import praw
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import List, Dict

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))
from vault_helper import get_reddit_credentials


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


def calculate_relevance_score(post, keywords) -> float:
    """
    Calculate relevance score for a post
    
    Score components:
    - Keyword match (0-40 points)
    - Engagement (0-30 points)
    - Recency (0-20 points)
    - Source credibility (0-10 points)
    """
    score = 0.0
    text = f"{post.title} {post.selftext}".lower()
    
    # Keyword matching (0-40 points)
    high_priority_matches = sum(1 for kw in keywords["high_priority"] if kw.lower() in text)
    medium_priority_matches = sum(1 for kw in keywords["medium_priority"] if kw.lower() in text)
    tool_matches = sum(1 for tool in keywords["tools"] if tool.lower() in text)
    
    keyword_score = min(40, (high_priority_matches * 10) + (medium_priority_matches * 5) + (tool_matches * 8))
    score += keyword_score
    
    # Check exclusions
    exclude_matches = sum(1 for ex in keywords["exclude"] if ex.lower() in text)
    if exclude_matches > 0:
        return 0.0  # Exclude this post
    
    # Engagement (0-30 points)
    upvote_ratio = post.upvote_ratio if hasattr(post, 'upvote_ratio') else 0.5
    num_comments = post.num_comments
    engagement_score = min(30, (upvote_ratio * 15) + (min(num_comments, 50) / 50 * 15))
    score += engagement_score
    
    # Recency (0-20 points)
    post_age_hours = (datetime.utcnow().timestamp() - post.created_utc) / 3600
    recency_score = max(0, 20 - (post_age_hours / 24 * 5))  # Decay over 4 days
    score += recency_score
    
    # Source credibility (0-10 points)
    # Higher score for posts from known good subreddits
    credible_subs = ["dataengineering", "dataquality", "bigquery"]
    if post.subreddit.display_name.lower() in credible_subs:
        score += 10
    else:
        score += 5
    
    return score


def crawl_reddit(subreddits: List[str], time_filter: str = "day", limit: int = 25) -> List[Dict]:
    """
    Crawl Reddit for Data QA content
    
    Args:
        subreddits: List of subreddit names
        time_filter: Time filter (hour, day, week, month, year, all)
        limit: Max posts per subreddit
        
    Returns:
        List of relevant posts with metadata
    """
    # Get credentials from Vault
    creds = get_reddit_credentials()
    
    # Initialize Reddit client
    reddit = praw.Reddit(
        client_id=creds["client_id"],
        client_secret=creds["client_secret"],
        user_agent=creds["user_agent"]
    )
    
    # Load keywords for filtering
    keywords = load_keywords()
    
    results = []
    
    for subreddit_name in subreddits:
        try:
            subreddit = reddit.subreddit(subreddit_name)
            
            # Get hot posts
            for post in subreddit.hot(limit=limit):
                # Calculate relevance score
                score = calculate_relevance_score(post, keywords)
                
                if score > 0:  # Only include if not excluded
                    results.append({
                        "source": "reddit",
                        "subreddit": subreddit_name,
                        "title": post.title,
                        "url": f"https://reddit.com{post.permalink}",
                        "text": post.selftext[:500] if post.selftext else "",
                        "author": str(post.author),
                        "score": post.score,
                        "num_comments": post.num_comments,
                        "created_utc": post.created_utc,
                        "relevance_score": score,
                        "crawled_at": datetime.utcnow().isoformat()
                    })
        except Exception as e:
            print(f"Error crawling r/{subreddit_name}: {e}", file=sys.stderr)
            continue
    
    # Sort by relevance score
    results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    return results


def main():
    """Main entry point"""
    config = load_config()
    reddit_config = config["sources"]["reddit"]
    
    if not reddit_config["enabled"]:
        print("Reddit crawler is disabled in config")
        return
    
    print(f"Crawling {len(reddit_config['subreddits'])} subreddits...")
    
    results = crawl_reddit(
        subreddits=reddit_config["subreddits"],
        time_filter=reddit_config["time_filter"],
        limit=reddit_config["limit"]
    )
    
    # Filter by minimum score
    min_score = config["relevance"]["min_score"]
    filtered_results = [r for r in results if r["relevance_score"] >= min_score]
    
    print(f"Found {len(results)} posts, {len(filtered_results)} above threshold (>={min_score})")
    
    # Output as JSON
    print(json.dumps(filtered_results, indent=2))


if __name__ == "__main__":
    main()

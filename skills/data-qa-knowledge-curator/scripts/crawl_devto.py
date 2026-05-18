"""
Dev.to Crawler - Fetch Data QA content from Dev.to
"""
import requests
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict

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


def calculate_relevance_score(article, keywords) -> float:
    """Calculate relevance score for an article"""
    score = 0.0
    text = f"{article.get('title', '')} {article.get('description', '')} {' '.join(article.get('tag_list', []))}".lower()
    
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
    reactions = article.get('public_reactions_count', 0)
    comments = article.get('comments_count', 0)
    engagement_score = min(30, (reactions / 50 * 15) + (comments / 20 * 15))
    score += engagement_score
    
    # Recency (0-20 points)
    published_at = datetime.fromisoformat(article['published_at'].replace('Z', '+00:00'))
    hours_since = (datetime.now(published_at.tzinfo) - published_at).total_seconds() / 3600
    recency_score = max(0, 20 - (hours_since / 24 * 5))
    score += recency_score
    
    # Source credibility (0-10 points)
    # Dev.to is generally good quality
    score += 8
    
    return score


def search_articles(tags: List[str], per_page: int = 30) -> List[Dict]:
    """
    Search Dev.to articles by tags
    
    Args:
        tags: List of tags to search
        per_page: Results per tag
        
    Returns:
        List of relevant articles
    """
    keywords = load_keywords()
    results = []
    seen_ids = set()
    
    base_url = "https://dev.to/api/articles"
    
    for tag in tags:
        try:
            params = {
                "tag": tag,
                "per_page": per_page,
                "top": 7  # Last 7 days
            }
            
            response = requests.get(base_url, params=params, timeout=10)
            response.raise_for_status()
            
            articles = response.json()
            
            for article in articles:
                article_id = article["id"]
                if article_id in seen_ids:
                    continue
                seen_ids.add(article_id)
                
                # Calculate relevance
                score = calculate_relevance_score(article, keywords)
                
                if score > 0:
                    results.append({
                        "source": "devto",
                        "article_id": article_id,
                        "title": article["title"],
                        "url": article["url"],
                        "description": article.get("description", "")[:500],
                        "author": article["user"]["name"],
                        "author_username": article["user"]["username"],
                        "tags": article.get("tag_list", []),
                        "reactions": article.get("public_reactions_count", 0),
                        "comments": article.get("comments_count", 0),
                        "published_at": article["published_at"],
                        "relevance_score": score,
                        "crawled_at": datetime.utcnow().isoformat()
                    })
        except Exception as e:
            print(f"Error searching tag '{tag}': {e}", file=sys.stderr)
            continue
    
    # Sort by relevance
    results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    return results


def get_latest_articles(per_page: int = 30) -> List[Dict]:
    """
    Get latest articles from Dev.to
    
    Args:
        per_page: Number of articles to fetch
        
    Returns:
        List of relevant articles
    """
    keywords = load_keywords()
    results = []
    
    base_url = "https://dev.to/api/articles"
    
    try:
        params = {
            "per_page": per_page,
            "top": 7  # Last 7 days
        }
        
        response = requests.get(base_url, params=params, timeout=10)
        response.raise_for_status()
        
        articles = response.json()
        
        for article in articles:
            score = calculate_relevance_score(article, keywords)
            
            if score > 0:
                results.append({
                    "source": "devto",
                    "article_id": article["id"],
                    "title": article["title"],
                    "url": article["url"],
                    "description": article.get("description", "")[:500],
                    "author": article["user"]["name"],
                    "author_username": article["user"]["username"],
                    "tags": article.get("tag_list", []),
                    "reactions": article.get("public_reactions_count", 0),
                    "comments": article.get("comments_count", 0),
                    "published_at": article["published_at"],
                    "relevance_score": score,
                    "crawled_at": datetime.utcnow().isoformat()
                })
    except Exception as e:
        print(f"Error fetching latest articles: {e}", file=sys.stderr)
    
    return results


def crawl_devto(tags: List[str], per_page: int = 30) -> List[Dict]:
    """
    Crawl Dev.to for Data QA content
    
    Args:
        tags: List of tags to search
        per_page: Results per tag
        
    Returns:
        List of relevant articles
    """
    # Search by tags
    results = search_articles(tags, per_page)
    
    # Also get latest articles
    latest = get_latest_articles(per_page)
    results.extend(latest)
    
    # Remove duplicates
    seen = set()
    unique_results = []
    for r in results:
        if r["article_id"] not in seen:
            seen.add(r["article_id"])
            unique_results.append(r)
    
    # Sort by relevance
    unique_results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    return unique_results


def main():
    """Main entry point"""
    config = load_config()
    devto_config = config["sources"].get("devto", {})
    
    if not devto_config.get("enabled", True):
        print("Dev.to crawler is disabled in config")
        return
    
    tags = devto_config.get("tags", [
        "dataengineering",
        "dataquality",
        "testing",
        "sql",
        "etl"
    ])
    per_page = devto_config.get("per_page", 30)
    
    print(f"Crawling Dev.to for {len(tags)} tags...")
    
    results = crawl_devto(tags=tags, per_page=per_page)
    
    # Filter by minimum score
    min_score = config["relevance"]["min_score"]
    filtered_results = [r for r in results if r["relevance_score"] >= min_score]
    
    print(f"Found {len(results)} articles, {len(filtered_results)} above threshold (>={min_score})")
    
    # Output as JSON
    print(json.dumps(filtered_results, indent=2))


if __name__ == "__main__":
    main()

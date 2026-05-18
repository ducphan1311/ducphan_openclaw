"""
Twitter/X Crawler - Fetch Data QA content from Twitter
"""
import requests
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))
from vault_helper import get_twitter_credentials


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


def calculate_relevance_score(tweet, keywords) -> float:
    """Calculate relevance score for a tweet"""
    score = 0.0
    text = tweet.get("text", "").lower()
    
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
    metrics = tweet.get("public_metrics", {})
    likes = metrics.get("like_count", 0)
    retweets = metrics.get("retweet_count", 0)
    replies = metrics.get("reply_count", 0)
    
    engagement_score = min(30, (likes / 100 * 10) + (retweets / 50 * 10) + (replies / 20 * 10))
    score += engagement_score
    
    # Recency (0-20 points)
    created_at = datetime.fromisoformat(tweet["created_at"].replace("Z", "+00:00"))
    hours_since = (datetime.now(created_at.tzinfo) - created_at).total_seconds() / 3600
    recency_score = max(0, 20 - (hours_since / 24 * 5))
    score += recency_score
    
    # Source credibility (0-10 points)
    # Check if from known accounts
    author_username = tweet.get("author_username", "").lower()
    credible_accounts = ["dbt_labs", "greatexpect", "apacheairflow"]
    if author_username in credible_accounts:
        score += 10
    else:
        score += 5
    
    return score


def search_tweets(query: str, max_results: int = 20) -> List[Dict]:
    """
    Search tweets using Twitter API v2
    
    Args:
        query: Search query
        max_results: Max results (10-100)
        
    Returns:
        List of relevant tweets
    """
    creds = get_twitter_credentials()
    
    headers = {
        "Authorization": f"Bearer {creds['bearer_token']}"
    }
    
    # Search recent tweets (last 7 days for Basic tier)
    url = "https://api.twitter.com/2/tweets/search/recent"
    
    params = {
        "query": query,
        "max_results": min(max_results, 100),
        "tweet.fields": "created_at,public_metrics,author_id",
        "expansions": "author_id",
        "user.fields": "username,name"
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error searching tweets: {e}", file=sys.stderr)
        return {"data": [], "includes": {}}


def crawl_twitter(hashtags: List[str], accounts: List[str], max_results: int = 20) -> List[Dict]:
    """
    Crawl Twitter for Data QA content
    
    Args:
        hashtags: List of hashtags to search
        accounts: List of account usernames to monitor
        max_results: Max results per query
        
    Returns:
        List of relevant tweets
    """
    keywords = load_keywords()
    results = []
    seen_tweets = set()
    
    # Search by hashtags
    for hashtag in hashtags:
        query = f"#{hashtag} -is:retweet lang:en"
        
        try:
            data = search_tweets(query, max_results)
            tweets = data.get("data", [])
            users = {u["id"]: u for u in data.get("includes", {}).get("users", [])}
            
            for tweet in tweets:
                tweet_id = tweet["id"]
                if tweet_id in seen_tweets:
                    continue
                seen_tweets.add(tweet_id)
                
                # Add author info
                author_id = tweet.get("author_id")
                author = users.get(author_id, {})
                tweet["author_username"] = author.get("username", "")
                tweet["author_name"] = author.get("name", "")
                
                # Calculate relevance score
                score = calculate_relevance_score(tweet, keywords)
                
                if score > 0:
                    results.append({
                        "source": "twitter",
                        "tweet_id": tweet_id,
                        "text": tweet["text"],
                        "url": f"https://twitter.com/{tweet['author_username']}/status/{tweet_id}",
                        "author": tweet["author_name"],
                        "author_username": tweet["author_username"],
                        "created_at": tweet["created_at"],
                        "likes": tweet["public_metrics"]["like_count"],
                        "retweets": tweet["public_metrics"]["retweet_count"],
                        "replies": tweet["public_metrics"]["reply_count"],
                        "relevance_score": score,
                        "crawled_at": datetime.utcnow().isoformat()
                    })
        except Exception as e:
            print(f"Error searching #{hashtag}: {e}", file=sys.stderr)
            continue
    
    # Search by accounts
    for account in accounts:
        query = f"from:{account} -is:retweet lang:en"
        
        try:
            data = search_tweets(query, max_results)
            tweets = data.get("data", [])
            users = {u["id"]: u for u in data.get("includes", {}).get("users", [])}
            
            for tweet in tweets:
                tweet_id = tweet["id"]
                if tweet_id in seen_tweets:
                    continue
                seen_tweets.add(tweet_id)
                
                # Add author info
                author_id = tweet.get("author_id")
                author = users.get(author_id, {})
                tweet["author_username"] = author.get("username", "")
                tweet["author_name"] = author.get("name", "")
                
                score = calculate_relevance_score(tweet, keywords)
                
                if score > 0:
                    results.append({
                        "source": "twitter",
                        "tweet_id": tweet_id,
                        "text": tweet["text"],
                        "url": f"https://twitter.com/{tweet['author_username']}/status/{tweet_id}",
                        "author": tweet["author_name"],
                        "author_username": tweet["author_username"],
                        "created_at": tweet["created_at"],
                        "likes": tweet["public_metrics"]["like_count"],
                        "retweets": tweet["public_metrics"]["retweet_count"],
                        "replies": tweet["public_metrics"]["reply_count"],
                        "relevance_score": score,
                        "crawled_at": datetime.utcnow().isoformat()
                    })
        except Exception as e:
            print(f"Error searching @{account}: {e}", file=sys.stderr)
            continue
    
    # Sort by relevance score
    results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    return results


def main():
    """Main entry point"""
    config = load_config()
    twitter_config = config["sources"]["twitter"]
    
    if not twitter_config["enabled"]:
        print("Twitter crawler is disabled in config")
        return
    
    print(f"Crawling Twitter for {len(twitter_config['hashtags'])} hashtags and {len(twitter_config['accounts'])} accounts...")
    
    results = crawl_twitter(
        hashtags=twitter_config["hashtags"],
        accounts=twitter_config["accounts"],
        max_results=twitter_config["max_results"]
    )
    
    # Filter by minimum score
    min_score = config["relevance"]["min_score"]
    filtered_results = [r for r in results if r["relevance_score"] >= min_score]
    
    print(f"Found {len(results)} tweets, {len(filtered_results)} above threshold (>={min_score})")
    
    # Output as JSON
    print(json.dumps(filtered_results, indent=2))


if __name__ == "__main__":
    main()

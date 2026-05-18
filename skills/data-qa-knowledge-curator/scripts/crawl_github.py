"""
GitHub Crawler - Fetch trending Data QA repositories and releases
"""
import requests
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))
from vault_helper import get_github_credentials


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


def calculate_relevance_score(repo, keywords) -> float:
    """Calculate relevance score for a repository"""
    score = 0.0
    text = f"{repo['name']} {repo['description'] or ''}".lower()
    
    # Keyword matching (0-40 points)
    high_priority_matches = sum(1 for kw in keywords["high_priority"] if kw.lower() in text)
    tool_matches = sum(1 for tool in keywords["tools"] if tool.lower() in text)
    
    keyword_score = min(40, (high_priority_matches * 10) + (tool_matches * 8))
    score += keyword_score
    
    # Popularity (0-30 points)
    stars = repo.get('stargazers_count', 0)
    star_score = min(30, (stars / 1000) * 10)  # 1k stars = 10 points, max 30
    score += star_score
    
    # Activity (0-20 points)
    updated_at = datetime.fromisoformat(repo['updated_at'].replace('Z', '+00:00'))
    days_since_update = (datetime.now(updated_at.tzinfo) - updated_at).days
    activity_score = max(0, 20 - (days_since_update / 30 * 5))  # Decay over 4 months
    score += activity_score
    
    # Language bonus (0-10 points)
    preferred_languages = ['Python', 'SQL', 'TypeScript', 'JavaScript']
    if repo.get('language') in preferred_languages:
        score += 10
    else:
        score += 5
    
    return score


def search_repositories(topics: List[str], limit: int = 10) -> List[Dict]:
    """
    Search GitHub repositories by topics
    
    Args:
        topics: List of topics to search
        limit: Max results per topic
        
    Returns:
        List of relevant repositories
    """
    creds = get_github_credentials()
    headers = {
        "Authorization": f"token {creds['token']}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    keywords = load_keywords()
    results = []
    seen_repos = set()
    
    for topic in topics:
        try:
            # Search repositories by topic
            url = "https://api.github.com/search/repositories"
            params = {
                "q": f"topic:{topic}",
                "sort": "updated",
                "order": "desc",
                "per_page": limit
            }
            
            response = requests.get(url, headers=headers, params=params)
            response.raise_for_status()
            
            data = response.json()
            
            for repo in data.get("items", []):
                repo_id = repo["id"]
                if repo_id in seen_repos:
                    continue
                seen_repos.add(repo_id)
                
                # Calculate relevance score
                score = calculate_relevance_score(repo, keywords)
                
                if score > 0:
                    results.append({
                        "source": "github",
                        "type": "repository",
                        "name": repo["full_name"],
                        "description": repo["description"],
                        "url": repo["html_url"],
                        "stars": repo["stargazers_count"],
                        "language": repo["language"],
                        "topics": repo.get("topics", []),
                        "updated_at": repo["updated_at"],
                        "relevance_score": score,
                        "crawled_at": datetime.utcnow().isoformat()
                    })
        except Exception as e:
            print(f"Error searching topic '{topic}': {e}", file=sys.stderr)
            continue
    
    # Sort by relevance score
    results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    return results


def get_trending_repos(language: str = None, since: str = "daily") -> List[Dict]:
    """
    Get trending repositories (using GitHub search as proxy)
    
    Args:
        language: Filter by language
        since: Time period (daily, weekly, monthly)
        
    Returns:
        List of trending repositories
    """
    creds = get_github_credentials()
    headers = {
        "Authorization": f"token {creds['token']}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    keywords = load_keywords()
    
    # Calculate date range
    if since == "daily":
        date_from = (datetime.utcnow() - timedelta(days=1)).strftime("%Y-%m-%d")
    elif since == "weekly":
        date_from = (datetime.utcnow() - timedelta(days=7)).strftime("%Y-%m-%d")
    else:  # monthly
        date_from = (datetime.utcnow() - timedelta(days=30)).strftime("%Y-%m-%d")
    
    # Search for recently updated repos with data-quality related keywords
    query_parts = [
        "data-quality OR data-validation OR data-testing",
        f"created:>={date_from}"
    ]
    if language:
        query_parts.append(f"language:{language}")
    
    query = " ".join(query_parts)
    
    try:
        url = "https://api.github.com/search/repositories"
        params = {
            "q": query,
            "sort": "stars",
            "order": "desc",
            "per_page": 10
        }
        
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        
        data = response.json()
        results = []
        
        for repo in data.get("items", []):
            score = calculate_relevance_score(repo, keywords)
            
            if score > 0:
                results.append({
                    "source": "github",
                    "type": "trending",
                    "name": repo["full_name"],
                    "description": repo["description"],
                    "url": repo["html_url"],
                    "stars": repo["stargazers_count"],
                    "language": repo["language"],
                    "topics": repo.get("topics", []),
                    "created_at": repo["created_at"],
                    "relevance_score": score,
                    "crawled_at": datetime.utcnow().isoformat()
                })
        
        return results
    except Exception as e:
        print(f"Error fetching trending repos: {e}", file=sys.stderr)
        return []


def main():
    """Main entry point"""
    config = load_config()
    github_config = config["sources"]["github"]
    
    if not github_config["enabled"]:
        print("GitHub crawler is disabled in config")
        return
    
    print(f"Crawling GitHub for {len(github_config['topics'])} topics...")
    
    # Search by topics
    results = search_repositories(
        topics=github_config["topics"],
        limit=github_config["limit"]
    )
    
    # Get trending repos
    trending = get_trending_repos(since=github_config["trending_period"])
    results.extend(trending)
    
    # Remove duplicates and sort
    seen = set()
    unique_results = []
    for r in results:
        if r["name"] not in seen:
            seen.add(r["name"])
            unique_results.append(r)
    
    unique_results.sort(key=lambda x: x["relevance_score"], reverse=True)
    
    # Filter by minimum score
    min_score = config["relevance"]["min_score"]
    filtered_results = [r for r in unique_results if r["relevance_score"] >= min_score]
    
    print(f"Found {len(unique_results)} repos, {len(filtered_results)} above threshold (>={min_score})")
    
    # Output as JSON
    print(json.dumps(filtered_results, indent=2))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Test script to verify Data QA Knowledge Curator setup
"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent))

from vault_helper import VaultHelper


def test_vault_connection():
    """Test Vault connectivity"""
    print("Testing Vault connection...")
    if VaultHelper.is_vault_available():
        print("  ✓ Vault is available and authenticated")
        return True
    else:
        print("  ✗ Vault is not available or not authenticated")
        print("  → Run: vault login")
        return False


def test_reddit_credentials():
    """Test Reddit credentials (optional)"""
    print("Testing Reddit credentials (optional)...")
    try:
        from vault_helper import get_reddit_credentials
        creds = get_reddit_credentials()
        required_keys = ["client_id", "client_secret", "user_agent"]
        
        for key in required_keys:
            if key not in creds:
                print(f"  ⚠️  Missing key: {key}")
                print("  Note: Reddit is optional (disabled by default)")
                return True  # Pass anyway
        
        print(f"  ✓ Reddit credentials found: {list(creds.keys())}")
        return True
    except Exception as e:
        print(f"  ⚠️  Reddit credentials not found (optional): {e}")
        print("  Note: Reddit is disabled by default due to API policy changes")
        return True  # Pass anyway since Reddit is optional


def test_twitter_credentials():
    """Test Twitter credentials"""
    print("Testing Twitter credentials...")
    try:
        from vault_helper import get_twitter_credentials
        creds = get_twitter_credentials()
        
        if "bearer_token" not in creds:
            print("  ✗ Missing bearer_token")
            return False
        
        print(f"  ✓ Twitter credentials found: {list(creds.keys())}")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def test_github_credentials():
    """Test GitHub credentials"""
    print("Testing GitHub credentials...")
    try:
        from vault_helper import get_github_credentials
        creds = get_github_credentials()
        
        if "token" not in creds:
            print("  ✗ Missing token")
            return False
        
        print(f"  ✓ GitHub credentials found: {list(creds.keys())}")
        return True
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False


def test_config_files():
    """Test configuration files"""
    print("Testing configuration files...")
    
    config_path = Path(__file__).parent.parent / "references" / "config.json"
    keywords_path = Path(__file__).parent.parent / "references" / "keywords.json"
    
    if not config_path.exists():
        print(f"  ✗ Missing config.json at {config_path}")
        return False
    
    if not keywords_path.exists():
        print(f"  ✗ Missing keywords.json at {keywords_path}")
        return False
    
    print("  ✓ Configuration files found")
    return True


def test_dependencies():
    """Test Python dependencies"""
    print("Testing Python dependencies...")
    
    missing = []
    
    try:
        import praw
        print("  ✓ praw (Reddit API)")
    except ImportError:
        print("  ✗ praw not installed")
        missing.append("praw")
    
    try:
        import requests
        print("  ✓ requests")
    except ImportError:
        print("  ✗ requests not installed")
        missing.append("requests")
    
    if missing:
        print(f"\n  → Install missing packages: pip install {' '.join(missing)}")
        return False
    
    return True


def main():
    """Run all tests"""
    print("=" * 60)
    print("Data QA Knowledge Curator - Setup Test")
    print("=" * 60)
    print()
    
    results = []
    
    results.append(("Vault Connection", test_vault_connection()))
    results.append(("Configuration Files", test_config_files()))
    results.append(("Python Dependencies", test_dependencies()))
    results.append(("Reddit Credentials", test_reddit_credentials()))
    results.append(("Twitter Credentials", test_twitter_credentials()))
    results.append(("GitHub Credentials", test_github_credentials()))
    
    print()
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    
    for name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status}: {name}")
    
    all_passed = all(passed for _, passed in results)
    
    print()
    if all_passed:
        print("✓ All tests passed! You're ready to run the crawler.")
        print()
        print("Next steps:")
        print("  1. Test individual crawlers:")
        print("     python scripts/crawl_reddit.py")
        print("     python scripts/crawl_twitter.py")
        print("     python scripts/crawl_github.py")
        print()
        print("  2. Run daily crawl:")
        print("     python scripts/daily_crawl.py")
        return 0
    else:
        print("✗ Some tests failed. Please fix the issues above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())

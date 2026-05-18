"""
Vault Helper - Read secrets from HashiCorp Vault
"""
import subprocess
import json
import os
from typing import Optional


class VaultHelper:
    """Helper class to read secrets from Vault"""
    
    @staticmethod
    def get_secret(path: str, key: str) -> str:
        """
        Read a secret from Vault
        
        Args:
            path: Vault path (e.g., "secret/data-qa-curator/reddit")
            key: Secret key (e.g., "client_id")
            
        Returns:
            Secret value as string
            
        Raises:
            Exception if secret cannot be read
        """
        try:
            result = subprocess.run(
                ["vault", "kv", "get", "-format=json", path],
                capture_output=True,
                text=True,
                check=True
            )
            data = json.loads(result.stdout)
            return data["data"]["data"][key]
        except subprocess.CalledProcessError as e:
            raise Exception(f"Failed to read {path}/{key} from Vault: {e.stderr}")
        except KeyError:
            raise Exception(f"Key '{key}' not found in {path}")
        except Exception as e:
            raise Exception(f"Error reading Vault secret: {e}")
    
    @staticmethod
    def get_all_secrets(path: str) -> dict:
        """
        Read all secrets from a Vault path
        
        Args:
            path: Vault path
            
        Returns:
            Dictionary of all secrets at that path
        """
        try:
            result = subprocess.run(
                ["vault", "kv", "get", "-format=json", path],
                capture_output=True,
                text=True,
                check=True
            )
            data = json.loads(result.stdout)
            return data["data"]["data"]
        except Exception as e:
            raise Exception(f"Failed to read {path} from Vault: {e}")
    
    @staticmethod
    def is_vault_available() -> bool:
        """Check if Vault CLI is available and authenticated"""
        try:
            result = subprocess.run(
                ["vault", "token", "lookup"],
                capture_output=True,
                text=True,
                check=True
            )
            return result.returncode == 0
        except:
            return False


# Convenience functions
def get_reddit_credentials() -> dict:
    """Get Reddit API credentials from Vault"""
    return VaultHelper.get_all_secrets("secret/data-qa-curator/reddit")


def get_twitter_credentials() -> dict:
    """Get Twitter API credentials from Vault"""
    return VaultHelper.get_all_secrets("secret/data-qa-curator/twitter")


def get_github_credentials() -> dict:
    """Get GitHub API credentials from Vault"""
    return VaultHelper.get_all_secrets("secret/data-qa-curator/github")


def get_openai_credentials() -> dict:
    """Get OpenAI API credentials from Vault"""
    return VaultHelper.get_all_secrets("secret/data-qa-curator/openai")


if __name__ == "__main__":
    # Test Vault connectivity
    if VaultHelper.is_vault_available():
        print("✓ Vault is available and authenticated")
        
        # Test reading secrets
        try:
            reddit = get_reddit_credentials()
            print(f"✓ Reddit credentials found: {list(reddit.keys())}")
        except Exception as e:
            print(f"✗ Reddit credentials: {e}")
        
        try:
            twitter = get_twitter_credentials()
            print(f"✓ Twitter credentials found: {list(twitter.keys())}")
        except Exception as e:
            print(f"✗ Twitter credentials: {e}")
        
        try:
            github = get_github_credentials()
            print(f"✓ GitHub credentials found: {list(github.keys())}")
        except Exception as e:
            print(f"✗ GitHub credentials: {e}")
        
        try:
            openai = get_openai_credentials()
            print(f"✓ OpenAI credentials found: {list(openai.keys())}")
        except Exception as e:
            print(f"✗ OpenAI credentials: {e}")
    else:
        print("✗ Vault is not available or not authenticated")
        print("Run: vault login")

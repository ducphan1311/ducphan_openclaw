#!/bin/bash
# setup_mobile_env.sh - Prepare macOS host for Mobile Development (Flutter + Android)
# This script installs Homebrew (if missing), Flutter, and Android Studio Cask.
# It is designed to be run by the user or the agent (with approval) to set up the build environment.

set -e

echo "Starting Mobile Environment Setup for macOS..."

# 1. Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Setup brew path for Apple Silicon / Intel
    if [ -d "/opt/homebrew/bin" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -d "/usr/local/bin" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# 2. Install dependencies via Homebrew
echo "Installing CocoaPods, Git, and other dependencies..."
brew install cocoapods git curl unzip
brew link --overwrite cocoapods

# 3. Install Android Studio and command line tools
echo "Installing Android Studio..."
brew install --cask android-studio

# 4. Install Flutter
if ! command -v flutter >/dev/null 2>&1; then
    echo "Installing Flutter SDK..."
    brew install --cask flutter
else
    echo "Flutter is already installed. Upgrading..."
    flutter upgrade
fi

# 5. Configure Android SDK Paths (Standard macOS locations)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Note: Android SDK components (platforms, build-tools) usually require accepting licenses.
# This requires Android Studio to be launched once or sdkmanager to be used.
echo "Accepting Android Licenses (may fail if SDK is not yet initialized via Android Studio)..."
yes | flutter doctor --android-licenses || echo "Please open Android Studio once to initialize the SDK, then run 'flutter doctor --android-licenses'."

# 6. Run Flutter Doctor
echo "Running flutter doctor..."
flutter doctor

echo "Setup script completed. Please ensure you add the following to your ~/.zshrc or ~/.bash_profile:"
echo "export ANDROID_HOME=\"\$HOME/Library/Android/sdk\""
echo "export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools\""

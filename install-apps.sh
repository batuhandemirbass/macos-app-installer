#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Checking for Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
    echo "📦 Homebrew is not installed. Installing now..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Homebrew'ü mevcut shell'e ekle (Apple Silicon için; Intel'de /usr/local kullanılır)
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed."
fi

# Burada cask adlarını 'brew search <isim>' ile kontrol edin:
apps=(
    slack
    google-chrome
    pritunl-client   # CLI/GUI cask adı
    asana
    microsoft-office
)

echo "🚀 Installing applications..."
for app in "${apps[@]}"; do
    if brew list --cask "$app" >/dev/null 2>&1; then
        echo "✅ $app is already installed."
    else
        echo "➤ Installing: $app"
        brew install --cask "$app"
    fi
done

echo "🎉 All applications have been installed successfully."

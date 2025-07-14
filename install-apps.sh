#!/bin/bash

echo "🔍 Checking for Homebrew..."

if ! command -v brew &> /dev/null
then
    echo "📦 Homebrew is not installed. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew is already installed."
fi

apps=(
  slack
  asana
  google-chrome
  pritunl
)

echo "🚀 Installing applications..."
for app in "${apps[@]}"
do
  echo "➤ Installing: $app"
  brew install --cask "$app"
done

echo "🎉 All applications have been installed successfully."

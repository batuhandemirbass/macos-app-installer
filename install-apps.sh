#!/bin/bash

echo "🔍 Homebrew kontrol ediliyor..."

if ! command -v brew &> /dev/null
then
    echo "📦 Homebrew yüklü değil. Yükleniyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew zaten yüklü."
fi

echo "➡️ Tap ekleniyor: homebrew/cask"
brew tap homebrew/cask

apps=(
  slack
  asana
  google-chrome
  pritunl
)

echo "🚀 Uygulamalar kuruluyor..."
for app in "${apps[@]}"
do
  echo "➤ Kuruluyor: $app"
  brew install --force "$app"
done

echo "🎉 Tüm uygulamalar başarıyla kuruldu."

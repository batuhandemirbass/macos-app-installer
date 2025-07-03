#!/bin/bash

echo "🔍 Homebrew kontrol ediliyor..."
if ! command -v brew &> /dev/null
then
    echo "📦 Homebrew yüklü değil. Yükleniyor..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew zaten yüklü."
fi

echo "🔄 Gerekirse tap yapılıyor..."
brew tap | grep homebrew/cask || brew tap homebrew/cask

apps=(
  slack
  asana
  google-chrome
  pritunl
  microsoft-office
)

echo "🚀 Uygulamalar kuruluyor..."
for app in "${apps[@]}"
do
  echo "➤ Kuruluyor: $app"
  brew install --force "$app" 2>/dev/null
done

echo "🎉 Tüm uygulamalar başarıyla kuruldu."

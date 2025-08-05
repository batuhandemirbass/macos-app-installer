#!/usr/bin/env bash
set -euo pipefail

# 1. Root kontrolü
if [ "$EUID" -eq 0 ]; then
  echo "❌ Lütfen bu betiği root olarak değil, normal kullanıcı olarak çalıştırın!" >&2
  exit 1
fi

# 2. Homebrew kurulumu
if ! command -v brew >/dev/null 2>&1; then
  echo "📦 Homebrew yüklü değil. Yükleniyor..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  # :contentReference[oaicite:0]{index=0}
  # Apple Silicon vs Intel tespiti ve PATH güncellemesi
  if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew zaten kurulu."
fi

# 3. Yüklenecek cask listesi
apps=(
  asana           # :contentReference[oaicite:1]{index=1}
  slack           # :contentReference[oaicite:2]{index=2}
  pritunl         # :contentReference[oaicite:3]{index=3}
  google-chrome   # :contentReference[oaicite:4]{index=4}
)

# 4. Uygulamaların kurulumu
echo "🚀 Uygulamalar yükleniyor..."
for app in "${apps[@]}"; do
  if brew list --cask "$app" >/dev/null 2>&1; then
    echo "✅ $app zaten yüklü."
  else
    echo "➤ $app kuruluyor..."
    brew install --cask "$app"
  fi
done

echo "🎉 Tüm uygulamalar başarıyla yüklendi."

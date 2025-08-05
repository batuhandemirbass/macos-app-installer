#!/bin/bash

# macOS Otomatik Uygulama Kurulum Betiği
# Bu betik Homebrew kullanarak Asana, Slack, Pritunl ve Google Chrome'u kurar

# Renkli çıktı için kodlar
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logo ve başlık
echo -e "${BLUE}"
echo "================================================"
echo "    macOS Otomatik Uygulama Kurulum Betiği"
echo "================================================"
echo -e "${NC}"

# Hata durumunda betiği durdur
set -e

# Log fonksiyonu
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[HATA] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[UYARI] $1${NC}"
}

info() {
    echo -e "${BLUE}[BİLGİ] $1${NC}"
}

# Homebrew kurulu mu kontrol et
check_homebrew() {
    log "Homebrew kontrolü yapılıyor..."
    
    if ! command -v brew &> /dev/null; then
        warning "Homebrew bulunamadı. Kuruluyor..."
        
        # Homebrew kurulumu
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # PATH'e ekle (Apple Silicon Mac'ler için)
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            # Intel Mac'ler için
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log "Homebrew başarıyla kuruldu!"
    else
        log "Homebrew zaten kurulu ✓"
    fi
}

# Homebrew'i güncelle
update_homebrew() {
    log "Homebrew güncelleniyor..."
    brew update
    log "Homebrew güncellendi ✓"
}

# Cask uygulamalarını kur
install_cask_apps() {
    local apps=("asana" "slack" "pritunl" "google-chrome")
    
    log "Cask uygulamaları kuruluyor..."
    
    for app in "${apps[@]}"; do
        info "Kuruluyor: $app"
        
        # Uygulama zaten kurulu mu kontrol et
        if brew list --cask | grep -q "^${app}$"; then
            warning "$app zaten kurulu, atlanıyor..."
            continue
        fi
        
        # Uygulamayı kur
        if brew install --cask "$app"; then
            log "$app başarıyla kuruldu ✓"
        else
            error "$app kurulumunda hata oluştu!"
            continue
        fi
    done
}

# Kurulum sonrası temizlik
cleanup() {
    log "Kurulum sonrası temizlik yapılıyor..."
    brew cleanup
    log "Temizlik tamamlandı ✓"
}

# Kurulu uygulamaları listele
list_installed_apps() {
    info "Kurulu cask uygulamaları:"
    echo ""
    brew list --cask | grep -E "(asana|slack|pritunl|google-chrome)" || warning "Belirtilen uygulamalardan hiçbiri kurulu değil"
    echo ""
}

# Ana fonksiyon
main() {
    log "Kurulum başlatılıyor..."
    echo ""
    
    # Sistem bilgisi
    info "Sistem: $(sw_vers -productName) $(sw_vers -productVersion)"
    info "Mimari: $(uname -m)"
    echo ""
    
    # Kullanıcıdan onay al
    echo -e "${YELLOW}Bu betik aşağıdaki uygulamaları kuracak:"
    echo "• Asana (Proje yönetimi)"
    echo "• Slack (İletişim)"
    echo "• Pritunl (VPN istemcisi)"
    echo "• Google Chrome (Web tarayıcısı)"
    echo ""
    read -p "Devam etmek istiyor musunuz? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Kurulum iptal edildi."
        exit 0
    fi
    
    echo ""
    
    # Kurulum adımları
    check_homebrew
    update_homebrew
    install_cask_apps
    cleanup
    
    echo ""
    log "Kurulum tamamlandı! 🎉"
    echo ""
    
    list_installed_apps
    
    info "Uygulamalar Launchpad'de veya Applications klasöründe bulunabilir."
    info "Bazı uygulamalar ilk açılışta ek izinler isteyebilir."
}

# Betik çalıştırılıyor mu kontrol et
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

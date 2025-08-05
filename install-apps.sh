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

# DNS ve bağlantı kontrolü
check_connectivity() {
    log "İnternet bağlantısı kontrol ediliyor..."
    
    # DNS sunucularını test et
    local dns_servers=("8.8.8.8" "1.1.1.1" "208.67.222.222")
    local working_dns=""
    
    for dns in "${dns_servers[@]}"; do
        if ping -c 1 -W 5000 "$dns" &> /dev/null; then
            working_dns="$dns"
            log "DNS sunucusu $dns çalışıyor ✓"
            break
        fi
    done
    
    if [[ -z "$working_dns" ]]; then
        error "İnternet bağlantısı bulunamadı!"
        exit 1
    fi
    
    # Homebrew API erişimini test et
    info "Homebrew API erişimi test ediliyor..."
    if ! curl -Is --connect-timeout 15 --max-time 30 https://formulae.brew.sh &> /dev/null; then
        warning "formulae.brew.sh'a erişim sorunu tespit edildi!"
        
        # DNS ayarlarını kaydet
        local current_dns=$(networksetup -getdnsservers Wi-Fi 2>/dev/null | head -1)
        info "Mevcut DNS: $current_dns"
        
        # DNS ayarlarını geçici olarak değiştir
        info "DNS ayarları Google DNS'e çevriliyor..."
        sudo networksetup -setdnsservers Wi-Fi 8.8.8.8 1.1.1.1
        
        # DNS cache'i temizle
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder
        
        # 10 saniye bekle
        info "DNS değişikliği için bekleniyor..."
        sleep 10
        
        # Tekrar test et
        if ! curl -Is --connect-timeout 15 --max-time 30 https://formulae.brew.sh &> /dev/null; then
            warning "Hala erişim sorunu var, alternatif DNS denenecek..."
            sudo networksetup -setdnsservers Wi-Fi 1.1.1.1 1.0.0.1
            sudo dscacheutil -flushcache
            sleep 5
            
            if ! curl -Is --connect-timeout 15 --max-time 30 https://formulae.brew.sh &> /dev/null; then
                error "Homebrew API'sine erişim sağlanamadı!"
                error "Lütfen manuel olarak aşağıdaki adımları deneyin:"
                echo "1. VPN bağlantınızı kontrol edin"
                echo "2. Güvenlik duvarı ayarlarınızı kontrol edin"
                echo "3. İnternet servis sağlayıcınızla iletişime geçin"
                exit 1
            fi
        fi
    fi
    
    log "Homebrew API erişimi başarılı ✓"
}

# Homebrew'in çalışma durumunu kontrol et
check_homebrew_health() {
    log "Homebrew sağlık kontrolü yapılıyor..."
    
    if command -v brew &> /dev/null; then
        # Homebrew doctor çalıştır
        info "Homebrew doctor çalıştırılıyor..."
        brew doctor || warning "Homebrew doctor bazı uyarılar verdi, ancak devam ediliyor..."
        
        # Homebrew config kontrol et
        info "Homebrew yapılandırması kontrol ediliyor..."
        brew config > /dev/null 2>&1 || warning "Homebrew config kontrolü başarısız"
        
        log "Homebrew sağlık kontrolü tamamlandı ✓"
    fi
}

# Homebrew kurulu mu kontrol et
check_homebrew() {
    log "Homebrew kontrolü yapılıyor..."
    
    if ! command -v brew &> /dev/null; then
        warning "Homebrew bulunamadı. Kuruluyor..."
        
        # Homebrew kurulumu (retry mekanizması ile)
        local max_attempts=3
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            info "Homebrew kurulum denemesi $attempt/$max_attempts"
            
            if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                break
            else
                if [[ $attempt -eq $max_attempts ]]; then
                    error "Homebrew kurulumu $max_attempts denemeden sonra başarısız oldu!"
                    exit 1
                fi
                warning "Kurulum başarısız, 10 saniye sonra tekrar denenecek..."
                sleep 10
                ((attempt++))
            fi
        done
        
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
    
    # Önce tap'ları güncelle
    info "Homebrew taps güncelleniyor..."
    brew tap --repair || warning "Tap repair başarısız oldu"
    
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        info "Homebrew güncelleme denemesi $attempt/$max_attempts"
        
        # HOMEBREW_NO_AUTO_UPDATE=1 kullanarak otomatik güncellemeyi devre dışı bırak
        if HOMEBREW_NO_AUTO_UPDATE=1 brew update --quiet; then
            log "Homebrew güncellendi ✓"
            return 0
        else
            if [[ $attempt -eq $max_attempts ]]; then
                warning "Homebrew güncellemesi başarısız!"
                info "Alternatif yöntem deneniyor..."
                
                # Homebrew cache'i temizle
                brew cleanup --prune=all
                rm -rf "$(brew --cache)"
                
                # Formulae reposu manuel güncelle
                info "Manuel repo güncelleme deneniyor..."
                if command -v git &> /dev/null; then
                    brew_repo_path=$(brew --repository)
                    if [[ -d "$brew_repo_path/.git" ]]; then
                        cd "$brew_repo_path" && git fetch --all && git reset --hard origin/master
                        log "Manuel güncelleme tamamlandı ✓"
                        return 0
                    fi
                fi
                
                warning "Güncelleeme atlanıyor, kuruluma devam ediliyor..."
                return 0
            fi
            warning "Güncelleme başarısız, 10 saniye sonra tekrar denenecek..."
            sleep 10
            ((attempt++))
        fi
    done
}

# Cask uygulamalarını kur
install_cask_apps() {
    local apps=("asana" "slack" "pritunl" "google-chrome")
    
    log "Cask uygulamaları kuruluyor..."
    
    # Cask tap'ını kontrol et
    info "Homebrew Cask kontrolü yapılıyor..."
    if ! brew tap | grep -q "homebrew/cask"; then
        info "Homebrew Cask tap'ı ekleniyor..."
        brew tap homebrew/cask || warning "Cask tap eklenemedi"
    fi
    
    for app in "${apps[@]}"; do
        info "Kuruluyor: $app"
        
        # Uygulama zaten kurulu mu kontrol et
        if brew list --cask 2>/dev/null | grep -q "^${app}$"; then
            warning "$app zaten kurulu, atlanıyor..."
            continue
        fi
        
        # Uygulamayı kur (retry mekanizması ile)
        local max_attempts=3
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            info "$app kurulum denemesi $attempt/$max_attempts"
            
            # Otomatik güncellemeyi devre dışı bırakarak kur
            if HOMEBREW_NO_AUTO_UPDATE=1 brew install --cask "$app" --no-quarantine 2>/dev/null; then
                log "$app başarıyla kuruldu ✓"
                break
            else
                if [[ $attempt -eq $max_attempts ]]; then
                    error "$app kurulumunda hata oluştu! (Tüm denemeler başarısız)"
                    warning "Bu uygulama manuel olarak kurulabilir: brew install --cask $app"
                    continue 2
                fi
                warning "$app kurulumu başarısız, 10 saniye sonra tekrar denenecek..."
                
                # Cache temizle
                brew cleanup
                sleep 10
                ((attempt++))
            fi
        done
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
    brew list --cask | grep -E "(asana|slack|pritunl|google-chrome|microsoft-office)" || warning "Belirtilen uygulamalardan hiçbiri kurulu değil"
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
    echo "• Microsoft Office"
    echo ""
    read -p "Devam etmek istiyor musunuz? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Kurulum iptal edildi."
        exit 0
    fi
    
    echo ""
    
    # Kurulum adımları
    check_connectivity
    check_homebrew
    check_homebrew_health
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

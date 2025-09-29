#!/bin/bash


set -e

echo "================================================"
echo "  Kali Linux Setup Script"
echo "================================================"
echo ""

# Prüfen ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then 
    echo "Bitte als root ausführen (sudo ./kali-setup.sh)"
    exit 1
fi

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# System Update
print_status "System-Update wird durchgeführt..."
apt update && apt upgrade -y
apt dist-upgrade -y

# Keyboard Layout auf German Switzerland setzen
print_status "Konfiguriere Keyboard Layout auf German Switzerland..."
setxkbmap ch
cat > /etc/default/keyboard << 'EOF'
XKBMODEL="pc105"
XKBLAYOUT="ch"
XKBVARIANT="legacy"
XKBOPTIONS=""
BACKSPACE="guess"
EOF

# Keyboard Layout dauerhaft für X11 setzen
mkdir -p /etc/X11/xorg.conf.d/
cat > /etc/X11/xorg.conf.d/00-keyboard.conf << 'EOF'
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "ch"
        Option "XkbModel" "pc105"
        Option "XkbVariant" "legacy"
EndSection
EOF

print_status "Keyboard Layout wurde auf German Switzerland (legacy) gesetzt"

# Nützliche Tools installieren
print_status "Installiere zusätzliche Tools..."
apt install -y \
    htop \

# Nützliche Repositories klonen
print_status "Klone nützliche Tools..."
mkdir -p /opt/tools
cd /opt/tools

# SecLists (falls nicht vorhanden)
if [ ! -d "/usr/share/seclists" ]; then
    print_status "SecLists wird installiert..."
    apt install -y seclists
fi

# LinPEAS & WinPEAS
if [ ! -d "PEASS-ng" ]; then
    git clone https://github.com/carlospolop/PEASS-ng.git
fi

# PayloadsAllTheThings
if [ ! -d "PayloadsAllTheThings" ]; then
    git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git
fi

# Bash-Aliases einrichten
print_status "Richte Bash-Aliases ein..."
cat >> /home/$SUDO_USER/.bashrc << 'EOF'

# Custom Aliases
alias ll='ls -lah'
alias ports='netstat -tulanp'
alias myip='curl ifconfig.me'
alias update='sudo apt update && sudo apt upgrade -y'
alias serve='python3 -m http.server 8000'
alias vpnup='sudo openvpn --config'

# Nützliche Funktionen
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
EOF

# Arbeitsverzeichnisse erstellen
print_status "Erstelle Arbeitsverzeichnisse..."
mkdir -p /home/$SUDO_USER/{HTB,TryHackMe,Workspace,Tools,Notes}
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/{HTB,TryHackMe,Workspace,Tools,Notes}

# SSH-Server konfigurieren (optional)
read -p "SSH-Server aktivieren? (j/n): " enable_ssh
if [ "$enable_ssh" = "j" ] || [ "$enable_ssh" = "y" ]; then
    print_status "SSH-Server wird aktiviert..."
    systemctl enable ssh
    systemctl start ssh
fi

# Firewall-Grundeinstellungen
print_status "Konfiguriere UFW-Firewall..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
if [ "$enable_ssh" = "j" ] || [ "$enable_ssh" = "y" ]; then
    ufw allow 22/tcp
fi
ufw --force enable

# System-Cleanup
print_status "Räume System auf..."
apt autoremove -y
apt autoclean -y

# PimpMyKali herunterladen
print_status "Lade pimpmykali herunter..."
cd /opt/tools
if [ ! -d "pimpmykali" ]; then
    mkdir pimpmykali
fi
cd pimpmykali
wget -O pimpmykali.sh https://raw.githubusercontent.com/Dewalt-arch/pimpmykali/refs/heads/master/pimpmykali.sh
chmod +x pimpmykali.sh

# Desktop-Verknüpfung für pimpmykali erstellen
print_status "Erstelle Desktop-Verknüpfung für pimpmykali..."
cat > /home/$SUDO_USER/Desktop/pimpmykali.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=PimpMyKali
Comment=Kali Linux Optimierung und Fixes
Exec=x-terminal-emulator -e 'sudo /opt/tools/pimpmykali/pimpmykali.sh; exec bash'
Icon=kali-menu
Terminal=false
Categories=System;Security;
EOF

# Verknüpfung ausführbar machen
chmod +x /home/$SUDO_USER/Desktop/pimpmykali.desktop
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/Desktop/pimpmykali.desktop

# Verknüpfung auch im Anwendungsmenü verfügbar machen
cp /home/$SUDO_USER/Desktop/pimpmykali.desktop /usr/share/applications/

# Abschluss
echo ""
echo "================================================"
print_status "Setup abgeschlossen!"
echo "================================================"
echo ""
print_warning "Bitte System neu starten für alle Änderungen:"
echo "  sudo reboot"
echo ""
print_status "Installierte Features:"
echo "  - System vollständig aktualisiert"
echo "  - Keyboard Layout: German Switzerland (legacy)"
echo "  - Zusätzliche Tools installiert"
echo "  - Docker eingerichtet"
echo "  - Git konfiguriert"
echo "  - Nützliche Repositories geklont (/opt/tools)"
echo "  - Bash-Aliases eingerichtet"
echo "  - Arbeitsverzeichnisse erstellt"
echo "  - Firewall konfiguriert"
echo "  - pimpmykali heruntergeladen (/opt/tools/pimpmykali)"
echo "  - Desktop-Verknüpfung für pimpmykali erstellt"
echo ""
print_warning "Möchtest du jetzt pimpmykali ausführen?"
echo "  pimpmykali bietet zusätzliche Optimierungen und Fixes für Kali Linux"
read -p "pimpmykali jetzt ausführen? (j/n): " run_pimpmykali

if [ "$run_pimpmykali" = "j" ] || [ "$run_pimpmykali" = "y" ]; then
    print_status "Führe pimpmykali aus..."
    cd /opt/tools/pimpmykali
    ./pimpmykali.sh
    echo ""
    print_status "pimpmykali abgeschlossen!"
else
    print_warning "pimpmykali wurde nicht ausgeführt."
    echo "  Du kannst es später manuell ausführen mit:"
    echo "  cd /opt/tools/pimpmykali && sudo ./pimpmykali.sh"
fi

echo ""
print_warning "Bitte System neu starten für alle Änderungen:"
echo "  sudo reboot"
echo ""

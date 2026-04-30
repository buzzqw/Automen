#!/usr/bin/env bash
# =============================================================================
#  AutoMen v8 - Setup Script
#  Installa dipendenze Python e tool di codifica video
#  Supporta: Debian/Ubuntu · Fedora/RHEL · Arch Linux · openSUSE
# =============================================================================

set -euo pipefail

# ── Colori ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }
info() { echo -e "${BLUE}[→]${NC} $*"; }
hdr()  { echo -e "\n${BOLD}$*${NC}"; }

# ── Rilevamento distribuzione ──────────────────────────────────────────────────
detect_distro() {
    if   [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="${ID,,}"         # lowercase
        DISTRO_LIKE="${ID_LIKE,,}"
    elif [ -f /etc/redhat-release ]; then
        DISTRO_ID="rhel"
        DISTRO_LIKE="rhel"
    else
        DISTRO_ID="unknown"
        DISTRO_LIKE=""
    fi

    if   [[ "$DISTRO_ID" =~ ^(debian|ubuntu|linuxmint|pop|elementary|zorin|kali)$ ]] \
      || [[ "$DISTRO_LIKE" =~ debian ]]; then
        FAMILY="debian"
    elif [[ "$DISTRO_ID" =~ ^(fedora|rhel|centos|almalinux|rocky|ol)$ ]] \
      || [[ "$DISTRO_LIKE" =~ (rhel|fedora) ]]; then
        FAMILY="fedora"
    elif [[ "$DISTRO_ID" =~ ^(arch|manjaro|endeavouros|garuda|artix)$ ]] \
      || [[ "$DISTRO_LIKE" =~ arch ]]; then
        FAMILY="arch"
    elif [[ "$DISTRO_ID" =~ ^(opensuse|sles|sled)$ ]] \
      || [[ "$DISTRO_LIKE" =~ suse ]]; then
        FAMILY="suse"
    else
        FAMILY="unknown"
    fi
}

# ── Controllo root/sudo ────────────────────────────────────────────────────────
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
    elif command -v sudo &>/dev/null; then
        SUDO="sudo"
        info "Verrà usato sudo per i comandi di sistema"
    else
        err "Questo script richiede root o sudo"
        exit 1
    fi
}

# ── Installatori per famiglia ──────────────────────────────────────────────────
install_debian() {
    hdr "=== Debian / Ubuntu ==="
    info "Aggiornamento indice pacchetti..."
    $SUDO apt-get update -qq

    # Abilita repository universe/contrib se non già attivi (Ubuntu/Debian)
    if command -v add-apt-repository &>/dev/null; then
        $SUDO add-apt-repository -y universe 2>/dev/null || true
        $SUDO add-apt-repository -y multiverse 2>/dev/null || true
    fi
    # Riabilita non-free su Debian
    if [ -f /etc/debian_version ] && ! grep -q "non-free" /etc/apt/sources.list 2>/dev/null; then
        warn "Su Debian potresti dover aggiungere 'non-free' alle sources per alcuni codec"
    fi

    PKG_PYTHON="python3 python3-pip python3-pyqt6 python3-pyqt6.qtmultimedia"
    PKG_CORE="ffmpeg mencoder mkvtoolnix gpac"
    PKG_AUDIO="lame vorbis-tools flac faac aften"
    PKG_X264="x264"
    PKG_X265="x265"
    PKG_EXTRA="mplayer xterm"

    for group in PKG_PYTHON PKG_CORE PKG_AUDIO PKG_X264 PKG_X265 PKG_EXTRA; do
        info "Installazione ${group}..."
        # shellcheck disable=SC2086
        $SUDO apt-get install -y --no-install-recommends ${!group} 2>/dev/null \
            || warn "Alcuni pacchetti di ${group} non disponibili — continuo"
    done
}

install_fedora() {
    hdr "=== Fedora / RHEL / CentOS ==="

    # Abilita RPM Fusion (necessario per ffmpeg, x264, x265, lame, ecc.)
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        info "Abilitazione RPM Fusion Free..."
        $SUDO dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            2>/dev/null || warn "RPM Fusion non installato — alcuni codec potrebbero mancare"
    fi
    if ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
        info "Abilitazione RPM Fusion Non-Free..."
        $SUDO dnf install -y \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
            2>/dev/null || warn "RPM Fusion Non-Free non installato"
    fi

    PKG_PYTHON="python3 python3-pip python3-pyqt6"
    PKG_CORE="ffmpeg mkvtoolnix gpac"
    PKG_AUDIO="lame vorbis-tools flac aften"
    PKG_X264="x264"
    PKG_X265="x265"
    PKG_EXTRA="mplayer xterm"
    # mencoder non è in RPM Fusion da Fedora 36+
    PKG_MENCODER="mencoder"

    for group in PKG_PYTHON PKG_CORE PKG_AUDIO PKG_X264 PKG_X265 PKG_MENCODER PKG_EXTRA; do
        info "Installazione ${group}..."
        # shellcheck disable=SC2086
        $SUDO dnf install -y ${!group} 2>/dev/null \
            || warn "Alcuni pacchetti di ${group} non disponibili"
    done
}

install_arch() {
    hdr "=== Arch Linux / Manjaro ==="

    # Aggiorna db
    info "Sincronizzazione database pacchetti..."
    $SUDO pacman -Sy --noconfirm 2>/dev/null || true

    PKG_OFFICIAL="python python-pip python-pyqt6 ffmpeg mkvtoolnix-cli gpac \
                  lame vorbis-tools flac x264 x265 xterm"
    # mencoder e faac sono su AUR
    PKG_AUR="mencoder faac aften"

    info "Installazione pacchetti ufficiali..."
    # shellcheck disable=SC2086
    $SUDO pacman -S --noconfirm --needed $PKG_OFFICIAL 2>/dev/null \
        || warn "Alcuni pacchetti ufficiali non installati"

    # AUR: usa yay o paru se disponibili
    AUR_HELPER=""
    for h in yay paru pikaur; do
        if command -v "$h" &>/dev/null; then AUR_HELPER="$h"; break; fi
    done

    if [ -n "$AUR_HELPER" ]; then
        info "Installazione pacchetti AUR con $AUR_HELPER..."
        # shellcheck disable=SC2086
        $AUR_HELPER -S --noconfirm --needed $PKG_AUR 2>/dev/null \
            || warn "Alcuni pacchetti AUR non installati"
    else
        warn "Nessun AUR helper trovato (yay/paru). Pacchetti AUR saltati: $PKG_AUR"
        warn "Installa yay e riesegui, oppure installa manualmente da https://aur.archlinux.org"
    fi

    # mplayer da AUR
    if [ -n "$AUR_HELPER" ]; then
        $AUR_HELPER -S --noconfirm --needed mplayer 2>/dev/null || true
    else
        $SUDO pacman -S --noconfirm --needed mplayer 2>/dev/null || true
    fi
}

install_suse() {
    hdr "=== openSUSE ==="

    # Abilita Packman (codec non-free)
    if ! zypper repos 2>/dev/null | grep -qi packman; then
        info "Aggiunta repository Packman..."
        SUSE_VER=$(. /etc/os-release && echo "$VERSION_ID")
        if [[ "$DISTRO_ID" == *"tumbleweed"* ]]; then
            $SUDO zypper ar -cfp 90 \
                "https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/" \
                packman 2>/dev/null || warn "Packman non aggiunto"
        else
            $SUDO zypper ar -cfp 90 \
                "https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_${SUSE_VER}/" \
                packman 2>/dev/null || warn "Packman non aggiunto"
        fi
        $SUDO zypper --gpg-auto-import-keys refresh 2>/dev/null || true
    fi

    PKG_ALL="python3 python3-pip python3-qt6 ffmpeg mkvtoolnix gpac \
             lame vorbis-tools flac x264 x265 mencoder mplayer xterm"

    info "Installazione pacchetti..."
    # shellcheck disable=SC2086
    $SUDO zypper install -y --no-recommends $PKG_ALL 2>/dev/null \
        || warn "Alcuni pacchetti non disponibili"
}

# ── Installazione PyQt6 via pip (fallback se non disponibile nei repo) ─────────
install_pyqt6_pip() {
    hdr "Verifica PyQt6..."
    if python3 -c "import PyQt6" &>/dev/null; then
        ok "PyQt6 già disponibile"
        return
    fi
    warn "PyQt6 non trovato nei pacchetti di sistema, installazione via pip..."
    if [ "$FAMILY" = "debian" ]; then
        # Debian/Ubuntu recenti richiedono --break-system-packages o venv
        python3 -m pip install --break-system-packages PyQt6 2>/dev/null \
            || python3 -m pip install PyQt6
    else
        python3 -m pip install PyQt6
    fi
    python3 -c "import PyQt6" && ok "PyQt6 installato via pip" \
        || err "PyQt6 non installabile — installa manualmente"
}

# ── Verifica finale tool ───────────────────────────────────────────────────────
check_tools() {
    hdr "Verifica tool installati:"
    local all_ok=true

    check_one() {
        local name="$1"; shift
        if command -v "$1" &>/dev/null; then
            ok "$name → $(command -v "$1")"
        else
            warn "$name → NON TROVATO (opzionale)"
            all_ok=false
        fi
    }

    check_one "python3"     python3
    check_one "PyQt6"       python3   # verificato sotto
    check_one "ffmpeg"      ffmpeg
    check_one "mencoder"    mencoder
    check_one "x264"        x264
    check_one "x265"        x265
    check_one "mkvmerge"    mkvmerge
    check_one "MP4Box"      MP4Box
    check_one "lame"        lame
    check_one "oggenc"      oggenc
    check_one "flac"        flac
    check_one "aften"       aften
    check_one "mplayer"     mplayer
    check_one "xterm"       xterm

    # PyQt6 speciale
    if python3 -c "import PyQt6" &>/dev/null; then
        VER=$(python3 -c "import PyQt6.QtCore; print(PyQt6.QtCore.PYQT_VERSION_STR)" 2>/dev/null || echo "?")
        ok "PyQt6 → versione $VER"
    else
        err "PyQt6 → NON DISPONIBILE — AutoMen non funzionerà"
        all_ok=false
    fi

    # Verifica libx265 in ffmpeg
    if command -v ffmpeg &>/dev/null; then
        if ffmpeg -encoders 2>/dev/null | grep -q libx265; then
            ok "ffmpeg libx265 → disponibile"
        else
            warn "ffmpeg libx265 → NON compilato (X265 non disponibile con FFmpeg)"
        fi
    fi

    echo ""
    if $all_ok; then
        ok "Tutti i tool principali sono disponibili!"
    else
        warn "Alcuni tool opzionali mancano. AutoMen funzionerà con le funzioni disponibili."
    fi
}

# ── Crea launcher desktop opzionale ───────────────────────────────────────────
create_launcher() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DESKTOP_FILE="$HOME/.local/share/applications/automen.desktop"

    if [ ! -f "$SCRIPT_DIR/automen.py" ]; then
        warn "automen.py non trovato in $SCRIPT_DIR — launcher non creato"
        return
    fi

    mkdir -p "$HOME/.local/share/applications"
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=AutoMen
Comment=Video Encoding Frontend
Exec=python3 $SCRIPT_DIR/automen.py
Icon=video-x-generic
Terminal=false
Categories=AudioVideo;Video;Encoding;
EOF
    ok "Launcher desktop creato: $DESKTOP_FILE"
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}"
    echo "╔══════════════════════════════════════╗"
    echo "║     AutoMen v8 — Setup Script        ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"

    detect_distro
    check_sudo

    info "Distribuzione rilevata: ${DISTRO_ID} (famiglia: ${FAMILY})"
    echo ""

    case "$FAMILY" in
        debian) install_debian ;;
        fedora) install_fedora ;;
        arch)   install_arch   ;;
        suse)   install_suse   ;;
        *)
            err "Distribuzione non riconosciuta: $DISTRO_ID"
            err "Installa manualmente: python3 python3-pyqt6 ffmpeg mencoder x264 x265"
            err "                      mkvtoolnix gpac lame vorbis-tools flac mplayer xterm"
            exit 1
            ;;
    esac

    install_pyqt6_pip
    check_tools
    create_launcher

    echo ""
    echo -e "${BOLD}${GREEN}Setup completato!${NC}"
    echo -e "Avvia AutoMen con:  ${BOLD}python3 automen.py${NC}"
    echo ""
}

main "$@"

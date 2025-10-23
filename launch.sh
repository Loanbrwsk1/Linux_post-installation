#! /bin/bash

# Based on the repo of aaaaadrien : https://github.com/aaaaadrien/linux-postinst

SYSLANG=${LANG:0:2}
if [[ $SYSLANG == "fr" ]]
then
    ERROR="Erreur"
    UPDATE_SOURCE="Update des sources"
    UPGRADE_SYSTEM="Upgrade du système"
    YES_OR_NO="[O/n] "
    FLAT_COMP="Voulez-vous Flatpak et le dépôt Flathub ?"
    INSTALL_FLATPAK="Installation de Flatpak"
    INSTALL_FLATHUB="Installation de Flathub"
    NONFREE="Voulez-vous le dépôt non libre ?"
elif [[ $SYSLANG == "en" ]]
then
    ERROR="Error"
    UPDATE_SOURCE="Sources update"
    UPGRADE_SYSTEM="System upgrade"
    YES_OR_NO="[Y/n] "
    FLAT_COMP="Do you want Flatpak and Flathub repo ?"
    NONFREE="Do you want non-free components ?"
fi

### THANKS FLASHBIOS ###
RED=$(tput setaf 1) # Rouge
GREEN=$(tput setaf 2) # Vert
YELLOW=$(tput setaf 3) # Jaune
GREY=$(tput setaf 7) # Gris
BOLD=$(tput bold)
NC=$(tput sgr0)

function spinner() {
    local pid=$1
    local msg=$2
    local delay=0.1
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame_index=0
    local spinner_length=4
    local total_length=$((spinner_length + ${#msg}))
    while kill -0 "$pid" 2> /dev/null; do
        printf "\r[%s] %s" "${frames[frame_index]}" "$msg"
        frame_index=$(( (frame_index + 1) % ${#frames[@]} ))
        sleep $delay
        printf "\b%.0s" $(seq 1 $total_length)
    done
    printf "\r\033[K"
}

function run_with_spinner() {
    local cmd="$1"
    local msg="$2"
    eval "$cmd" &
    local pid=$!
    spinner $pid "$msg"
    wait $pid
    return $?
} 

info() {
    printf '%s\n' "${BOLD}${GREY}>${NC} $*"
}

success() {
    printf '%s\n' "${GREEN}✓ $*${NC}"
}

warn() {
    printf '%s\n' "${YELLOW}! $*${NC}"
}

error() {
    printf '%s\n' "${RED}x $*${NC}"
}
### END THANKS FLASHBIOS ###


#? Detect root
if [[ "$EUID" -ne 0 ]]
then
	echo "Erreur : Vous devez lancer en tant que root !"
	exit 1
fi

#? Detect distrib
DIST="$(source /etc/os-release; echo "$ID")"

#? Actions distrib
case "$DIST" in
	fedora)
        read -rp "$FLAT_COMP $YES_OR_NO " REPONSE_FLAT
        REPONSE_FLAT=${REPONSE:-y}

        read -rp "$NONFREE $YES_OR_NO " REPONSE_NONFREE
        REPONSE_NONFREE=${REPONSE:-y}

		(run_with_spinner "dnf -y --refresh upgrade > /dev/null 2>&1" "$UPGRADE_SYSTEM" && success "$UPGRADE_SYSTEM") || error "$ERROR $UPGRADE_SYSTEM"

        if [ "$REPONSE_FLAT" ] || [ "$REPONSE_FLAT" = "y" ] || [ "$REPONSE_FLAT" = "Y" ] || [ "$REPONSE_FLAT" = "o" ] || [ "$REPONSE_FLAT" = "O" ]; then
            (run_with_spinner "dnf install -y flatpak > /dev/null 2>&1" "$INSTALL_FLATPAK" && success "$INSTALL_FLATPAK") || error "$ERROR $INSTALL_FLATPAK"
            (run_with_spinner "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo > /dev/null 2>&1" "$INSTALL_FLATHUB" && success "$INSTALL_FLATHUB") || error "$ERROR $INSTALL_FLATHUB"
        fi
        if [ "$REPONSE_NONFREE" ] || [ "$REPONSE_NONFREE" = "y" ] || [ "$REPONSE_NONFREE" = "Y" ] || [ "$REPONSE_NONFREE" = "o" ] || [ "$REPONSE_NONFREE" = "O" ]; then
            echo "nonfree"
        fi
        #RPM Fusion
			#GNOME Logiciels/Discover : appstream
			#Codec ?
	;;
	ubuntu)
        read -rp "$FLAT_COMP $YES_OR_NO " REPONSE_FLAT
        REPONSE_FLAT=${REPONSE:-y}

        read -rp "$NONFREE $YES_OR_NO " REPONSE_NONFREE
        REPONSE_NONFREE=${REPONSE:-y}

		(run_with_spinner "apt update > /dev/null 2>&1" "$UPDATE_SOURCE" && success "$UPDATE_SOURCE") || error "$ERROR : $UPDATE_SOURCE"
		(run_with_spinner "apt -y full-upgrade > /dev/null 2>&1" "$UPGRADE_SYSTEM" && success "$UPGRADE_SYSTEM") || error "$ERROR : $UPGRADE_SYSTEM"

        if [ "$REPONSE_FLAT" ] || [ "$REPONSE_FLAT" = "y" ] || [ "$REPONSE_FLAT" = "Y" ] || [ "$REPONSE_FLAT" = "o" ] || [ "$REPONSE_FLAT" = "O" ]; then
            (run_with_spinner "apt install -y flatpak > /dev/null 2>&1" "$INSTALL_FLATPAK" && success "$INSTALL_FLATPAK") || error "$ERROR $INSTALL_FLATPAK"
            (run_with_spinner "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo > /dev/null 2>&1" "$INSTALL_FLATHUB" && success "$INSTALL_FLATHUB") || error "$ERROR $INSTALL_FLATHUB"
        fi
	;;
	*)
		echo "Distribution non supportée"
		exit 1
        ;;
esac


#! /bin/bash

# Based on the repo of aaaaadrien : https://github.com/aaaaadrien/linux-postinst

LOGFILE="/tmp/config-progress.log"

install_by_flatpak=false

SYSLANG=${LANG:0:2}
if [[ $SYSLANG == "fr" ]] ; then
    ERROR="Erreur"
    ERROR_ROOT="vous devez lancer le script avec sudo !"
    LOGS="Vous pouvez voir les logs en exécutant dans un autre terminal : tails -f /tmp/config-progress.log"
    UPDATE_SOURCE="Update des sources"
    UPGRADE_SYSTEM="Upgrade du système"
    YES_NO="[O/n] "
    FLAT_COMP="Voulez-vous Flatpak et le dépôt Flathub ?"
    INSTALL_FLATPAK="Installation de Flatpak"
    INSTALL_FLATHUB="Installation de Flathub"
    RPM_FUSION_FREE_INSTALL="Installation de RPM Fusion Free"
    NONFREE="Voulez-vous le dépôt non libre ?"
    RPM_FUSION_NON_FREE_INSTALL="Installation de RPM Fusion Non-Free"
    CODECS_INSTALL="Installation des codecs"
    DOCK="Voulez-vous avoir un dock sur le bureau ?"
    DOCK_INSTALL="Installation du dock"
    DOCK_ACTIVATION="Activation du dock"
    GNOME_TWEAKS_INSTALL="Installation de Gnome tweaks"
    NVIDIA="Avez-vous une carte graphique NVIDIA ?"
    NVIDIA_INSTALL="Installation des pilotes NVIDIA avec ubuntu-drivers autoinstall"
    WINDOW_BUTTONS="Activation des boutons de fenêtres"
    WALLPAPERS="Voulez-vous des fonds d'écran supplémentaires (~5,1 Go) ?"
    WALLPAPERS_DOWNLOAD="Téléchargement des fonds d'écran"
    DYN_WALLPAPERS="Voulez-vous des fonds d'écran dynamiques supplémentaires (2,5 Go) ?"
    DYN_WALLPAPERS_DOWNLOAD="Téléchargement des fonds d'écran dynamiques"
    WALLPAPERS_INFO="Vous retrouverez les fonds d'écran dans votre dossier Images"
    WALLPAPERS_INFO_GNOME="Vous pouvez changer de fond d'écran dans les paramètres"
    DYN_WALLPAPERS_INFO="Vous retrouverez les aperçus des fonds d'écran dynamiques dans votre dossier Images. Pour les appliquer, aller dans les Paramètres pour changer le fond d'écran"
    ERR_DISTRO="non supporté"
    DOWNLOAD_DIR="Téléchargements"
    PICTURES_DIR="Images"
elif [[ $SYSLANG == "en" ]] ; then
    ERROR="Error"
    ERROR_ROOT="Error : you should launch the script with sudo !"
    LOGS="You can see the logs by executing in an other terminal : tail -f /tmp/config-progress.log"
    UPDATE_SOURCE="Sources update"
    UPGRADE_SYSTEM="System upgrade"
    YES_NO="[Y/n] "
    FLAT_COMP="Do you want Flatpak and Flathub repo ?"
    RPM_FUSION_FREE_INSTALL="Installation of RPM Fusion Free"
    NONFREE="Do you want non-free components ?"
    RPM_FUSION_NON_FREE_INSTALL="Installation of RPM Fusion Non-Free"
    CODECS_INSTALL="Installation of codecs"
    DOCK="Do you want to have a dock on the desktop ?"
    DOCK_INSTALL="Installation of the dock"
    DOCK_ACTIVATION="Activation of the dock"
    GNOME_TWEAKS_INSTALL="Installation of Gnome tweaks"
    NVIDIA="Do you have a graphic card NVIDIA ?"
    NVIDIA_INSTALL="Installation of NVIDIA pilots with ubuntu-drivers autoinstall"
    WINDOW_BUTTONS="Activation of window buttons"
    WALLPAPERS="Do you want additional wallpapers (~5.1 GB) ?"
    WALLPAPERS_DOWNLOAD="Downloading of wallpapers"
    DYN_WALLPAPERS="Do you want additional dynamic wallpapers (2.5 GB) ?"
    DYN_WALLPAPERS_DOWNLOAD="Downloading os dynamic wallpapers"
    WALLPAPERS_INFO="You will find the wallpapers in your Pictures directory"
    WALLPAPERS_INFO_GNOME="You can now change your wallpaper in the settings"
    DYN_WALLPAPERS_INFO="You wille find the overviews of the dynamic wallpepers in your Pictures directory. To apply them, go in Settings to change the wallpaper"
    ERR_DISTRO="non supported"
    DOWNLOAD_DIR="Downloads"
    PICTURES_DIR="Pictures"
fi

### THANKS FLASHBIOS ###
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
GREY=$(tput setaf 7)
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
	error "$ERROR $ERROR_ROOT"
	exit 1
fi

#? Functions
wallpapers() {
    if [ "$ANSWER_WALLPAPERS" == "y" ] || [ "$ANSWER_WALLPAPERS" == "Y" ] || [ "$ANSWER_WALLPAPERS" == "o" ] || [ "$ANSWER_WALLPAPERS" == "O" ] ; then
        cd /home/$USERNAME/$DOWNLOAD_DIR
        (run_with_spinner "git clone https://github.com/Loanbrwsk1/Wallpapers.git >> $LOGFILE" "$WALLPAPERS_DOWNLOAD" && success "$WALLPAPERS_DOWNLOAD") || error "$ERROR $WALLPAPERS_DOWNLOAD"
        cd Wallpapers
        if [ "$DE" == "GNOME" ] ; then
            mv ./wallpapers/* ~/.local/share/backgrounds/
            info "$WALLPAPERS_INFO_GNOME"
        else
            cp -r ./wallpapers/ ~/$PICTURES_DIR/
            info "$WALLPAPERS_INFO"
        fi
        cd ..
        rm -fr Wallpapers
    fi

    if [ "$ANSWER_DYN_WALLPAPERS" == "y" ] || [ "$ANSWER_DYN_WALLPAPERS" == "Y" ] || [ "$ANSWER_DYN_WALLPAPERS" == "o" ] || [ "$ANSWER_WALLPAPERS" == "O" ] ; then
        cd /home/$USERNAME/$DOWNLOAD_DIR
        (run_with_spinner "git clone https://github.com/Loanbrwsk1/Dynamic-wallpapers.git >> $LOGFILE" "$DYN_WALLPAPERS_DOWNLOAD" && success "$DYN_WALLPAPERS_DOWNLOAD") || error "$ERROR $DYN_WALLPAPERS_DOWNLOAD"
        cd ./Dynamic-wallpapers/
        mv ./Dynamic_Wallpapers/ /usr/share/backgrounds/
        if [ "$DE" == "GNOME" ] ; then
            mv ./xml/* /usr/share/gnome-background-properties/
        elif [ "$DE" == "CINNAMON" ] ; then
            mv ./xml/* /usr/share/cinnamon-background-properties/
        fi
        mv ./Screenshots_dynamic_wallpapers/ ~/Images/
        cd ..
        rm -rf ./Dynamic-wallpapers/
        info "$DYN_WALLPAPERS_INFO"
    fi
}

#? Detect distro
DIST="$(source /etc/os-release; echo "$ID")"
DE="$XDG_CURRENT_DESKTOP"

#? Actions distro
fedora() {
    info "$LOGS"
    read -rp "$FLAT_COMP $YES_NO " ANSWER_FLAT
    if [[ $ANSWER_FLAT == "" ]] ; then
        ANSWER_FLAT=${REPONSE:-y}
    fi

    read -rp "$NONFREE $YES_NO " ANSWER_NONFREE
    if [[ $ANSWER_NONFREE == "" ]] ; then
        ANSWER_NONFREE=${REPONSE:-y}
    fi

    read -rp "$DOCK $YES_NO " ANSWER_DOCK
    if [[ $ANSWER_DOCK == "" ]] ; then
        ANSWER_DOCK=${REPONSE:-y}
    fi

    read -rp "$WALLPAPERS" ANSWER_WALLPAPERS
    if [[ $ANSWER_WALLPAPERS == "" ]] ; then
        ANSWER_WALLPAPERS=${REPONSE:-y}
    fi

    ANSWER_DYN_WALLPAPERS=${REPONSE:-n}
    if [ "$DE" == "GNOME" ] || [ "$DE" == "CINNAMON" ] ; then
        read -rp "$DYN_WALLPAPERS" ANSWER_DYN_WALLPAPERS
        if [[ $ANSWER_DYN_WALLPAPERS == "" ]] ; then
            ANSWER_DYN_WALLPAPERS=${REPONSE:-y}
        fi
    fi

    (run_with_spinner "dnf -y --refresh upgrade >> $LOGFILE" "$UPGRADE_SYSTEM" && success "$UPGRADE_SYSTEM") || error "$ERROR $UPGRADE_SYSTEM"

    if [ "$ANSWER_FLAT" == "y" ] || [ "$ANSWER_FLAT" == "Y" ] || [ "$ANSWER_FLAT" == "o" ] || [ "$ANSWER_FLAT" == "O" ] ; then
        (run_with_spinner "dnf install -y flatpak >> $LOGFILE" "$INSTALL_FLATPAK" && success "$INSTALL_FLATPAK") || error "$ERROR $INSTALL_FLATPAK"
        (run_with_spinner "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> $LOGFILE" "$INSTALL_FLATHUB" && success "$INSTALL_FLATHUB") || error "$ERROR $INSTALL_FLATHUB"
        install_by_flatpak=true
    fi

    (run_with_spinner "dnf install -y 'https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm' 'https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm' >> $LOGFILE" "$RPM_FUSION_FREE_INSTALL" && success "$RPM_FUSION_FREE_INSTALL") || error "$ERROR $RPM_FUSION_FREE_INSTALL"
    if [ "$ANSWER_NONFREE" == "y" ] || [ "$ANSWER_NONFREE" == "Y" ] || [ "$ANSWER_NONFREE" == "o" ] || [ "$ANSWER_NONFREE" == "O" ] ; then
        (run_with_spinner "dnf install -y 'https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm' 'https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm' >> $LOGFILE" "$RPM_FUSION_NON_FREE_INSTALL" && success "$RPM_FUSION_NON_FREE_INSTALL") || error "$ERROR $RPM_FUSION_NON_FREE_INSTALL"
    fi
    
    (run_with_spinner "dnf install -y libavcodec-freeworld >> $LOGFILE" "$CODECS_INSTALL" && success "$CODECS_INSTALL") || error "$ERROR $CODECS_INSTALL"

    if [ "$DE" == "GNOME" ] && { [ "$ANSWER_DOCK" == "y" ] || [ "$ANSWER_DOCK" == "Y" ] || [ "$ANSWER_DOCK" == "o" ] || [ "$ANSWER_DOCK" == "O" ]; } ; then
        (run_with_spinner "dnf install -y gnome-shell-extension-dash-to-dock >> $LOGFILE" "$DOCK_INSTALL" && success "$DOCK_INSTALL") || error "$ERROR $DOCK_INSTALL"
        (run_with_spinner "gnome-extensions enable dash-to-dock@micxgx.gmail.com >> $LOGFILE" "$DOCK_ACTIVATION" && success "$DOCK_ACTIVATION") || error "$ERROR $DOCK_ACTIVATION"
    fi

    if [ "$DE" == "GNOME" ] ; then
        (run_with_spinner "dnf install -y gnome-tweaks >> $LOGFILE" "$GNOME_TWEAKS_INSTALL" && success "$GNOME_TWEAKS_INSTALL") || error "$ERROR $GNOME_TWEAKS_INSTALL"
        (run_with_spinner "gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' >> $LOGFILE" "$WINDOW_BUTTONS" && success "$WINDOW_BUTTONS") || error "$ERROR $WINDOW_BUTTONS"
        if [ $install_by_flatpak == true ] ; then
            (run_with_spinner "flatpak install -y flathub com.mattjakeman.ExtensionManager >> $LOGFILE" "$GNOME_TWEAKS_INSTALL" && success "$GNOME_TWEAKS_INSTALL") || error "$ERROR $GNOME_TWEAKS_INSTALL"
        fi
    fi

    wallpapers

}

base_ubuntu() {
    info "$LOGS"
    read -rp "$FLAT_COMP $YES_NO " ANSWER_FLAT
    if [[ $ANSWER_FLAT == "" ]] ; then
        ANSWER_FLAT=${REPONSE:-y}
    fi

    read -rp "$NVIDIA $YES_NO " ANSWER_NVIDIA
    if [[ $ANSWER_NVIDIA == "" ]] ; then
        ANSWER_NVIDIA=${REPONSE:-y}
    fi

    read -rp "$WALLPAPERS" ANSWER_WALLPAPERS
    if [[ $ANSWER_WALLPAPERS == "" ]] ; then
        ANSWER_WALLPAPERS=${REPONSE:-y}
    fi

    ANSWER_DYN_WALLPAPERS=${REPONSE:-n}
    if [ "$DE" == "GNOME" ] || [ "$DE" == "CINNAMON" ] ; then
        read -rp "$DYN_WALLPAPERS" ANSWER_DYN_WALLPAPERS
        if [[ $ANSWER_DYN_WALLPAPERS == "" ]] ; then
            ANSWER_DYN_WALLPAPERS=${REPONSE:-y}
        fi
    fi

    (run_with_spinner "apt update >> $LOGFILE" "$UPDATE_SOURCE" && success "$UPDATE_SOURCE") || error "$ERROR : $UPDATE_SOURCE"
    (run_with_spinner "apt -y full-upgrade >> $LOGFILE" "$UPGRADE_SYSTEM" && success "$UPGRADE_SYSTEM") || error "$ERROR : $UPGRADE_SYSTEM"

    if [ "$ANSWER_FLAT" == "y" ] || [ "$ANSWER_FLAT" == "Y" ] || [ "$ANSWER_FLAT" == "o" ] || [ "$ANSWER_FLAT" == "O" ] ; then
        (run_with_spinner "apt install -y flatpak >> $LOGFILE" "$INSTALL_FLATPAK" && success "$INSTALL_FLATPAK") || error "$ERROR $INSTALL_FLATPAK"
        (run_with_spinner "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> $LOGFILE" "$INSTALL_FLATHUB" && success "$INSTALL_FLATHUB") || error "$ERROR $INSTALL_FLATHUB"
        install_by_flatpak=true
    fi

    if [ "$DE" == "GNOME" ] ; then
        (run_with_spinner "apt install -y gnome-tweaks >> $LOGFILE" "$GNOME_TWEAKS_INSTALL" && success "$GNOME_TWEAKS_INSTALL") || error "$ERROR $GNOME_TWEAKS_INSTALL"
        (run_with_spinner "gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' >> $LOGFILE" "$WINDOW_BUTTONS" && success "$WINDOW_BUTTONS") || error "$ERROR $WINDOW_BUTTONS"
        if [ $install_by_flatpak == true ] ; then
            (run_with_spinner "flatpak install -y flathub com.mattjakeman.ExtensionManager >> $LOGFILE" "$GNOME_TWEAKS_INSTALL" && success "$GNOME_TWEAKS_INSTALL") || error "$ERROR $GNOME_TWEAKS_INSTALL"
        fi
    fi

    if [ "$ANSWER_NVIDIA" == "y" ] || [ "$ANSWER_NVIDIA" == "Y" ] || [ "$ANSWER_NVIDIA" == "o" ] || [ "$ANSWER_NVIDIA" == "O" ] ; then
        (run_with_spinner "unbuntu-drivers autoinstall >> $LOGFILE" "$NVIDIA_INSTALL" && success "$NVIDIA_INSTALL") || error "$ERROR $NVIDIA_INSTALL"
    fi

    wallpapers
}

opensuse() {
    info "$LOGS"
    read -rp "$FLAT_COMP $YES_NO " ANSWER_FLAT
    if [[ $ANSWER_FLAT == "" ]] ; then
            ANSWER_FLAT=${REPONSE:-y}
    fi

    read -rp "$WALLPAPERS" ANSWER_WALLPAPERS
    if [[ $ANSWER_WALLPAPERS == "" ]] ; then
        ANSWER_WALLPAPERS=${REPONSE:-y}
    fi

    ANSWER_DYN_WALLPAPERS=${REPONSE:-n}
    if [ "$DE" == "GNOME" ] || [ "$DE" == "CINNAMON" ] ; then
        read -rp "$DYN_WALLPAPERS" ANSWER_DYN_WALLPAPERS
        if [[ $ANSWER_DYN_WALLPAPERS == "" ]] ; then
            ANSWER_DYN_WALLPAPERS=${REPONSE:-y}
        fi
    fi

    (run_with_spinner "zypper refresh >> $LOGFILE" "$UPDATE_SOURCE" && success "$UPDATE_SOURCE") || error "$ERROR : $UPDATE_SOURCE"
    (run_with_spinner "zypper update -y >> $LOGFILE" "$UPGRADE_SYSTEM" && success "$UPGRADE_SYSTEM") || error "$ERROR : $UPGRADE_SYSTEM"

    if [ "$ANSWER_FLAT" == "y" ] || [ "$ANSWER_FLAT" == "Y" ] || [ "$ANSWER_FLAT" == "o" ] || [ "$ANSWER_FLAT" == "O" ] ; then
        (run_with_spinner "zypper in -y flatpak >> $LOGFILE" "$INSTALL_FLATPAK" && success "$INSTALL_FLATPAK") || error "$ERROR $INSTALL_FLATPAK"
        (run_with_spinner "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >> $LOGFILE" "$INSTALL_FLATHUB" && success "$INSTALL_FLATHUB") || error "$ERROR $INSTALL_FLATHUB"
        install_by_flatpak=true
    fi

    if [ "$DE" == "GNOME" ] ; then
        (run_with_spinner "zypper in -y gnome-tweaks >> $LOGFILE" "$GNOME_TWEAKS_INSTALL" && success "$GNOME_TWEAKS_INSTALL") || error "$ERROR $GNOME_TWEAKS_INSTALL"
        (run_with_spinner "gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' >> $LOGFILE" "$WINDOW_BUTTONS" && success "$WINDOW_BUTTONS") || error "$ERROR $WINDOW_BUTTONS"
        if [ $install_by_flatpak == true ] ; then
            (run_with_spinner "flatpak install -y flathub com.mattjakeman.ExtensionManager >> $LOGFILE" "$GNOME_TWEAKS_INSTALL" && success "$GNOME_TWEAKS_INSTALL") || error "$ERROR $GNOME_TWEAKS_INSTALL"
        fi
    fi

    wallpapers
}

case "$DIST" in
	fedora)
        fedora
	;;
	ubuntu)
        base_ubuntu
	;;
    linuxmint)
        base_ubuntu
    ;;
    zorin)
        base_ubuntu
    ;;
    pop-os)
        base_ubuntu
    ;;
    opensuse-*)
        opensuse
    ;;
	*)
		error "$ERROR $DIST $ERR_DISTRO"
		exit 1
    ;;
esac
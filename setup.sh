#!/usr/bin/env bash
#
#
########################################################################

# Switch on Debugging
set -x

# Check user privileges
[[ $(id -u) == 0 ]] || echo -e "\n# This script requires root privileges to run"

# Define logfile
LOG="/root/install.log"

update_system() {
    echo -e "# Updating system..." >> ${LOG}
    dnf -y update > /dev/null 2>&1
}

install_packages() {
    echo -e "# Installing packages..." >> ${LOG}
    dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf -y install git wget unzip net-tools httpd-tools patch mlocate maven htop iftop curl tree bind-utils dos2unix bash-completion git gcc-c++ make dnf-plugins-core nodejs vlc qbittorrent icedtea-web java-openjdk mediawriter quassel chrome-gnome-shell exa composer vim ripgrep
    rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
    dnf -y config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
    dnf -y install sublime-text

    dnf -y config-manager --add-repo=http://negativo17.org/repos/fedora-spotify.repo
    dnf -y install spotify

    dnf -y group install virtualization
    systemctl start libvirtd
    systemctl enable libvirtd

    dnf -y config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
    dnf -y install docker-ce
    systemctl start docker
    systemctl enable docker
    groupadd docker
    usermod -aG docker $USER

    cat << EOF > /etc/yum.repos.d/google-chrome.repo
    [google-chrome]
    name=google-chrome - \$basearch
    baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
    enabled=1
    gpgcheck=1
    gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
    EOF
    dnf -y install google-chrome-stable
}

configure_git() {
    git config --global user.name "Jack Powell"
    git config --global user.email "jack@jpowell.me"
}

create_profile() {
    echo "# Creating profile..." >> ${LOG}
    cat > /etc/profile.d/custom.sh << 'EOF'
# Prompt colors
if [ `whoami` != "root" ]; then
    PS1='\[\e[32m\][\u@\h \W]\$\[\e[0m\] '
else
    PS1='\[\e[31m\][\u@\h \W]\$\[\e[0m\] '
fi
# Aliases
alias c='clear'
alias h='history'
alias j='journalctl -fx'
alias l='exa -aghlF --group-directories-first --git '
alias n='netstat -vatulpn | rg'
alias p='ps -A | rg'
alias g='gvim'
# Configure bash history 
export HISTSIZE='1000000'
export HISTIGNORE=' *:&:?:??'
export HISTCONTROL='ignoreboth:erasedups'
# Turn on bash history options
shopt -s histappend histreedit histverify
# Sync term history
history() {
  history_sync
  builtin history "$@"
}
history_sync() {
  builtin history -a         
  HISTFILESIZE=$HISTSIZE     
  builtin history -c         
  builtin history -r         
}
PROMPT_COMMAND=history_sync
EOF
}

configure_vim(){
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh
}


update_system
install_packages
create_profile
history_sync
configure_git
configure_vim
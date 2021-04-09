#!/bin/bash
###
#
# Author: Maël
# Date: 2021/03/14
# Desc:
#   - Install & Setup a new server
#   -
#
###
DEBUG="false"
USERS_LIST=$(awk -F ':' '$3>=1000 && $3<=29999 {print $1}'  /etc/passwd)
PUBLIC_IP="$(curl -s icanhazip.com)"

if ! [ $(id -nu) == "root" ]; then
  echo "Please run this script as root"
  exit 1
fi

if [ "$(lsb_release -is)" != "Debian" ] && [ "$(lsb_release -rs)" != "10" ]
  then
    echo "Oops ! This script was tested on Debian10 only."
    exit 1
fi

function main(){
  while [[ -z $SRV_HOSTNAME ]]; do
    echo "---"
    read -p "Server name: " SRV_HOSTNAME
  done

  while [[ -z $SRV_DOMAIN ]]; do
    echo "---"
    read -p "Server domain: " SRV_DOMAIN
  done

  while ! [[ $SRV_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
    echo "---"
    read -p "Server IP ? [$PUBLIC_IP]: " SRV_IP
    SRV_IP=${SRV_IP:-$PUBLIC_IP)}
  done

  while [[ -z $ROOT_PASSWORD ]]; do
    echo "---"
    echo -n "Choose root "
    ROOT_PASSWORD="$(openssl passwd -6)"
  done

  while ! [[ $DEL_USERS =~ ^(y|n)$ ]]; do
    echo "---"
    echo "Those users were found: $USERS_LIST"
    read -p "Delete them ? [y/N]: " DEL_USERS
    DEL_USERS=${DEL_USERS:-"n"}
  done

  while [[ -z $USER_TO_CREATE ]]; do
    echo "---"
    read -p "User to create: " USER_TO_CREATE
  done

  while ! [[ $USER_UID =~ ^[0-9]{1,4} ]]; do
    echo "---"
    read -p "Set an uid for $USER_TO_CREATE ? (1000-29999) [1000]: " USER_UID
    USER_UID=${USER_UID:-1000}
  done

  while ! [[ $SET_USER_PASSWORD =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Set a password for $USER_TO_CREATE ? [y/N]: " SET_USER_PASSWORD
    SET_USER_PASSWORD=${SET_USER_PASSWORD:-"n"}
  done

  if [[ $SET_USER_PASSWORD == "y" ]]; then
    while [[ -z $USER_PASSWORD ]]; do
      echo "---"
      echo -n "Choose user "
      USER_PASSWORD="$(openssl passwd -6)"
    done
  fi

  while ! [[ $SSH_PORT =~ ^[0-9]+$ ]]; do
    echo "---"
    read -p "SSH port ? [22]: " SSH_PORT
    SSH_PORT=${SSH_PORT:-"22"}
  done

  while ! [[ $SSH_PASSWORD =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "SSH PasswordAuthentication ? [y/N]: " SSH_PASSWORD
    SSH_PASSWORD=${SSH_PASSWORD:-"n"}
  done

  while ! [[ $SSH_ROOT =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "SSH PermitRootLogin ? [y/N]: " SSH_ROOT
    SSH_ROOT=${SSH_ROOT:-"n"}
  done

  while [[ -z $SSH_KEYS_TO_COPY || ! -f $SSH_KEYS_TO_COPY ]]; do
    echo "---"
    read -p "Path to ssh keys list [./files/ssh_keys.txt]: " SSH_KEYS_TO_COPY
    SSH_KEYS_TO_COPY=${SSH_KEYS_TO_COPY:-"./files/ssh_keys.txt"}
  done

  while [[ -z $BASHRC_TO_COPY || ! -f $BASHRC_TO_COPY ]]; do
    echo "---"
    read -p "Path to bashrc [./files/bashrc]: " BASHRC_TO_COPY
    BASHRC_TO_COPY=${BASHRC_TO_COPY:-"./files/bashrc"}
  done

  while [[ -z $VIMRC_TO_COPY || ! -f $VIMRC_TO_COPY ]]; do
    echo "---"
    read -p "Path to bashrc [./files/vimrc]: " VIMRC_TO_COPY
    VIMRC_TO_COPY=${VIMRC_TO_COPY:-"./files/vimrc"}
  done

  while [[ -z $SOURCES_LIST_TO_COPY || ! -f $SOURCES_LIST_TO_COPY ]]; do
    echo "---"
    read -p "Path to sources.list [./files/sources.list]: " SOURCES_LIST_TO_COPY
    SOURCES_LIST_TO_COPY=${SOURCES_LIST_TO_COPY:-"./files/sources.list"}
  done

  while [[ -z $PACKAGES_LIST || ! -f $PACKAGES_LIST ]]; do
    echo "---"
    read -p "Path to packages.list [./files/packages.list]: " PACKAGES_LIST
    PACKAGES_LIST=${PACKAGES_LIST:-"./files/packages.list"}
  done

  while ! [[ "$INSTALL_NTP" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to install NTP ? [Y/n]: " INSTALL_NTP
    INSTALL_NTP=${INSTALL_NTP:-y}
  done
  if [[ $INSTALL_NTP == "y" ]]; then
    while [[ -z $NTP_CONF || ! -f $NTP_CONF ]]; do
      echo "---"
      read -p "Path to ntp.conf [./files/ntp.conf]: " NTP_CONF
      NTP_CONF=${NTP_CONF:-"./files/ntp.conf"}
    done
  fi

  ### firewall

  while ! [[ "$INSTALL_IPTABLES" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to install iptables ? [Y/n]: " INSTALL_IPTABLES
    INSTALL_IPTABLES=${INSTALL_IPTABLES:-y}
  done

  if [[ $INSTALL_IPTABLES == "y" ]]; then
    while [[ -z $IPTABLES_RULES_4 || ! -f $IPTABLES_RULES_4 ]]; do
      echo "---"
      read -p "Path to rules.v4 [./files/rules.v4]: " IPTABLES_RULES_4
      IPTABLES_RULES_4=${IPTABLES_RULES_4:-"./files/rules.v4"}
    done
    while [[ -z $IPTABLES_RULES_6 || ! -f $IPTABLES_RULES_6 ]]; do
      echo "---"
      read -p "Path to rules.v6 [./files/rules.v6]: " IPTABLES_RULES_6
      IPTABLES_RULES_6=${IPTABLES_RULES_6:-"./files/rules.v6"}
    done
  fi

  ### Nullmailer

  while ! [[ "$INSTALL_NULLMAILER" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to install nullmailer and mailx ? [Y/n]: " INSTALL_NULLMAILER
    INSTALL_NULLMAILER=${INSTALL_NULLMAILER:-y}
  done

  if [[ $INSTALL_NULLMAILER == "y" ]]; then
    while [[ -z $NULLMAILER_REMOTE || ! -f $NULLMAILER_REMOTE ]]; do
      echo "---"
      read -p "Path to remotes [./files/remotes]: " NULLMAILER_REMOTE
      NULLMAILER_REMOTE=${NULLMAILER_REMOTE:-"./files/remotes"}
    done
    while [[ -z $NULLMAILER_ADMINADDR || ! -f $NULLMAILER_ADMINADDR ]]; do
      echo "---"
      read -p "Path to adminaddr [./files/adminaddr]: " NULLMAILER_ADMINADDR
      NULLMAILER_ADMINADDR=${NULLMAILER_ADMINADDR:-"./files/adminaddr"}
    done
    while [[ -z $NULLMAILER_DEFAULTDOMAIN || ! -f $NULLMAILER_DEFAULTDOMAIN ]]; do
      echo "---"
      read -p "Path to defaultdomain [./files/defaultdomain]: " NULLMAILER_DEFAULTDOMAIN
      NULLMAILER_DEFAULTDOMAIN=${NULLMAILER_DEFAULTDOMAIN:-"./files/defaultdomain"}
    done
  fi

  ### Fail2ban

  while ! [[ "$INSTALL_FAIL2BAN" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to install fail2ban ? [Y/n]: " INSTALL_FAIL2BAN
    INSTALL_FAIL2BAN=${INSTALL_FAIL2BAN:-y}
  done

  if [[ $INSTALL_FAIL2BAN == "y" ]]; then
    while [[ -z $FAIL2BAN_JAIL || ! -f $FAIL2BAN_JAIL ]]; do
      echo "---"
      read -p "Path to jail.local [./files/jail.local]: " FAIL2BAN_JAIL
      FAIL2BAN_JAIL=${FAIL2BAN_JAIL:-"./files/jail.local"}
    done
    while [[ -z $FAIL2BAN_IPTABLES_COMMON || ! -f $FAIL2BAN_IPTABLES_COMMON ]]; do
      echo "---"
      read -p "Path to iptables-common.local [./files/iptables-common.local]: " FAIL2BAN_IPTABLES_COMMON
      FAIL2BAN_IPTABLES_COMMON=${FAIL2BAN_IPTABLES_COMMON:-"./files/iptables-common.local"}
    done
  fi

  ### Install Auto-Updates

  while ! [[ "$INSTALL_AUTO_UPDATES" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to setup automatic system updates ? [Y/n]: " INSTALL_AUTO_UPDATES
    INSTALL_AUTO_UPDATES=${INSTALL_AUTO_UPDATES:-y}
  done

  ### Install Monitorix

  while ! [[ "$INSTALL_MONITORIX" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to install Monitorix ? [Y/n]: " INSTALL_MONITORIX
    INSTALL_MONITORIX=${INSTALL_MONITORIX:-y}
  done

  if [[ $INSTALL_MONITORIX == "y" ]]; then
    while [[ -z $MONITORIX_LOCAL || ! -f $MONITORIX_LOCAL ]]; do
      echo "---"
      read -p "Path to personnal config [./files/monitorix_local.conf]: " MONITORIX_LOCAL
      MONITORIX_LOCAL=${MONITORIX_LOCAL:-"./files/monitorix_local.conf"}
    done
  fi

  if [ $DEBUG == "false" ]; then

    setup_system
    setup_users
    if [ $INSTALL_NTP == "y" ]; then setup_ntp; fi
    if [ $INSTALL_IPTABLES == "y" ]; then setup_iptables; fi
    if [ $INSTALL_FAIL2BAN == "y" ]; then setup_fail2ban; fi
    if [ $INSTALL_NULLMAILER == "y" ]; then setup_nullmailer; fi
    if [ $INSTALL_AUTO_UPDATES == "y" ]; then setup_auto_updates; fi
    if [ $INSTALL_MONITORIX == "y" ]; then setup_monitorix; fi
    cleaning

    echo "########################################################################"
    echo "                            Setup done."
    echo ""
    echo "  - Monitorix: Firewall is not open for it"
    echo "               for more security you can use ssh port forwarding"
    echo "    Exemple:"
    echo "      ssh -L 8080:localhost:8080 user@myserver.domain.tld"
    echo "      And browse to http://localhost:8080"
    echo ""
    echo "  - Nullmailer: Quick test"
    echo "      echo \"My message\" | mail -s \"My subject\" mail@domain.tld"
    echo ""
    echo "  /!\  To applied everything propely please reboot your server  /!\ "
    echo "########################################################################"

  elif [ $DEBUG == "true" ]; then
    debug
  fi
}

function debug() {
  echo ""
  echo "############### Variables Values ###############"
  echo "Server Name                   : $SRV_HOSTNAME"
  echo "Server Domain                 : $SRV_DOMAIN"
  echo "Server IP                     : $SRV_IP"
  echo "New root password             : $ROOT_PASSWORD"
  echo "Delete existing users ?       : $DEL_USERS"
  echo "Username to create            : $USER_TO_CREATE"
  echo "Set User UID ?                : $USER_UID"
  echo "Set User Password ?           : $SET_USER_PASSWORD"
  echo "New user password             : $USER_PASSWORD"
  echo "SSH port                      : $SSH_PORT"
  echo "SSH PasswordAuthentication    : $SSH_PASSWORD"
  echo "SSH PermitRootLogin           : $SSH_ROOT"
  echo "SSH keys to copy              : $SSH_KEYS_TO_COPY"
  echo "Bashrc to copy                : $BASHRC_TO_COPY"
  echo "Vimrc to copy                 : $VIMC_TO_COPY"
  echo "Sources_list to copy          : $SOURCES_LIST_TO_COPY"
  echo "Path to packages.list         : $PACKAGES_LIST"
  echo "Install NTP ?                 : $INSTALL_NTP"
  echo "Path to ntp.conf              : $NTP_CONF"
  echo "Install iptables              : $INSTALL_IPTABLES"
  echo "Path to rules.v4              : $IPTABLES_RULES_4"
  echo "Path to rules.v6              : $IPTABLES_RULES_6"
  echo "Install FAIL2BAN ?            : $INSTALL_FAIL2BAN"
  echo "Path to jail.local            : $FAIL2BAN_JAIL"
  echo "Path to iptables-common       : $FAIL2BAN_IPTABLES_COMMON"
  echo "Install NULLMAILER ?          : $INSTALL_NULLMAILER"
  echo "Path to remotes               : $NULLMAILER_REMOTE"
  echo "Path to adminaddr             : $NULLMAILER_ADMINADDR"
  echo "Path to defaultdomain         : $NULLMAILER_DEFAULTDOMAIN"
  echo "Install Auto System Updates ? : $INSTALL_AUTO_UPDATES"
  echo "Install Monitorix ?           : $INSTALL_MONITORIX"
  echo "Path to monitorix.local       : $MONITORIX_LOCAL"
  echo "#################################################"
  echo ""
}

function setup_iptables() {
  echo "########################################################################"
  echo "                        Setup iptables"
  echo "########################################################################"

  if [ "$(which iptables)" = "" ]; then
    apt -qq install iptables -y
  fi

  # I don't use iptables/netfilter-persistent anymore because it start before network.
  # So it's not able to resolv hostname.
  #echo "iptables-persistent iptables-persistent/autosave_v4	boolean	true" | debconf-set-selections
  #echo "iptables-persistent iptables-persistent/autosave_v6	boolean	true" | debconf-set-selections
  #apt -qq install iptables-persistent -y

  if [ ! -d "/etc/iptables" ]; then
    mkdir -m 755 /etc/iptables
  fi

  cp $IPTABLES_RULES_4 /etc/iptables/rules.v4 \
    && msg ok "/etc/iptables/rules.v4" \
    || msg warn "Line: $LINENO"
  cp $IPTABLES_RULES_6 /etc/iptables/rules.v6 \
    && msg ok "/etc/iptables/rules.v6" \
    || msg warn "Line: $LINENO"

  echo "#!/bin/sh
  /sbin/iptables-restore < /etc/iptables/rules.v4
  /sbin/ip6tables-restore < /etc/iptables/rules.v6" > /etc/network/if-up.d/iptables \
    && msg ok "/etc/network/if-up.d/iptables" \
    || msg warn "Line: $LINENO"
  chmod 755 /etc/network/if-up.d/iptables
}

function setup_nullmailer() {
  echo "########################################################################"
  echo "                       Setup Nullmailer"
  echo "########################################################################"

  echo "nullmailer shared/mailname            string domain.tld"        | debconf-set-selections
  echo "nullmailer nullmailer/defaultdomain	  string domain.tld"        | debconf-set-selections
  echo "nullmailer nullmailer/relayhost	      string smtp.domain.tld"   | debconf-set-selections
  echo "nullmailer nullmailer/remotes         string smtp.domain.tld"   | debconf-set-selections
  echo "nullmailer nullmailer/adminaddr       string admin@domain.tld"  | debconf-set-selections

  apt -qq install nullmailer mailutils -y
  cp $NULLMAILER_REMOTE /etc/nullmailer/remotes \
    && msg ok "/etc/nullmailer/remotes" \
    || msg warn "Line: $LINENO"
  cp $NULLMAILER_ADMINADDR /etc/nullmailer/adminaddr \
    && msg ok "/etc/nullmailer/adminaddr" \
    || msg warn "Line: $LINENO"
  cp $NULLMAILER_DEFAULTDOMAIN /etc/nullmailer/defaultdomain \
    && msg ok "/etc/nullmailer/defaultdomain" \
    || msg warn "Line: $LINENO"
}

function setup_ntp() {
  echo "########################################################################"
  echo "                            Setup NTP"
  echo "########################################################################"

  apt -qq install ntp -y
  cp $NTP_CONF /etc/ntp.conf \
    && msg ok "/etc/ntp.conf" \
    || msg warn "Line: $LINENO"
}

function setup_system() {
  echo "########################################################################"
  echo "                   Basic System Configuration "
  echo "########################################################################"

  # APT Repository & basic Softwares
  cp $SOURCES_LIST_TO_COPY /etc/apt/sources.list

  echo "--> Run apt update..."
  apt -qq update

  echo "--> Run apt full-upgrade..."
  apt -qq full-upgrade -y

  echo "--> Let's install your packages..."
  apt -qq install -y $(grep -o ^[^#][[:alnum:]-]* $PACKAGES_LIST)

      # -o keep only the part of line that matches the expression
      # ^[^#] anything that does not start with a #
      # [[:alnum]-]* a sequence of letters, numbers and -

  ## Hostname & Hosts Configuration
  echo "$SRV_HOSTNAME" > /etc/hostname \
    && msg ok "/etc/hostname" \
    || msg warn "Line: $LINENO"

  if grep -q "^$SRV_IP" /etc/hosts ; then
    sed -i "s/^$SRV_IP.*/$SRV_IP  $SRV_HOSTNAME $SRV_HOSTNAME.$SRV_DOMAIN/g" /etc/hosts \
      && msg ok "/etc/hosts" \
      || msg warn "Line: $LINENO"
  else
    echo "$SRV_IP  $SRV_HOSTNAME $SRV_HOSTNAME.$SRV_DOMAIN" >> /etc/hosts \
      && msg ok "/etc/hosts" \
      || msg warn "Line: $LINENO"
  fi

  ## SSH Configuration
  sed -i "s/\(^#\|^\)Port.*/Port $SSH_PORT/g" /etc/ssh/sshd_config \
    && msg ok "SSH: Port => $SSH_PORT" \
    || msg warn "Line: $LINENO"

  if [ $SSH_ROOT == "y" ]; then
    sed -i 's/\(^#\|^\)PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config \
      && msg ok "SSH: PermitRootLogin => yes" \
      || msg warn "Line: $LINENO"
  elif [ $SSH_ROOT == "n" ]; then
    sed -i 's/\(^#\|^\)PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config \
      && msg ok "SSH: PermitRootLogin => no" \
      || msg warn "Line: $LINENO"
  fi
  if [ $SSH_PASSWORD == "y" ]; then
    sed -i 's/\(^#\|^\)PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config \
      && msg ok "SSH: PasswordAuthentication => yes" \
      || msg warn "Line: $LINENO"
  elif [ $SSH_PASSWORD == "n" ]; then
    sed -i 's/\(^#\|^\)PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config \
      && msg ok "SSH: PasswordAuthentication => no" \
      || msg warn "Line: $LINENO"
  fi

  /usr/bin/systemctl restart ssh
}

function setup_users() {
  echo "########################################################################"
  echo "                $USER_TO_CREATE & root configuration"
  echo "########################################################################"

  if [ $DEL_USERS == "y" ]; then
    for e in $USERS_LIST; do
      userdel -rf $e
    done
  fi

  echo "root:$ROOT_PASSWORD" | /usr/sbin/chpasswd -e \
    && msg ok "Set Root password" \
    || msg warn "Line: $LINENO"

  /usr/sbin/useradd --create-home --shell "/bin/bash" --uid $USER_UID -U $USER_TO_CREATE \
    && msg ok "Create $USER_TO_CREATE" \
    || msg warn "Line: $LINENO"

  if [[ $SET_USER_PASSWORD == "y" ]]; then
    echo "$USER_TO_CREATE:$USER_PASSWORD" | /usr/sbin/chpasswd -e \
      && msg ok "Set $USER_TO_CREATE password" \
      || msg warn "Line: $LINENO"
  fi

  for e in "/root/.bashrc" "/home/$USER_TO_CREATE/.bashrc"; do
    cp $BASHRC_TO_COPY $e \
      && msg ok "Copy $BASHRC_TO_COPY to $e" \
      || msg warn "Line: $LINENO"
  done
  source /root/.bashrc

  for e in "/root/.vimrc" "/home/$USER_TO_CREATE/.vimrc"; do
    cp $VIMRC_TO_COPY $e \
      && msg ok "Copy $VIMRC_TO_COPY to $e" \
      || msg warn "Line: $LINENO"
  done

  if [ ! -d "/home/$USER_TO_CREATE/.ssh" ]; then
    mkdir -m 0700 "/home/$USER_TO_CREATE/.ssh"
  fi
  cp $SSH_KEYS_TO_COPY "/home/$USER_TO_CREATE/.ssh/authorized_keys" \
    && msg ok "/home/$USER_TO_CREATE/.ssh/authorized_keys" \
    || msg warn "Line: $LINENO"
  chmod 0600 "/home/$USER_TO_CREATE/.ssh/authorized_keys"
  chown --recursive "$USER_TO_CREATE":"$USER_TO_CREATE" "/home/$USER_TO_CREATE/.ssh"
}

function setup_auto_updates() {
  echo "########################################################################"
  echo "                     Setup Auto Updates"
  echo "########################################################################"

  apt -qq install unattended-upgrades apt-listchanges -y

}

function setup_fail2ban() {
  echo "########################################################################"
  echo "                         Setup Fail2ban"
  echo "########################################################################"

  apt -qq install fail2ban -y
  cp $FAIL2BAN_JAIL /etc/fail2ban/jail.local \
    && msg ok "/etc/fail2ban/jail.local" \
    || msg warn "Line: $LINENO"
  cp $FAIL2BAN_IPTABLES_COMMON /etc/fail2ban/action.d/iptables-common.local \
    && msg ok "/etc/fail2ban/action.d/iptables-common.local" \
    || msg warn "Line: $LINENO"

  /usr/bin/systemctl restart fail2ban
}

function setup_monitorix() {
  echo "########################################################################"
  echo "                        Setup Monitorix"
  echo "########################################################################"

  apt -qq install monitorix -y
  cp $MONITORIX_LOCAL /etc/monitorix/conf.d/ \
    && msg ok "/etc/monitorix/conf.d/$MONITORIX_LOCAL" \
    || msg warn "Line: $LINENO"

  /usr/sbin/service monitorix restart
}

function cleaning() {
  apt autoremove -y && apt clean -y
}

function msg() {
  # Color
  local GREEN="\\033[1;32m"
  local NORMAL="\\033[0;39m"
  local RED="\\033[1;31m"
  local PINK="\\033[1;35m"
  local BLUE="\\033[1;34m"
  local WHITE="\\033[0;02m"
  local YELLOW="\\033[1;33m"

  if [ "$1" == "ok" ]; then
    echo -e "[$GREEN  OK  $NORMAL] $2"
  elif [ "$1" == "ko" ]; then
    echo -e "[$RED CRIT $NORMAL] $2"
  elif [ "$1" == "warn" ]; then
    echo -e "[$YELLOW WARN $NORMAL] $2"
  fi
}

main

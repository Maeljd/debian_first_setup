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

if ! [ $(id -nu) == "root" ]; then
  echo "Please run this script as root"
  exit 1
fi

function main(){
  while [[ $SRV_HOSTNAME == "" ]]; do
    echo "---"
    read -p "Server name: " SRV_HOSTNAME
  done

  while [[ $SRV_DOMAIN == "" ]]; do
    echo "---"
    read -p "Server domain: " SRV_DOMAIN
  done

  while ! [[ $SRV_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
    echo "---"
    read -p "Server IP ? [$(hostname -i)]: " SRV_IP
    SRV_IP=${SRV_IP:-$(hostname -i)}
  done

  while [[ $ROOT_PASSWORD == "" ]]; do
    echo "---"
    echo -n "Choose root "
    ROOT_PASSWORD="$(openssl passwd -6)"
  done

  while [[ $USER_TO_CREATE == "" ]]; do
    echo "---"
    read -p "User to create: " USER_TO_CREATE
  done

  while [[ $USER_PASSWORD == "" ]]; do
    echo "---"
    echo -n "Choose user "
    USER_PASSWORD="$(openssl passwd -6)"
  done

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

  while [[ $SSH_KEYS_TO_COPY == "" || ! -f $SSH_KEYS_TO_COPY ]]; do
    echo "---"
    read -p "Path to ssh keys list [./files/ssh_keys.txt]: " SSH_KEYS_TO_COPY
    SSH_KEYS_TO_COPY=${SSH_KEYS_TO_COPY:-"./files/ssh_keys.txt"}
  done

  while [[ $BASHRC_TO_COPY == "" || ! -f $BASHRC_TO_COPY ]]; do
    echo "---"
    read -p "Path to bashrc [./files/bashrc]: " BASHRC_TO_COPY
    BASHRC_TO_COPY=${BASHRC_TO_COPY:-"./files/bashrc"}
  done

  while [[ $SOURCES_LIST_TO_COPY == "" || ! -f $SOURCES_LIST_TO_COPY ]]; do
    echo "---"
    read -p "Path to sources.list [./files/sources.list]: " SOURCES_LIST_TO_COPY
    SOURCES_LIST_TO_COPY=${SOURCES_LIST_TO_COPY:-"./files/sources.list"}
  done

  while ! [[ "$INSTALL_NTP" =~ ^(y|n)$ ]]; do
    echo "---"
    read -p "Do you want to install NTP ? [Y/n]: " INSTALL_NTP
    INSTALL_NTP=${INSTALL_NTP:-y}
  done
  if [[ $INSTALL_NTP == "y" ]]; then
    while [[ $NTP_CONF == "" || ! -f $NTP_CONF ]]; do
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
    while [[ $IPTABLES_RULES_4 == "" || ! -f $IPTABLES_RULES_4 ]]; do
      echo "---"
      read -p "Path to rules.v4 [./files/rules.v4]: " IPTABLES_RULES_4
      IPTABLES_RULES_4=${IPTABLES_RULES_4:-"./files/rules.v4"}
    done
    while [[ $IPTABLES_RULES_6 == "" || ! -f $IPTABLES_RULES_6 ]]; do
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
    while [[ $NULLMAILER_REMOTE == "" || ! -f $NULLMAILER_REMOTE ]]; do
      echo "---"
      read -p "Path to remotes [./files/remotes]: " NULLMAILER_REMOTE
      NULLMAILER_REMOTE=${NULLMAILER_REMOTE:-"./files/remotes"}
    done
    while [[ $NULLMAILER_ADMINADDR == "" || ! -f $NULLMAILER_ADMINADDR ]]; do
      echo "---"
      read -p "Path to adminaddr [./files/adminaddr]: " NULLMAILER_ADMINADDR
      NULLMAILER_ADMINADDR=${NULLMAILER_ADMINADDR:-"./files/adminaddr"}
    done
    while [[ $NULLMAILER_DEFAULTDOMAIN == "" || ! -f $NULLMAILER_DEFAULTDOMAIN ]]; do
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
    while [[ $FAIL2BAN_JAIL == "" || ! -f $FAIL2BAN_JAIL ]]; do
      echo "---"
      read -p "Path to jail.local [./files/jail.local]: " FAIL2BAN_JAIL
      FAIL2BAN_JAIL=${FAIL2BAN_JAIL:-"./files/jail.local"}
    done
    while [[ $FAIL2BAN_IPTABLES_COMMON == "" || ! -f $FAIL2BAN_IPTABLES_COMMON ]]; do
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
    while [[ $MONITORIX_LOCAL == "" || ! -f $MONITORIX_LOCAL ]]; do
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
    echo " Setup done. Please reboot"

  elif [ $DEBUG == "true" ]; then
    debug
  fi
}

function debug() {
  echo ""
  echo "### Variables Values ###"
  echo "Server Name: $SRV_HOSTNAME"
  echo "Server Domain: $SRV_DOMAIN"
  echo "Server IP: $SRV_IP"
  echo "New root password: $ROOT_PASSWORD"
  echo "Username to create: $USER_TO_CREATE"
  echo "New user password: $USER_PASSWORD"
  echo "SSH port: $SSH_PORT"
  echo "SSH PasswordAuthentication: $SSH_PASSWORD"
  echo "SSH PermitRootLogin: $SSH_ROOT"
  echo "SSH keys to copy: $SSH_KEYS_TO_COPY"
  echo "Bashrc to copy: $BASHRC_TO_COPY"
  echo "Sources_list to copy: $SOURCES_LIST_TO_COPY"
  echo "Install NTP ? : $INSTALL_NTP"
  echo "Path to ntp.conf: $NTP_CONF"
  echo "Install iptables: $INSTALL_IPTABLES"
  echo "Path to rules.v4: $IPTABLES_RULES_4"
  echo "Path to rules.v6: $IPTABLES_RULES_6"
  echo "Install FAIL2BAN ? : $INSTALL_FAIL2BAN"
  echo "Path to jail.local: $FAIL2BAN_JAIL"
  echo "Path to iptables-common: $FAIL2BAN_IPTABLES_COMMON"
  echo "Install NULLMAILER ? : $INSTALL_NULLMAILER"
  echo "Path to remotes: $NULLMAILER_REMOTE"
  echo "Path to adminaddr: $NULLMAILER_ADMINADDR"
  echo "Path to defaultdomain: $NULLMAILER_DEFAULTDOMAIN"
  echo "Install Auto System Updates ? : $INSTALL_AUTO_UPDATES"
  echo "Install Monitorix ? : $INSTALL_MONITORIX"
  echo "Path to monitorix.local: $MONITORIX_LOCAL"
  echo "#########################"
  echo ""
}

function setup_iptables() {
  echo "########################################################################"
  echo "                        Setup iptables"
  echo "########################################################################"

  if [ "$(which iptables)" = "" ]; then
    apt install iptables -y
  fi

  # I don't use iptables/netfilter-persistent anymore because it start before network.
  # So it's not able to resolv hostname.
  #echo "iptables-persistent iptables-persistent/autosave_v4	boolean	true" | debconf-set-selections
  #echo "iptables-persistent iptables-persistent/autosave_v6	boolean	true" | debconf-set-selections
  #apt install iptables-persistent -y

  mkdir -m 755 /etc/iptables
  cp $IPTABLES_RULES_4 /etc/iptables/rules.v4
  cp $IPTABLES_RULES_6 /etc/iptables/rules.v6
  echo "#!/bin/sh
  /sbin/iptables-restore < /etc/iptables/rules.v4
  /sbin/ip6tables-restore < /etc/iptables/rules.v6" > /etc/network/if-up.d/iptables
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

  apt install nullmailer mailutils -y
  cp $NULLMAILER_REMOTE /etc/nullmailer/remotes
  cp $NULLMAILER_ADMINADDR /etc/nullmailer/adminaddr
  cp $NULLMAILER_DEFAULTDOMAIN /etc/nullmailer/defaultdomain
}

function setup_ntp() {
  echo "########################################################################"
  echo "                            Setup NTP"
  echo "########################################################################"

  apt install ntp -y
  cp $NTP_CONF /etc/ntp.conf
}

function setup_system() {
  echo "########################################################################"
  echo "                   Basic System Configuration "
  echo "########################################################################"

  # APT Repository & basic Softwares
  cp $SOURCES_LIST_TO_COPY /etc/apt/sources.list

  apt update && apt full-upgrade -y
  apt install -y \
    vim \
    htop

  ## Hostname & Hosts Configuration
  echo "$SRV_HOSTNAME" > /etc/hostname

  if grep -q "^$SRV_IP" /etc/hosts ; then
    sed -i "s/^$SRV_IP.*/$SRV_IP  $SRV_HOSTNAME $SRV_HOSTNAME.$SRV_DOMAIN/g" /etc/hosts
  else
    echo "$SRV_IP  $SRV_HOSTNAME $SRV_HOSTNAME.$SRV_DOMAIN" >> /etc/hosts
  fi

  ## SSH Configuration
  sed -i "s/\(^#\|^\)Port.*/Port $SSH_PORT/g" /etc/ssh/sshd_config

  if [ $SSH_ROOT == "y" ]; then
    sed -i 's/\(^#\|^\)PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
  elif [ $SSH_ROOT == "n" ]; then
    sed -i 's/\(^#\|^\)PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
  fi
  if [ $SSH_PASSWORD == "y" ]; then
    sed -i 's/\(^#\|^\)PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
  elif [ $SSH_PASSWORD == "n" ]; then
    sed -i 's/\(^#\|^\)PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
  fi

  /usr/bin/systemctl restart ssh
}

function setup_users() {
  echo "########################################################################"
  echo "                $USER_TO_CREATE & root configuration"
  echo "########################################################################"

  echo "root:$ROOT_PASSWORD" | /usr/sbin/chpasswd -e
  /usr/sbin/useradd --password "$USER_PASSWORD" --create-home --shell "/bin/bash" $USER_TO_CREATE

  cp $BASHRC_TO_COPY /root/.bashrc
  source /root/.bashrc
  cp $BASHRC_TO_COPY /home/$USER_TO_CREATE/.bashrc

  mkdir -m 0700 "/home/$USER_TO_CREATE/.ssh"
  cp $SSH_KEYS_TO_COPY "/home/$USER_TO_CREATE/.ssh/authorized_keys"
  chmod 0600 "/home/$USER_TO_CREATE/.ssh/authorized_keys"
  chown --recursive "$USER_TO_CREATE":"$USER_TO_CREATE" "/home/$USER_TO_CREATE/.ssh"
}

function setup_auto_updates() {
  echo "########################################################################"
  echo "                     Setup Auto Updates"
  echo "########################################################################"

  apt install unattended-upgrades apt-listchanges -y

}

function setup_fail2ban() {
  echo "########################################################################"
  echo "                         Setup Fail2ban"
  echo "########################################################################"

  apt install fail2ban -y
  cp $FAIL2BAN_JAIL /etc/fail2ban/jail.local
  cp $FAIL2BAN_IPTABLES_COMMON /etc/fail2ban/action.d/iptables-common.local

  /usr/bin/systemctl restart fail2ban
}

function setup_monitorix() {
  echo "########################################################################"
  echo "                        Setup Monitorix"
  echo "########################################################################"

  apt install monitorix -y
  cp $MONITORIX_LOCAL /etc/monitorix/conf.d/

  /usr/sbin/service monitorix restart
}

function cleaning() {
  apt autoremove -y && apt clean -y
}

main

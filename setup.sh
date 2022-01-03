#!/bin/bash
###
#
# Author: snax44
# Date:
# Version: 1.0
# Desc:
###
#############
### Variables

# To personnalize
DEBUG=false                                                                                         # Set to true to go directly in debug function after option parsing
REQUIRE_ROOT=false                                                                                  # Set to true if this script need to be run as root
REQUIRE_OPTION=false                                                                                # Set to true if this script cannot be ran without any options
CONTINUE_ON_UNDETECTED_OS=false                                                                     # Script will continue even if the has not been correctly detected
MY_REPO_URL=""                                                                                      # Put here link to the git repository

###
OS_DETECTED="$(awk '/^ID=/' /etc/*-release 2> /dev/null | awk -F'=' '{ print tolower($2) }' )"      # Get the os name
USER_ID=$(id -u)                                                                                    # Nothing to say here

#################
### Main function
function main(){
  local OPTION=$(whiptail --title "Main Menu" --backtitle "OS Detected: $OS_DETECTED" --cancel-button Quit --menu "Choose your option" 15 60 0 \
  "1" "System configuration" \
  "2" "Network configuration" \
  "3" "Users configuration" \
  "4" "Software configuration"  \
  3>&1 1>&2 2>&3)

  if [ $? = 0 ]; then
    case "$OPTION" in
      1)
        system_setup
        main
        ;;
      2)
        network_setup
        main
        ;;
      3)
        users_setup
        main
        ;;
      4)
        software_setup
        main
        ;;
    esac
  else
      exit 0
  fi
}

function system_setup(){
  while [[ -z $SRV_HOSTNAME ]]; do
    SRV_HOSTNAME=$(whiptail --title "Define Hostname" --inputbox "Enter here the hostname." --nocancel  10 80 $(hostname -s) 3>&1 1>&2 2>&3)
  done

  while [[ -z $SRV_DOMAIN ]]; do
    SRV_DOMAIN=$(whiptail --title "Define Domain" --inputbox "Enter here the domain." --nocancel  10 80 $(hostname -d) 3>&1 1>&2 2>&3)
  done

  while ! [[ $SRV_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; do
    SRV_IP=$(whiptail --title "Define IP Address" --inputbox "Enter here the IP Address" --nocancel  10 80 $(hostname -i) 3>&1 1>&2 2>&3)
  done

  if (whiptail --title "Install NTP ?" --yesno "Install NTP for time synchronization ?" 10 60) then
    NTP_SRV=$(whiptail --title "Define NTP Server" --inputbox "Enter here your favorite ntp server. \n(Leave empty for defaults)" --nocancel  10 80 3>&1 1>&2 2>&3)
    echo "Server: $NTP_SRV"
  fi
}

function network_setup(){
  whiptail --title "Network Configuration" \
           --msgbox "Todo" 20 80
}

function users_setup(){
  whiptail --title "Users Configuration" \
           --msgbox "Todo" 20 80
}

function software_setup(){
  whiptail --title "Software Configuration" \
           --msgbox "Todo" 20 80
}

#####################
### Commons functions
# Basic function that will be call if DEBUG is set to true

function debug(){
  cat << EOF

  Debug mode:
  -----------------------------
  Require root              : $REQUIRE_ROOT
  Require options           : $REQUIRE_OPTION
  Continue on undetected OS : $CONTINUE_ON_UNDETECTED_OS
  Git Link                  : $MY_REPO_URL
  OS Detected               : $OS_DETECTED
  User ID                   : $USER_ID
  -----------------------------

EOF
}

function usage(){
  cat <<EOF

blablablabla

  Usage:
        $0 --help

    -d  |  --debug             Do nothing dangerous, only call debug function
    -h  |  --help              Show this help
EOF
}

function msg(){
  # Call this function to print a beautifull colored message
  # Ex: msg ko "This is an error"

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
    echo -e "[$RED ERROR $NORMAL] $2"
  elif [ "$1" == "warn" ]; then
    echo -e "[$YELLOW WARN $NORMAL] $2"
  elif [ "$1" == "info" ]; then
    echo -e "[$BLUE INFO $NORMAL] $2"
  fi
}

function detect_os(){
  # Do what you want or need accoring the detected os
  # By default this will just print an info message with then OS name.
  # You just have to write not_supported_os in one of the following if do make it not compatible

  if [[ "$OS_DETECTED" == "debian" ]]; then
    msg info "OS detected : Debian"
  elif [[ "$OS_DETECTED" == "ubuntu" ]]; then
    msg info "OS detected : Ubuntu"
  elif [[ "$OS_DETECTED" == "fedora" ]]; then
    msg info "OS detected : Fedora"
  elif [[ "$OS_DETECTED" == "centos" ]]; then
    msg info "OS detected : Centos"
  elif [[ "$OS_DETECTED" == "arch" ]]; then
    msg info "OS detected : Archlinux"
  else
    if $CONTINUE_ON_UNDETECTED_OS; then
      msg warn "Unable to detect os. Keep going anyway in 5s"
      sleep 5
      main
    else
      msg ko "Unable to detect os and CONTINUE_ON_UNDETECTED_OS is set to false"
      exit 1
    fi
  fi

  function not_supported_os(){
    msg ko "Oops This OS is not supported yet !"
    echo "    Do not hesitate to contribute for a better compatibility
              $MY_REPO_URL"
    exit 1
  }
}

##################
### Commons checks

if [ $USER_ID -ne 0 ] && $REQUIRE_ROOT ; then
   msg ko "Oops, this script must be run as root !"
   exit 1
fi

if [[ $# -eq 0 ]] && $REQUIRE_OPTION; then
  msg ko "Oops, This script require options"
  usage
  exit 1
fi

# Parsing positional option and arguments

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -d | --debug)
      DEBUG=true
      shift 1
      ;;
      *)
      msg ko "$1 : Unkown option"
      usage
      exit 1
      ;;
  esac
done

detect_os

if $DEBUG; then
  debug
  exit 0
else
  main
fi

A simple script for a quick debian postinstall setup

# What does it do ?

- Change hostname  
- Configure `/etc/hosts` with IP and fqdn  
- Set root password  
- Create none Super User with password and SSH_Keys  
- Copy your favorite .bashrc  
- Copy your favorite sources.list  
- Configure openssh-server  
- Install and configure [Optional]  
  - NTP  
  - Fail2ban  
  - iptables  
  - Nullmailer  
  - Unnatended_upgrades  
  - Monitorix  

# Usage

## Clone the repo

```bash
apt install git -y
cd /tmp
git clone https://gitlab.com/maelj/debian_first_setup.git
cd debian_first_setup
```

## Modify files in files folder as you like

### ssh_keys.txt
Put here all your public keys you need.  
This file will be copy to ~/.ssh/authorized_keys  

### bashrc
Put here your favorite bashrc.  

### sources.list
Nothing to say...  

### Nullmailer
**- adminaddr:** Put here your mail. (ex: myserver@domain.tld)  
**- defaultdomain:** Put here your domain. (ex: domain.tld)  
**- remotes:** Put here your smtp setting.  

### Fail2ban
Two files `jail.local` and `iptables-common.local`.  

Default:  
- bantime: 1d  
- findtime: 1d  
- maxretry: 2  
- Watch on SSH on aggressive mode
- action: ban allport with drop

### Monitorix
One file `monitorix_local.conf`.    
Basic monitoring [please see documention](https://www.monitorix.org/documentation.html)  

### Iptables
Two files: `rules.v4` and `rules.v6`  

A little bit strict firewall.  
Drop everything exept:  
- IN SSH  
- IN ICMP  
- OUT HTTPs / HTTP  
- OUT SSH  
- OUT DNS  
- OUT SMTP  
- OUT ICMP  
- OUT NTP on debian pool server  
- OUT Whois (for fail2ban)

## Start setup.sh

As root you can now launch setup.sh.  
```bash
bash setup.sh
```

# Todo

- rkhunter
- portsentry

# Sources
- [Sécuriser le serveur](http://sdz.tdct.org/sdz/securiser-son-serveur-linux.html)

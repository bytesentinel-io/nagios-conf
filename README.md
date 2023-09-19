# Quick Guide: Nagios for your network monitoring

## Introduction

This is a quick guide to install and configure Nagios for your network monitoring. This guide is based on the following environment:

* Ubuntu 22.04.3 LTS
* Nagios Core 4.4.14

## Installation

### Auto-Install script

```bash
git clone https://github.com/bytesentinel-io/nagios-conf.git
cd nagios-conf

chmod +x install.sh
# ./install.sh <DIRECTORY> <VERSION>
./install.sh /tmp "4.4.14"
```

### Install Nagios Core

```bash
sudo apt-get update
sudo apt-get install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php7.4 libgd-dev openssl libssl-dev

cd /tmp
wget -O nagioscore.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.14.tar.gz
tar xzf nagioscore.tar.gz

cd /tmp/nagioscore-nagios-4.4.14/
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make all

sudo make install-groups-users
sudo usermod -a -G nagios www-data

sudo make install
sudo make install-daemoninit
sudo make install-commandmode
sudo make install-config

sudo make install-webconf
sudo a2enmod rewrite
sudo a2enmod cgi

sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

sudo systemctl restart apache2
sudo systemctl restart nagios
```
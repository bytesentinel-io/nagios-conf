#!/bin/bash

NAGIOS_VERSION=${$1; "4.4.14"}
DIR=$(cd $(dirname $0); pwd)
PACKAGE_LIST="autoconf gcc libc6 make wget apache2 php unzip libapache2-mod-php7.4 libgd-dev openssl libssl-dev"

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install nagios."
    exit 1
fi

if [ -z "$DIR" ]; then
    echo "Error: Can not get current directory."
    exit 1
fi

if [ -z "$NAGIOS_VERSION" ]; then
    echo "Error: Nagios version is empty."
    exit 1
fi

function check_package() {
    if ! dpkg -s $1 >/dev/null 2>&1; then
        echo "Installing $1..."
        apt-get install -y $1
    fi
}

function check_dependencies() {
    # Check if nagios is installed
    if [ -d "/usr/local/nagios" ]; then
        echo "Error: Nagios is already installed."
        exit 1
    fi

    # Check if nagios user exists
    if id -u nagios >/dev/null 2>&1; then
        echo "Error: Nagios user already exists."
        exit 1
    fi

    # Check if nagcmd group exists
    if getent group nagcmd >/dev/null 2>&1; then
        echo "Error: Nagcmd group already exists."
        exit 1
    fi

    # Check if nagios group exists
    if getent group nagios >/dev/null 2>&1; then
        echo "Error: Nagios group already exists."
        exit 1
    fi

    for package in $PACKAGE_LIST; do
        check_package $package
    done
}

function generate_password() {
    echo $(date +%s | sha256sum | base64 | head -c 32 ; echo)
}

function install_nagios() {
    cd $DIR
    wget -O nagios.tar.gz https://github.com/NagiosEnterprises/nagioscore/archive/nagios-$NAGIOS_VERSION.tar.gz
    tar xzf nagios.tar.gz

    cd nagioscore-nagios-$NAGIOS_VERSION
    ./configure --with-httpd-conf=/etc/apache2/sites-enabled
    make all

    make install-groups-users
    usermod -a -G nagcmd www-data

    make install

    make install-daemoninit

    make install-commandmode

    make install-config

    make install-webconf
    a2enmod rewrite
    a2enmod cgi

    # Generate password for nagiosadmin
    NAGIOS_PASSWORD=$(generate_password)
    htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin $NAGIOS_PASSWORD
    
    # Start nagios
    systemctl start apache2.service
    systemctl start nagios.service

    # Enable nagios to start on boot
    systemctl enable apache2.service
    systemctl enable nagios.service

    # Check nagios status
    systemctl status nagios.service

    # Check nagios admin password
    echo "Nagios admin password: $NAGIOS_PASSWORD"
}

check_dependencies
install_nagios
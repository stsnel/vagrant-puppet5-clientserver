#!/bin/sh

set -e

progress_message () {
  /usr/bin/perl -e 'print "*" x 80 . "\n"'
  echo "* $1"
  /usr/bin/perl -e 'print "*" x 80 . "\n"'
}

progress_message "Loading settings"
. /tmp/.env

progress_message "Determining OS version"
LSBRELEASECODENAME=$(lsb_release -cs)

if [ -z "$LSBRELEASECODENAME" ]
then
    echo "Error: unable to determine LSB release"
    exit 1
fi

if [ "$LSBRELEASECODENAME" != "xenial" -a "$LSBRELEASECODENAME" != "bionic" ]
then
    echo "Error: unexpected LSB release: $LSBRELEASECODENAME"
    exit 1
fi

progress_message "Installing nmap"
apt install -y nmap

progress_message "Downloading Puppet release package"
wget https://apt.puppetlabs.com/puppet5-release-$LSBRELEASECODENAME.deb

progress_message "Installing Puppet release package"
dpkg -i puppet5-release-$LSBRELEASECODENAME.deb
apt update

progress_message "Installing Puppet agent"
if [ "$PUPPETAGENTVERSIONCLIENT" = "latest" ]
then apt install -y puppet-agent
else apt install -y puppet-agent=$PUPPETAGENTVERSIONCLIENT
     apt-mark hold puppet-agent
fi

progress_message "Configuring puppet agent"
cat << PUPPETCONF > /etc/puppetlabs/puppet/puppet.conf
[main]

environment = production
certname = $CLIENTHOSTNAME
server = $SERVERHOSTNAME
PUPPETCONF

progress_message "Updating hosts file"
echo "$MASTERIP $SERVERHOSTNAME" >> /etc/hosts
echo "$CLIENTIP $CLIENTHOSTNAME" >> /etc/hosts

while nmap -Pn -p 8140 $SERVERHOSTNAME | grep /tcp | grep -v open
do echo Waiting for Puppet server to start ...
   sleep 1
done

progress_message "Running Puppet agent"
/opt/puppetlabs/bin/puppet agent -t || /bin/true

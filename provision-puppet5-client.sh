#!/bin/sh

. /tmp/settings.sh

apt install -y nmap

wget https://apt.puppetlabs.com/puppet5-release-xenial.deb
dpkg -i puppet5-release-xenial.deb
apt update
apt install -y puppet-agent

cat << PUPPETCONF > /etc/puppetlabs/puppet/puppet.conf
[main]

environment = production
certname = client.local
server = master.local
PUPPETCONF

echo "$MASTERIP master.local" >> /etc/hosts
echo "$CLIENTIP client.local" >> /etc/hosts

while nmap -Pn -p 8140 master.local | grep /tcp | grep -v open
do echo Waiting for Puppet server to start ...
   sleep 1
done

/opt/puppetlabs/bin/puppet agent -t

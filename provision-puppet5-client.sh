#!/bin/sh

. /tmp/.env

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

apt install -y nmap

wget https://apt.puppetlabs.com/puppet5-release-$LSBRELEASECODENAME.deb
dpkg -i puppet5-release-$LSBRELEASECODENAME.deb
apt update

if [ "$PUPPETAGENTVERSIONCLIENT" = "latest" ]
then apt install -y puppet-agent
else apt install -y puppet-agent=$PUPPETAGENTVERSIONCLIENT
     apt-mark hold puppet-agent
fi

cat << PUPPETCONF > /etc/puppetlabs/puppet/puppet.conf
[main]

environment = production
certname = $CLIENTHOSTNAME
server = $SERVERHOSTNAME
PUPPETCONF

echo "$MASTERIP $SERVERHOSTNAME" >> /etc/hosts
echo "$CLIENTIP $CLIENTHOSTNAME" >> /etc/hosts

while nmap -Pn -p 8140 $SERVERHOSTNAME | grep /tcp | grep -v open
do echo Waiting for Puppet server to start ...
   sleep 1
done

/opt/puppetlabs/bin/puppet agent -t

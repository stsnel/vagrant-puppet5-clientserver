#!/bin/sh

. /tmp/settings.sh

wget https://apt.puppetlabs.com/puppet5-release-xenial.deb
dpkg -i puppet5-release-xenial.deb
apt update
apt install -y puppetserver puppet-agent

echo "$MASTERIP master.local" >> /etc/hosts
echo "$CLIENTIP client.local" >> /etc/hosts

cat << PUPPETCONF > /etc/puppetlabs/puppet/puppet.conf
[main]
certname = master.local
PUPPETCONF

# Automatically generates CA certificate
/opt/puppetlabs/bin/puppet cert list

cat << CLIENTMANIFEST > /etc/puppetlabs/code/environments/production/manifests/client.local.pp
node 'client.local' {
  notify { 'test message':
    message => join(['Manifest loaded successfully. Hiera message: ',lookup('puppet5vagrant::message',String)],''),
  }
}
CLIENTMANIFEST

hieradir=/etc/puppetlabs/code/environments/production/data/nodes
mkdir -p $hieradir
cat << CLIENTHIERA > $hieradir/client.local.yaml
puppet5vagrant::message: 'Default hiera message'
CLIENTHIERA

cat << AUTOSIGNCONF > /etc/puppetlabs/puppet/autosign.conf
*.local
AUTOSIGNCONF

systemctl start puppetserver

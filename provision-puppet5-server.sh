#!/bin/sh

. /tmp/.env

wget https://apt.puppetlabs.com/puppet5-release-xenial.deb
dpkg -i puppet5-release-xenial.deb
apt update
apt install -y puppetserver puppet-agent

echo "$MASTERIP $SERVERHOSTNAME" >> /etc/hosts
echo "$CLIENTIP $CLIENTHOSTNAME" >> /etc/hosts

cat << PUPPETCONF > /etc/puppetlabs/puppet/puppet.conf
[main]
certname = $SERVERHOSTNAME
PUPPETCONF

# Automatically generates CA certificate
/opt/puppetlabs/bin/puppet cert list

cat << CLIENTMANIFEST > /etc/puppetlabs/code/environments/production/manifests/$CLIENTHOSTNAME.pp
node '$CLIENTHOSTNAME' {
  notify { 'test message':
    message => join(['Manifest loaded successfully. Hiera message: ',lookup('puppet5vagrant::message',String)],''),
  }
}
CLIENTMANIFEST

hieradir=/etc/puppetlabs/code/environments/production/data/nodes
mkdir -p $hieradir
cat << CLIENTHIERA > $hieradir/$CLIENTHOSTNAME.yaml
puppet5vagrant::message: 'Default hiera message'
CLIENTHIERA

cat << AUTOSIGNCONF > /etc/puppetlabs/puppet/autosign.conf
$AUTOSIGNWHITELIST
AUTOSIGNCONF

systemctl start puppetserver

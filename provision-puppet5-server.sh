#!/bin/sh
set -e
. /tmp/.env

wget https://apt.puppetlabs.com/puppet5-release-xenial.deb
dpkg -i puppet5-release-xenial.deb
apt update

if [ "$PUPPETAGENTVERSIONSERVER" = "latest" ]
then apt install -y puppet-agent
else apt install -y puppet-agent=$PUPPETAGENTVERSIONSERVER
     apt-mark hold puppet-agent
fi

if [ "$PUPPETSERVERVERSION" = "latest" ]
then apt install -y puppetserver
else apt install -y puppetserver=$PUPPETSERVERVERSION
     apt-mark hold puppetserver
fi

echo "$MASTERIP $SERVERHOSTNAME" >> /etc/hosts
echo "$CLIENTIP $CLIENTHOSTNAME" >> /etc/hosts

cat << PUPPETCONF > /etc/puppetlabs/puppet/puppet.conf
[main]
certname = $SERVERHOSTNAME
PUPPETCONF

# Automatically generates CA certificate
/opt/puppetlabs/bin/puppet cert list

manifestdir=/etc/puppetlabs/code/environments/production/manifests
cat << CLIENTMANIFEST > $manifestdir/$CLIENTHOSTNAME.pp
node '$CLIENTHOSTNAME' {
  notify { 'test message':
    message => join(['Manifest loaded successfully. Hiera message: ',lookup('puppet5vagrant::message',String)],''),
  }
}
CLIENTMANIFEST

cat << SERVERMANIFEST > $manifestdir/$SERVERHOSTNAME.pp
node '$SERVERHOSTNAME' {

    include apache
    include puppetboard
    include puppetdb
    include puppetdb::master::config

    class { 'python':
        pip        => 'present',
        virtualenv => 'present',
        dev        => 'present',
    }

    \$puppetssldir = '/etc/puppetlabs/puppet/ssl'
    \$puppetdbssldir = '/etc/puppetlabs/puppetdb/ssl'
    \$certinstallcmd = '/usr/bin/install --mode=0640 --owner=puppetdb --group=puppetdb'

    ensure_packages ( 'python-virtualenv', { ensure => present } )

    class { 'puppetboard::apache::vhost':
         vhost_name => "$SERVERHOSTNAME",
         port       => 5000,
    }
}
SERVERMANIFEST

hieradir=/etc/puppetlabs/code/environments/production/data/nodes
mkdir -p $hieradir
cat << CLIENTHIERA > $hieradir/$CLIENTHOSTNAME.yaml
puppet5vagrant::message: 'Default hiera message'
CLIENTHIERA

cat << SERVERHIERA > $hieradir/$SERVERHOSTNAME.yaml
puppetdb::globals::version: $PUPPETDBVERSION
puppetdb::listen_address: "0.0.0.0"
puppetdb::ssl_listen_address: $SERVERHOSTNAME
puppetdb::manage_package_repo: true
puppetdb::postgres_version: '9.6'
puppetdb::ssl_set_cert_paths: true
puppetdb::ssl_cert_path: '/etc/puppetlabs/puppetdb/ssl/public.pem'
puppetdb::ssl_key_path: '/etc/puppetlabs/puppetdb/ssl/private.pem'
puppetdb::ssl_ca_cert_path: '/etc/puppetlabs/puppetdb/ssl/ca.pem'
puppetdb::master::config::puppetdb_server: '$SERVERHOSTNAME'
puppetdb::master::config::enable_reports: true
puppetdb::master::config::manage_report_processor: true
puppetdb::master::config::manage_config: true
puppetdb::master::config::restart_puppet: true
puppetdb::master::config::puppet_service_name: 'puppetserver'

puppetboard::enable_catalog: true
puppetboard::revision: $PUPPETBOARDVERSION
SERVERHIERA

cat << AUTOSIGNCONF > /etc/puppetlabs/puppet/autosign.conf
$AUTOSIGNWHITELIST
AUTOSIGNCONF

systemctl start puppetserver

installmodulecmd="sudo /opt/puppetlabs/bin/puppet module install"
moduledir="/etc/puppetlabs/code/environments/production/modules"
$installmodulecmd --target-dir $moduledir puppetlabs/puppetdb
$installmodulecmd --target-dir $moduledir puppet/puppetboard
$installmodulecmd --target-dir $moduledir puppetlabs/apache
$installmodulecmd --target-dir $moduledir stankevich/python

# This initial install is needed for setting up the
# TLS certificate files
apt install puppetdb
/opt/puppetlabs/bin/puppetdb ssl-setup

sudo /opt/puppetlabs/bin/puppet apply $manifestdir/$SERVERHOSTNAME.pp
sudo systemctl restart puppetdb

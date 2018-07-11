#!/bin/sh

set -e

progress_message () {
  echo "********************************************************************************"
  echo "* $1"
  echo "********************************************************************************"
}

progress_message "Loading settings"
. /tmp/.env

progress_message "Determining OS version"
if [ -f "/etc/centos-release" ]
then
   yum -y install perl
   distribution=CentOS
   distributionversion=$(perl -e ' if ( `cat /etc/centos-release` =~ /^CentOS(?: Linux)? release (\d)\./ ) { print "$1\n" } else { print "Unknown" }' )

   if [ "$distributionversion" != "6" -a "$distributionversion" != "7" ]
   then echo Error: unsupported CentOS version: $distributionversion
        exit 1
   fi
elif [ -x "/usr/bin/lsb_release" ]
then
   distribution=$(lsb_release -is)
   distributionversion=$(lsb_release -cs)

   if [ "$distribution" != "Ubuntu" ]
   then echo Unsupported distribution: $distribution
        exit 1
   fi

   if [ "$distributionversion" != "xenial" -a "$distributionversion" != "bionic" ]
   then echo "Error: unsupported distribution version: $distributionversion"
        exit 1
   fi
fi

progress_message "Installing nmap"
if [ "$distribution" = "CentOS" ]
then yum install -y nmap
elif [ "$distribution" = "Ubuntu" ]
then apt install -y nmap
else
     echo "Error: no way to install nmap for distribution $distribution"
     exit 1
fi

if [ "$distribution" = "CentOS" ]
then
    progress_message "Downloading and installing Puppet release package"
    rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-$distributionversion.noarch.rpm
elif [ "$distribution" = "Ubuntu" ]
then
    progress_message "Downloading Puppet release package"
    wget https://apt.puppetlabs.com/puppet5-release-$distributionversion.deb
    progress_message "Installing Puppet release package"
    dpkg -i puppet5-release-$distributionversion.deb
    apt update
else
    echo "Error: no way to add puppet repository for distribution $distribution"
    exit 1
fi

progress_message "Installing Puppet agent"
if [ "$distribution" = "CentOS" ]
then
     if [ "$PUPPETAGENTVERSIONCLIENT" = "latest" ]
     then yum install -y puppet-agent
     else yum install -y puppet-agent-$PUPPETAGENTVERSIONCLIENT
          yum install -y yum-plugin-versionlock
          yum versionlock puppet-agent-$PUPPETAGENTVERSIONCLIENT
     fi
elif [ "$distribution" = "Ubuntu" ]
then
     if [ "$PUPPETAGENTVERSIONCLIENT" = "latest" ]
     then apt install -y puppet-agent
     else apt install -y puppet-agent=$PUPPETAGENTVERSIONCLIENT
          apt-mark hold puppet-agent
     fi
else
     echo "Error: no way to install puppet agent for distribution $distribution"
     exit 1
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

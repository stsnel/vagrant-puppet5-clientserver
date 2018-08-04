# vagrant-puppet5-clientserver

Vagrant file and provisioning scripts for a Puppet 5 server and client

# Intended purpose

These scripts configure a local Puppet 5 server VM and a VM running the Puppet 5 agent. These VMs can be
used for local testing of puppet modules. PuppetDB and Puppetboard are also installed on the puppet
master. The default Puppetboard URL is: http://192.168.2.6:5000

The provisioning script for the puppet master is not suitable for configuring a publically accessible server,
because of settings that would be insecure on a nonlocal environment. For example, the puppet master is
configured with autosigning enabled, and access to Puppetboard is not secured.

# System requirements

This Vagrantfile has been tested with Vagrant 2.0.2. It requires the vagrant-env plugin, which
can be installed with: _vagrant plugin install vagrant-env_

Vagrant requires approximately 4 to 5 GB of memory for the basic configuration. By default, the server
VM is assigned up to 4 GB and the client VM is assigned up to 2 GB. If you're testing an application
stack on the client VM, you might have to increase the amount of assigned memory in the .env file.

# Supported client distributions

* CentOS 6
* CentOS 7
* Ubuntu 16.04 LTS
* Ubuntu 18.04 LTS

# Usage

* Optionally customize the configuration in the .env file
* _vagrant up_

# Scripts provided:

On the host:
* redeploy-client: destroys and re-deploys the client VM. Useful for redeploying the client VM after
  changes in the .env file.

On the server:
* vldt : validates Puppet DSL, Hiera YAML and ERB files

On the client:
* puprun: performs a puppet agent run (shorthand for: _sudo /opt/puppetlabs/bin/puppet agent -t_)

# vagrant-puppet5-clientserver

Vagrant file and provisioning scripts for a Puppet 5 server and client

# Intended purpose

The purpose of these scripts is to set up a local Puppet 5 server VM and a VM running the Puppet 5 agent
for local testing of Puppet modules. The provisioning script for the puppet master is not suitable
for configuring a publically accessible server, because it has unsafe security settings.

# System requirements

This Vagrantfile has been tested with Vagrant 2.0.2. It requires the vagrant-env plugin, which
can be installed with: _vagrant plugin install vagrant-env_

Vagrant requires approximately 3 to 4 GB memory for the basic configuration. By default, the server
VM is assigned up to 4 GB and the client VM is asssigned up to 2 GB. If you're testing an application
stack on the client VM, you might have to increase the amount of assigned memory in the .env file.

# Usage

* Optionally customize the configuration in the .env file
* _vagrant up_

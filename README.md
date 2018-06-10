# vagrant-puppet5-clientserver

Vagrant file and provisioning scripts for a Puppet 5 server and client

# Intended purpose

The purpose of these scripts is to set up a Puppet 5 server VM and a VM running the Puppet 5 agent
for local testing of Puppet modules.  The provisioning script for the puppet master is not suitable
for configuring a publically accessible puppet master, because it has permissive security settings.

# System requirements

Vagrant requires approximately 3 to 4 GB memory for the basic configuration. By default, the server
VM is assigned up to 4 GB and the client VM is asssigned up to 2 GB. If you're testing an application
stack on the client VM, you might have to increase its memory setting in the Vagrant file.

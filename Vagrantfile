Vagrant.configure("2") do |config|

  config.env.enable

  # Workaround for Vagrant issue with TTY errors - copied from
  # https://superuser.com/questions/1160025/how-to-solve-ttyname-failed-inappropriate-ioctl-for-device-in-vagrant
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.define "server" do |server|
    server.vm.box = ENV['SERVERBOXNAME']
    server.vm.provider "virtualbox" do |v|
      v.memory = ENV['SERVERMEMORY']
      # Synchronize clock in one step if difference is more than 1000 ms / 1s
      # Copied from https://stackoverflow.com/questions/19490652/how-to-sync-time-on-host-wake-up-within-virtualbox
      v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
    end
    server.vm.provision "file", source: ".env", destination: "/tmp/.env"
    server.vm.provision "file", source: "vldt", destination: "/tmp/vldt"
    server.vm.provision :shell, :path => 'provision-puppet5-server.sh'
    server.vm.network "private_network", ip: ENV['MASTERIP']
  end

  config.vm.define "client" do |client|
    client.vm.box = ENV['CLIENTBOXNAME']
    client.vm.provider "virtualbox" do |v|
      v.memory = ENV['CLIENTMEMORY']
      # Synchronize clock in one step if difference is more than 1000 ms / 1s
      # Copied from https://stackoverflow.com/questions/19490652/how-to-sync-time-on-host-wake-up-within-virtualbox
      v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
    end
    client.vm.provision "file", source: ".env", destination: "/tmp/.env"
    client.vm.provision :shell, :path => 'provision-puppet5-client.sh'
    client.vm.network :private_network, ip: ENV['CLIENTIP']
  end
end

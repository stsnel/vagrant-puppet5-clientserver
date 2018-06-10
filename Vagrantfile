Vagrant.configure("2") do |config|

  # Workaround for Vagrant issue with TTY errors - copied from
  # https://superuser.com/questions/1160025/how-to-solve-ttyname-failed-inappropriate-ioctl-for-device-in-vagrant
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.define "server" do |server|
    server.vm.box = "ubuntu/xenial64"
    server.vm.provider "virtualbox" do |v|
      v.memory = 4096
    end
    server.vm.provision "file", source: "settings.sh", destination: "/tmp/settings.sh"
    server.vm.provision :shell, :path => 'provision-puppet5-server.sh'
    server.vm.network "private_network", ip: "192.168.2.6"
  end

  config.vm.define "client" do |client|
    client.vm.box = "ubuntu/xenial64"
    client.vm.provider "virtualbox" do |v|
      v.memory = 2048
    end
    client.vm.provision "file", source: "settings.sh", destination: "/tmp/settings.sh"
    client.vm.provision :shell, :path => 'provision-puppet5-client.sh'
    client.vm.network :private_network, ip: "192.168.2.5"
  end
end

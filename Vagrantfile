## Copyright 2015 StreamBright LLC
#
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
##;; You may obtain a copy of the License at
#
##     http://www.apache.org/licenses/LICENSE-2.0
#
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.

# -*- mode: ruby -*-
# vi: set ft=ruby :

ssh_key = File.open(File.join(Dir.home, '.ssh/id_rsa.pub'), "rb").read
unix_user = 'centos'
unix_group = 'centos'

$script = <<SCRIPT
SYSTEM_USER=$(grep "^#{unix_user}" /etc/passwd)
if [ -z "$UNIX_USER" ]; then
    echo "#{unix_user} user does not exists"
    adduser "#{unix_user}" -m
    mkdir -p ~#{unix_user}/.ssh/
    echo "#{ssh_key}" >> ~#{unix_user}/.ssh/authorized_keys
    chmod 700 ~#{unix_user}/.ssh/
    chmod 600 ~#{unix_user}/.ssh/authorized_keys
    chown -R #{unix_user}:#{unix_group} ~#{unix_user}/.ssh
    echo "#{unix_user} ALL=(ALL)       NOPASSWD:       ALL" >> /etc/sudoers
fi
SCRIPT

Vagrant.configure(2) do |config|
  servers = {
   :"riak1"  => '10.10.10.11',
   :"riak2"  => '10.10.10.12',
   :"riak3"  => '10.10.10.13'
  }
  servers.each do |server_name, server_ip|
    config.vm.define server_name do |server_conf|
      server_conf.vm.box       = "centos7"
      server_conf.vm.host_name = server_name.to_s + ".local"
      server_conf.vm.network "private_network", ip: server_ip
      config.vm.synced_folder ".", "/vagrant", disabled: true
      config.vm.provision "shell", inline: $script
    end
  end
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.customize ['modifyvm', :id, "--chipset", "ich9"]
    vb.memory = 2048
    vb.cpus = 4
  end
end


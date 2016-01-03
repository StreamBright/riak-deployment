# Automating Riak cluster deployment with Ansible

## Creating dev environment locally

CentOS 7 must be registered with Vagrant before we can spin up the cluster.

```bash
$ vagrant box list
centos7         (virtualbox, 0)
```

### Registering centos7

Adding a box:

```bash
vagrant box add centos7 https://github.com/holms/vagrant-centos7-box/releases/download/7.1.1503.001/CentOS-7.1.1503-x86_64-netboot.box
```

Running init:

```
vagrant init centos7
```

### Running Vagrant

Running it the first time takes a bit longer than usual. Vagrant configures 3 VMs for running Ansible on them

```bash
node:riak-deployment user$ vagrant up
Bringing machine 'riak1' up with 'virtualbox' provider...
Bringing machine 'riak2' up with 'virtualbox' provider...
Bringing machine 'riak3' up with 'virtualbox' provider...
==> riak1: Importing base box 'centos7'...
==> riak1: Matching MAC address for NAT networking...
==> riak1: Setting the name of the VM: riak-deployment_riak1_1451839869567_51963
==> riak1: Clearing any previously set forwarded ports...
==> riak1: Clearing any previously set network interfaces...
==> riak1: Preparing network interfaces based on configuration...
```

Checking if the VMs are running:

```bash
node:riak-deployment user$ vagrant status
Current machine states:

riak1                     running (virtualbox)
riak2                     running (virtualbox)
riak3                     running (virtualbox)

This step needs a bit of time to run the first time, not recommended for 3G users. After a successful initial deployment the provisioned cluster can be managed without internet access.
```

### Adding extra storage

We need to add extra device so that we emulate the production environment perfectly. This allows us to gain confidence about no surprises in prod.

Creating images:

```bash
node:riak-deployment user$ n=1 ; 
for i in $(VBoxManage list vms| egrep -o 'riak-deployment_riak._[0-9]+_[0-9]+'); do 
  VBoxManage createhd -filename riak${n}.second.dsk.vdi --size 51200 ; 
  let n=n+1 ; 
done

0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: c9b67f52-ea2c-4946-bf2f-913aecda41cb
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: 48250e38-4246-4650-b3b7-6e8d08a3812c
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Medium created. UUID: c3c7751b-5f4b-474b-a460-f1a303e3bcef

```
Checking images:

```bash
node:riak-deployment user$ ls -alrth *.vdi
-rw-------  1 user  staff   2.0M Jan  3 17:59 riak2.second.dsk.vdi
-rw-------  1 user  staff   2.0M Jan  3 17:59 riak1.second.dsk.vdi
-rw-------  1 user  staff   2.0M Jan  3 17:59 riak3.second.dsk.vdi
```

Attaching images:

```bash
node:riak-deployment user$ vagrant halt
==> riak3: Attempting graceful shutdown of VM...
==> riak2: Attempting graceful shutdown of VM...
==> riak1: Attempting graceful shutdown of VM...

node:riak-deployment user$ n=1 ; 
for i in $(VBoxManage list vms| egrep -o 'riak-deployment_riak._[0-9]+_[0-9]+'); do 
  VBoxManage storageattach $i --storagectl 'SATA Controller' --port 1 --device 0 --type 'hdd' --medium "riak${n}.second.dsk.vdi"
  let n=n+1
done

node:riak-deployment user$ vagrant up
Bringing machine 'riak1' up with 'virtualbox' provider...
Bringing machine 'riak2' up with 'virtualbox' provider...
Bringing machine 'riak3' up with 'virtualbox' provider...
==> riak1: Clearing any previously set forwarded ports...
==> riak1: Clearing any previously set network interfaces...
==> riak1: Preparing network interfaces based on configuration...

```

We can verify the images being added:

```bash
n=1 ; 
for i in $(VBoxManage list vms| egrep -o 'riak-deployment_riak._[0-9]+_[0-9]+'); do 
  VBoxManage showvminfo $i | grep 'SATA' ; 
done | egrep '\(1\, 0\)'
```

We can go ahead an install Riak on the freshly provisioned VMs.

### Deploying Riak


```bash
ansible-playbook riak.yml -i hosts.dev -v -f 3
```

## Running Riak in prod

The only difference between dev and prod is the parameters in the hosts files.

One example of a AWS cluster:

```yaml
[riak-servers]

50.10.10.11   riak_node=riak ip_int=10.10.10.11
52.10.10.12   riak_node=riak ip_int=10.10.10.12
54.10.10.13   riak_node=riak ip_int=10.10.10.13

[riak-servers:vars]
ebs_device=/dev/xvdb
env=prod
data_folder=/data
riak_server_int=10.10.10.11
riak_server_ext=50.10.10.11

```

## Additional resources


### Stating and stopping Riak

On all of the nodes:

```bash
ansible riak-servers -a "sudo /etc/init.d/riak restart" -i hosts.dev -f 3
```

Some of the nodes:

```bash
ansible riak-servers -a "sudo /etc/init.d/riak restart" -i hosts.dev --limit 10.10.10.11 -f 3
```

Checking Ring status:

```bash
ansible riak-servers -a "sudo /sbin/riak-admin member-status" -i hosts.dev -f 3
```



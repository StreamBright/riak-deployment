
vagrant halt

n=1  
for i in $(VBoxManage list vms| egrep -o 'riak-deployment_riak._[0-9]+_[0-9]+'); do 
  VBoxManage createhd -filename riak${n}.second.dsk.vdi --size 51200  
  let n=n+1  
done


n=1 
for i in $(VBoxManage list vms| egrep -o 'riak-deployment_riak._[0-9]+_[0-9]+'); do 
  VBoxManage storageattach $i --storagectl 'SATA Controller' --port 1 --device 0 --type 'hdd' --medium "riak${n}.second.dsk.vdi"
  let n=n+1
done

vagrant up


n=1 
for i in $(VBoxManage list vms| egrep -o 'riak-deployment_riak._[0-9]+_[0-9]+'); do 
  VBoxManage showvminfo $i | grep 'SATA' ; 
done | egrep '\(1\, 0\)'

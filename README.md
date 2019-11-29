# repository
## Install CoreOS to ESXi

1. In ESXi create CoreOS container with no HDD and 2GB of RAM
2. Copy vmdk to ESXi Directory (ie. /volumes/###/CoreOS)
3. SSH to ESXi and convert the vmdk

```sh
vmkfstools -i coreos_production_vmware_insecure_image.vmdk coreos.vmdk -d thin -a lsilogic
```
4. Mount vmdk to VM and boot
5. SSH to CoreOS using insecure key
```sh
ssh -i <path_to_key>/insecure_ssh_key core@<your_coreos1_ip>
```
## Pull repo and initialize compose file
```sh
git clone https://github.com/kernelstubbs/repository.git /opt/docker/homelab
sudo sh /opt/docker/homelab/docker-init.sh
```

## Links

http://www.vreference.com/2014/06/09/deploy-coreos-into-your-esxi-lab/
 
 
http://beta.release.core-os.net/amd64-usr/current/coreos_production_vmware_insecure.zip
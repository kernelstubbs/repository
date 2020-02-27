# repository
## Requirements

1. Domain Name
2. Cloudflare DNS and API token
3. NordVPN Account
4. Plex Account/Claim Token
5. NAS or NFS server with volumes pre-created
6. For guacamole, init.db must be generated and copied ot the init DIR (per instruction on their DOcker page)

## 1. Install Ubuntu to ESXi

## 2. Pull repo and initialize compose file
```sh
git clone https://github.com/kernelstubbs/repository.git /opt/docker/homelab
sudo sh /opt/docker/homelab/docker-init.sh
```

## Links

http://www.vreference.com/2014/06/09/deploy-coreos-into-your-esxi-lab/
 
 
http://beta.release.core-os.net/amd64-usr/current/coreos_production_vmware_insecure.zip
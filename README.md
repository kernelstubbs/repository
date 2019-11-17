# To deploy from scratch
```sh
docker swarm init
git clone https://github.com/kernelstubbs/repository.git /opt/docker 
cd /opt/docker
########################################
### make modifications to .env files ###
########################################
docker stack up -c docker-compose.yml homelab
```



TO-DO

Add traefik for pihole, esxi and NAS
Fix rcon API for traefik
Fix deluge api for traefik
Replace watchtower with something that doesn't crash containers in VPN networks

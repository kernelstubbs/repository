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

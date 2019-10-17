# repository


[Install OS to ESXi]
    2GB + of RAM


[Install Docker-Compose]
sudo su -
mkdir -p /opt/bin
PATH=$PATH:/opt/bin
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose
chmod +x /opt/bin/docker-compose

mkdir /opt/docker

git clone https://github.com/kernelstubbs/repository.git /opt/docker

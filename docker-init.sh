#!/bin/bash

# test for root and exit
[ "$EUID" -ne 0 ] && echo "Please run as root" && exit
# Assuming GIT is installed and repo is pulled already...but if the code is copypasted here it be
[ -x "$(command -v git)" ] || yum install git -y
# Clone the repo
[ "$(ls -A /opt/docker/homelab)" ] || git clone https://github.com/kernelstubbs/repository.git /opt/docker/homelab

if ! [ -x "$(command -v docker-compose)" ]
then
    if ! test -f "/opt/bin"
    then 
        echo hurrrdurrr
        #mkdir -p /opt/bin
        if ! echo "$PATH"|grep -q "/opt/bin"
        then 
            echo hurderrrrr
            #PATH=$PATH:/opt/bin
        fi
    fi
    version=curl -fsSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | sed 's#.*tag/##g'
    curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose
    chmod +x /opt/bin/docker-compose
fi

function validate_secret () {
    IFS='-' read -r -a secArray <<< "$1"
    secType=${secArray[0]}
    secTarget=${secArray[1]}
    secVal=${secArray[2]}
    case $secType in
        env) echo "$1 : environment variable"
           ;;
        sec) echo "$1 : secret"
           ;;
    esac
    #sed 's/word1/word2/g'

    #if ! grep -Fq $1 "./.env"; then
    #    echo
    #    echo $1 does not exist
    #    read -p 'Secret: ' secret
    #    echo "$1=$secret" >> ./.env
    #fi
}

# Find any .env ${#######} Vars in docker-compose.yml and populate them
dotEnv=($(grep '\${.*}' "/opt/docker/homelab/docker-compose.yml"))

# Find any empty values in ./env/*.env and change them
envFiles=/opt/docker/homelab/env/*.env
for file in $envFiles
do
    # || prevents last line from being skipped if it lacks `n
    while read line || [[ -n "$line" ]]
    do
        # skip commented lines
        if ! grep -q '^#' <<< "$line"
        then
            # if the line ends in # or = we're going to assume it needs populating.
            if grep -Eq '#$|=$' <<< "$line"
            then
                varTarget=$(echo $file|rev|cut -d'/' -f1|rev)
                varName=$(echo $line|tr -d '#','=')
                #read -p "Enter value for $varTarget - $varName: " varValue </dev/tty
                #sed -i '' "s/$line/$varName=$varValue/g" $file
                echo $line
            fi
        fi
    done <$file # file
done

echo ${secrets[1]}

secrets=( \
    "env-global-TZ" \
    "env-pihole-WEBPASSWORD" \
    "env-traefik-CF_API_KEY" \
    "env-plex-PLEX_CLAIM" \
    "sec-traefik-SSH"
    )
    

if test -f "./.env"; then
    touch "./.env"
fi

for i in ${secrets[@]}
do
    validate_secret $i
done
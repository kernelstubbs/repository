#!/bin/bash

workingDIR = "/opt/docker/homelab"

# test for root and exit
[ "$EUID" -ne 0 ] && echo "Please run as root" && exit
# Assuming GIT is installed and repo is pulled already...but if the code is copypasted here it be
[ -x "$(command -v git)" ] || yum install git -y
# Clone the repo
[ "$(ls -A $workingDIR)" ] || git clone https://github.com/kernelstubbs/repository.git $workingDIR

if ! [ -x "$(command -v docker-compose)" ]
then
    # See if /opt/bin exists and if it doesn't, create and add to path
    test -f "/opt/bin" || mkdir -p /opt/bin
    echo "$PATH"|grep -q "/opt/bin" || PATH=$PATH:/opt/bin
  
    version=curl -fsSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | sed 's#.*tag/##g'
    curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose
    chmod +x /opt/bin/docker-compose
fi

# Find any .env ${#######} Vars in docker-compose.yml and populate them in ./.env
dotEnv=$(grep '\${.*}' "$workingDIR/docker-compose.yml")
echo $dotEnv && test -f "$workingDIR/.env" || touch "$workingDIR/.env"
for secret in $dotEnv
do
    secName=$(echo $secret | cut -d "{" -f2 | cut -d "}" -f1)
    read -p "Enter value for \${$secName}: " secVal
    echo "$secName=$secVal" >> "$workingDIR/.env"
done

# Find any empty values in ./env/*.env and change them
envFiles=$workingDIR/env/*.env
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
                read -p "Enter value for $varTarget - $varName: " varValue </dev/tty
                sed -i '' "s/$line/$varName=$varValue/g" $file
            fi
        fi
    done <$file
done


# for the eventuality of swarm mode...

#secrets=( \
#    "env_traefik_SECRET_1" \
#    "sec_global_SECRET_2"\
#    )
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

    # pseudo code
    # for each secret do docker secret create secret secVal blah blah blah
}

for i in ${secrets[@]}
do
    validate_secret $i
done
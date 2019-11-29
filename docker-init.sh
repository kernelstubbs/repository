#!/bin/bash
set -Euo pipefail

workingDIR="/opt/docker/homelab"

# test for root and exit
[ "$EUID" -ne 0 ] && echo "Please run as root" && exit
# Assuming GIT is installed and repo is pulled already...but if the code is copypasted here it be
[ -x "$(command -v git)" ] || yum install git -y
# Clone the repo if the working directory isn't populated
[ "$(ls -A $workingDIR)" ] || git clone https://github.com/kernelstubbs/repository.git $workingDIR

# Test for and install docker-compose in /opt/bin and add it to the path (since running in su, path may need to be modified per-user)
if ! [ -x "$(command -v docker-compose)" ]
then
    # See if /opt/bin exists and if it doesn't, create and add to path
    test -f "/opt/bin" || mkdir -p /opt/bin
    echo "$PATH"|grep -q "/opt/bin" || PATH=$PATH:/opt/bin
  
    version=curl -fsSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | sed 's#.*tag/##g'
    curl -L "https://github.com/docker/compose/releases/download/$version/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose
    chmod +x /opt/bin/docker-compose
fi

# store key pairs in answers.csv to retrieve after docker pulls of updated compose files.
answerFile="$workingDIR/answerfile.csv"
[ -f $answerFile ] || echo "TARGET,KEY,VALUE" >> $answerFile

# Find any .env ${#######} Vars in docker-compose.yml and populate them in ./.env
dotEnv=$(grep '\${.*}' "$workingDIR/docker-compose.yml")
dotEnvFile="$workingDIR/.env"

for secret in $dotEnv
do
    secName=$(echo $secret | cut -d "{" -f2 | cut -d "}" -f1)
    secVal=""
    ansVal=$(grep "ENV,$secName," $answerFile)
    envVal=$(grep "$secName=" $dotEnvFile )

    echo $envVal
    if ! test -z "$ansVal"; then
        echo "Value for \${$secName} found in answer file"
        IFS=',' read -ra array <<< "$ansVal"
        secVal=${array[2]}
    elif test -z "$envVal"; then
        read -p "Enter value for \${$secName}: " secVal
    else
        echo poop
    fi
    [ -z "$envVal" ] && echo "$secName=$secVal" >> $dotEnvFile # Add to .env if it's not already there
    [ -z "$ansVal" ] && echo "ENV,$secName,$secVal" >> $answerFile # Add to answer file if it's not already there
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
                # strip the path from the file name for cleanliness
                varTarget=$(echo $file|rev|cut -d'/' -f1|rev)
                # strip '=' and '#' from the line to get the variable name
                varName=$(echo $line|tr -d '#','=')
                read -p "Enter value for $varTarget - $varName: " varValue </dev/tty
                # replace the line with user input
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

#for i in ${secrets[@]}
#do
#    validate_secret $i
#done
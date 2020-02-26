#!/bin/bash
set -Euo pipefail

workingDIR="/opt/docker/homelab"

# test for root and exit
[ "$EUID" -ne 0 ] && echo "Please run as root" && exit
# Testing for GIT and CURL
# TODO - improve package detection to work with apt, yum and others
echo "Testing for GIT and CURL..."
if ["$(command -v yum)"]; then
    echo "yum detected..."
    [ -x "$(command -v git)" ] || yum install git
    [ -x "$(command -v curl)" ] || yum install curl   
elif ["$(command -v rpm-ostree)"]; then
    echo "rpm detected..."
    [ -x "$(command -v git)" ] || rpm-ostree install git
    [ -x "$(command -v curl)" ] || rpm-ostree install curl
else
    echo "No package manager detected" && exit
fi

# Clone the repo if the working directory is empty, rest if it's not
if [ "$(ls -A $workingDIR)" ]; then
    # A hard reset will wipe all the files but keep the answerfile.csv with env variables in it to repopulate
    read -r -p "Reset repo to default? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            git --git-dir=$workingDIR/.git fetch --all
            git --git-dir=$workingDIR/.git reset --hard origin/master
            ;;
        *)
            ;;
    esac
else   
    git clone https://github.com/kernelstubbs/repository.git $workingDIR
fi

# Test for and install docker-compose in /opt/bin and add it to the path (since running in su, path may need to be modified per-user)
composeVer=$(curl -fsSLI -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest | sed 's#.*tag/##g')
if [ -x "$(command -v docker-compose)" ] | [ $(docker-compose version --short) -eq $composeVer ]; then
    # See if /opt/bin exists and if it doesn't, create and add to path
    test -f "/opt/bin" || mkdir -p /opt/bin
    echo "$PATH"|grep -q "/opt/bin" || PATH=$PATH:/opt/bin
    curl -L "https://github.com/docker/compose/releases/download/$composeVer/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose
    chmod +x /opt/bin/docker-compose
fi

# store key pairs in answers.csv to retrieve after docker pulls of updated compose files.
answerFile="$workingDIR/answerfile.csv"
[ -f $answerFile ] || echo "TARGET,KEY,VALUE" >> $answerFile

# Find any .env ${#######} Vars in docker-compose.yml and populate them in ./.env
dotEnv=$(grep '\${.*}' "$workingDIR/docker-compose.yml")
dotEnvFile="$workingDIR/.env"
[ -f $dotEnvFile ] || touch $dotEnvFile

for secret in $dotEnv
do
    secName=$(echo $secret | cut -d "{" -f2 | cut -d "}" -f1)
    ansVal=$(grep "ENV,$secName," $answerFile)
    envVal=$(grep "$secName=" $dotEnvFile )

    if ! test -z "$ansVal"; then
        echo "Value for \${$secName} found in answer file"
        IFS=',' read -ra array <<< "$ansVal"
        secVal=${array[2]}
    elif ! test -z "$envVal"; then
        echo "Value for \${$secName} found in .env file"
        IFS='=' read -ra array <<< "$envVal"
        secVal=${array[1]}
    else
        read -p "Enter value for \${$secName}: " secVal
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
        grep -q '^#' <<< "$line" && continue
        # if the line ends in # or = we're going to assume it needs populating.
        if grep -Eq '#$|=$' <<< "$line"; then
            # strip the path from the file name for cleanliness
            varTarget=$(echo $file|rev|cut -d'/' -f1|rev)
            # strip '=' and '#' from the line to get the variable name
            varName=$(echo $line|tr -d '#','=')
            # check the answewr file to see if a value exists
            ansVal=$(grep "$varTarget,$varName," $answerFile)
            if ! test -z "$ansVal"; then
                echo "Value for $varName found in answer file"
                IFS=',' read -ra array <<< "$ansVal"
                varVal=${array[2]}
            else
                read -p "Enter value for $varTarget - $varName: " varVal </dev/tty
                # replace the line with user input
            fi
            sed -i "s/$line/$varName=$varVal/g" $file
            [ -z "$ansVal" ] && echo "$varTarget,$varName,$varVal" >> $answerFile # Add to answer file if it's not already there
        fi
    done <$file
done
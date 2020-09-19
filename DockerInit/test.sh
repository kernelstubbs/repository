# Use this to repair the plex database if it becomes corrupted.

plexCTR="plex"
dbFile="/config/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"

OW='\e[1A\e[K'  # Overwrite previous line
NC='\033[0m'    # no colour
GR='\033[0;32m' # green
RD='\033[0;31m' # red

runCMD () {
    echo -e "${NC}[    ] ${1}"
    { # try
        eval ${2} 2> /dev/null \
        && \
        echo -e "${OW}[${GR} OK ${NC}]${1}"
    } || { # catch
        echo -e "${OW}[${RD}FAIL${NC}]${1}"
    }
}

runCMD "Do thing ONE" \
    "ls -la"

runCMD "Do a thing that fails" \
    "cp totallynonesensefile.txt /dev/null/byebyefile.txt"

runCMD "Sleep for a second" \
    "sleep 1"

runCMD "Sleep for 2 seconds" \
    "sleep 2"

# Use this to repair the plex database if it becomes corrupted.

plexContainerName="plex"
dbDir="/config/Library/Application Support/Plex Media Server/Plug-in Support/Databases"

OW='\e[1A\e[K'  # Overwrite previous line
NC='\033[0m'    # no colour
GR='\033[0;32m' # green
RD='\033[0;31m' # red

runCMD () {
    echo -e "${NC}[    ] ${1}"
    { # try
        eval ${2} \
        && \
        echo -e "${OW}[${GR} OK ${NC}]${1}"
    } || { # catch
        echo -e "${OW}[${RD}FAIL${NC}]${1}" \
        && \
        exit
    }
}

runCMD "Backing up database" \
    "docker exec -d $plexContainerName cp \"$dbDir/com.plexapp.plugins.library.db\" \"$dbDir/com.plexapp.plugins.library.db.original\""

runCMD "Dropping Indexes" \
    "docker exec -d $plexContainerName sqlite3 \"${dbDir}/com.plexapp.plugins.library.db\" \"DROP index 'index_title_sort_naturalsort'\""

runCMD "Deleting migrations from schema" \
    "docker exec -d $plexContainerName sqlite3 \"${dbDir}/com.plexapp.plugins.library.db\" \"DELETE from schema_migrations where version='20180501000000'\""

runCMD "Dumping db to dump.sql" \
    "docker exec -d $plexContainerName sqlite3 \"${dbDir}/com.plexapp.plugins.library.db\" .dump > dump.sql"

runCMD "Deleting old database" \
    "docker exec -d $plexContainerName rm \"${dbDir}/com.plexapp.plugins.library.db\""

runCMD "Restoring dump.sql to new database" \
    "docker exec -d $plexContainerName sqlite3 \"${dbDir}/com.plexapp.plugins.library.db\" < dump.sql"

runCMD "Deleting db-shm" \
    "docker exec -d $plexContainerName rm \"${dbDir}/com.plexapp.plugins.library.db-shm\""

runCMD "Deleting db-wal" \
    "docker exec -d $plexContainerName rm \"${dbDir}/com.plexapp.plugins.library.db-wal\""

runCMD "Verifying database integrity" \
    "docker exec -d $plexContainerName sqlite3 \"${dbDir}/com.plexapp.plugins.library.db\" \"PRAGMA integrity_check\""
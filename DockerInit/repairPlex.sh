#! /bin/bash
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
        eval ${2} \
        && \
        echo -e "${OW}[${GR} OK ${NC}] ${1}"
    } || { # catch
        echo -e "${OW}[${RD}FAIL${NC}] ${1}" \
        && \
        exit
    }
}

runCMD "Backing up database" \
    "docker exec -d $plexCTR cp \"$dbFile\" \"$dbFile.original\""

runCMD "Dropping Indexes" \
    "docker exec -d $plexCTR sqlite3 \"${dbFile}\" \"DROP index 'index_title_sort_naturalsort'\""

runCMD "Deleting migrations from schema" \
    "docker exec -d $plexCTR sqlite3 \"${dbFile}\" \"DELETE from schema_migrations where version='20180501000000'\""

runCMD "Dumping db to dump.sql" \
    "docker exec -d $plexCTR sqlite3 \"${dbFile}\" .dump > dump.sql"

runCMD "Deleting old database" \
    "docker exec -d $plexCTR rm \"${dbFile}\""

runCMD "Restoring dump.sql to new database" \
    "docker exec -d $plexCTR sqlite3 \"${dbFile}\" < dump.sql"

runCMD "Deleting db-shm" \
    "docker exec -d $plexCTR rm \"${dbFile}-shm\""

runCMD "Deleting db-wal" \
    "docker exec -d $plexCTR rm \"${dbFile}-wal\""

runCMD "Verifying database integrity" \
    "docker exec -d $plexCTR sqlite3 \"${dbFile}\" \"PRAGMA integrity_check\""
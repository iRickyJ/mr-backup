#!/bin/sh

# mr-backup.sh
# author Troex Nevelin <troex@fury.scancode.ru>

BROOT="" # backup root directory
# include global config or exit
GCONF="${0}.conf"
if [ -f ${GCONF} ]
then
	. ${GCONF}
else
	echo "Error: global config ${GCONF} not found"
	exit 1
fi

# default options, do not change them here, use global/host config
POOL="${BROOT}/pool/"         # pool where current snapshots will be located
ARCHIVE="${BROOT}/archive/"   # backup history will go here
CONF="${BROOT}/conf.d/"       # config directory
HOST="$1"                    # hostname to backup
SSH="ssh"                    # ssh and it's options, eg. "ssh -p 2022"
REMOTE="root@${HOST}"        # remote source host and user for rsync
RBPATHS=""                   # space separated paths on remote server which will be backuped
OPTS="--archive --backup --compress --delete-after --delete-excluded --stats --verbose --numeric-ids" # default rsync opts
DATE=`date +%Y-%m-%d`        # 

if [ -z $BROOT ]
then
	echo "Error: backup root directory is not set"
	exit 1
fi

if [ ! -d $BROOT ]
then
	echo "Error: backup root directory ${BROOT} does not exist"
	exit 1
fi

if [ -z $HOST ]
then
	echo "Error: no host specified for backup"
	exit 1
fi

if [ `whoami` != "root" ];
then
	echo "Error: this script must be run as 'root'"
	exit 1
fi

# include local config if exists
LCONF="${CONF}${HOST}.conf"
if [ -f ${LCONF} ]
then
	. ${LCONF}
else
	echo "Error: host config ${LCONF} not found"
	exit 1
fi

if [ -z $RBPATHS ]
then
	echo "Error: remote backup paths are not set"
	exit 1
fi

# add exclude lists
EXCLUDE="${CONF}${HOST}.exclude"
if [ -f "${EXCLUDE}" ]
then
	OPTS="$OPTS --exclude-from=${EXCLUDE}"
fi

for RBP in $RBPATHS
do
	[ -n $RBP ] || continue
	FROM="${REMOTE}:${RBP}/"

	TO="${POOL}${HOST}${RBP}/"
	if [ ! -d $TO ]
	then
		mkdir -p $TO
	fi

	BBPATH="${ARCHIVE}${HOST}/${DATE}${RBP}"
	if [ ! -d ${BBPATH} ]
	then
		mkdir -p ${BBPATH}
	fi
	# add backup dir
	OPTS="${OPTS} --backup-dir=${BBPATH}"

	echo "Started ${HOST} backup at `date`"
	echo \# rsync ${OPTS} -e \"${SSH}\" ${FROM} ${TO}

	rsync ${OPTS} -e "${SSH}" ${FROM} ${TO}

	echo "Finished ${HOST} backup at `date`"
	echo

done

exit 0
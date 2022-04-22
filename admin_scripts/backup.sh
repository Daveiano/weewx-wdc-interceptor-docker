#!/bin/bash

# Parameters
# $1 - The named volume name.
# $2 - The desired output directory.

# see https://www.reddit.com/r/docker/comments/f8uwnl/comment/fio5ll8/?utm_source=share&utm_medium=web2x&context=3
if [[ $# -lt 2 ]] ; then
    echo "Wrong number of arguments!"
    echo "Usage: $0 <VOLUME> <OUTPUT_DIRECTORY>"
    echo "Example: \"$0 my-volume ./exports _new\""
    exit 1
fi

# Stop weewx service, see https://weewx.com/docs/usersguide.htm#Database
docker stop weewx

now=$(date +"%m_%d_%Y_%H_%M")

# Backup weewx.sdb from volume, see https://jareklipski.medium.com/backup-restore-docker-named-volumes-350397b8e362.
docker run --rm -v $1:/volume -v /$2:/backup alpine tar -cjf /backup/$1_$now.tar.bz2 -C /volume ./

# Restart weewx.
docker start weewx
#!/bin/bash

# Parameters
# $1 - The AWS cloudfront distribution ID.

if [[ $# -lt 1 ]] ; then
  echo "Wrong number of arguments!"
  echo "Usage: ./invalidate-12hourly.sh <CF DISTRIBUTION ID>"
  exit 1
fi

aws cloudfront create-invalidation --distribution-id "$1"\
    --paths "/*.html" "/NOAA/*.txt"
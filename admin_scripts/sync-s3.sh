#!/bin/bash

# Parameters
# $1 - The local path of the files.
# $2 - The s3 Bucket name and path.
# $3 - The AWS cloudfront distribution ID.

if [[ $# -lt 2 ]] ; then
    echo "Wrong number of arguments!"
    echo "Usage: $0 <LOCAL FILE PATH> <S3 BUCKET AND PATH> <OPTIONAL CF DISTRIBUTION ID>"
    echo "Example: \"$0 /var/lib/docker/volumes/weewx-html/_data weewx_web/\""
    exit 1
fi

aws s3 sync "$1" s3://"$2" --delete

if [[ $# -gt 2 ]] ; then
  aws cloudfront create-invalidation --distribution-id "$3" --paths '/*'
fi

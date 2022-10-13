#!/bin/bash

# Parameters
# $1 - The AWS cloudfront distribution ID.

if [[ $# -lt 1 ]] ; then
  echo "Wrong number of arguments!"
  echo "Usage: ./invalidate-hourly.sh <CF DISTRIBUTION ID>"
  exit 1
fi

aws cloudfront create-invalidation --distribution-id "$1"\
    --paths "/month*" "/year*" "/week.html" "/dwd/bwk_bodendruck_na_ana.png" "/dwd/bwk_bodendruck_weu_ana.png" "/dwd/SchilderLZ.jpg" "/dwd.html"
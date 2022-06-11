#!/bin/bash

# Parameters
# $1 - The AWS cloudfront distribution ID.

aws cloudfront create-invalidation --distribution-id "$3"\
    --paths "/month*" "/year*" "week.html"
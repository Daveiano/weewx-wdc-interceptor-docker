#!/bin/bash

# start rsyslog
echo 'Starting rsyslog'
# remove lingering pid file
rm -f /run/rsyslogd.pid
# start services
service rsyslog start
service cron start

# Initial weewx-DWD run.
mkdir /home/weewx/skins/weewx-wdc/dwd
/usr/local/bin/wget-dwd
/usr/local/bin/dwd-warnings
/usr/local/bin/dwd-cap-warnings --config=/home/weewx/weewx.conf --resolution=city
/usr/local/bin/dwd-mosmix --config=/home/weewx/weewx.conf --daily --hourly --json --database O461

# start weewx
echo 'Starting weewx'
"${WEEWX_HOME}"/bin/weewxd
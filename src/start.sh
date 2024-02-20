#!/bin/bash

echo "WEEWX_HOME: ${WEEWX_HOME}"

# start rsyslog
echo 'Starting rsyslog'
# remove lingering pid file
rm -f /run/rsyslogd.pid
# start services
service rsyslog start
service cron start

# Initial weewx-DWD run.
mkdir "${WEEWX_HOME}/skins/weewx-wdc/dwd"
/usr/local/bin/wget-dwd
/usr/local/bin/dwd-warnings
/usr/local/bin/dwd-cap-warnings --config="${WEEWX_HOME}/weewx.conf" --resolution=city
/usr/local/bin/dwd-mosmix --config="${WEEWX_HOME}/weewx.conf" --daily --hourly --json --database O461

# start weewx
echo 'Starting weewx'

# shellcheck source=/dev/null
. "${WEEWX_HOME}"/weewx-venv/bin/activate
weewxd --config "${WEEWX_HOME}/weewx.conf"
FROM python:3.10-buster

LABEL org.opencontainers.image.authors="David Baetge <david.baetge@gmail.com>"

ARG WEEWX_VERSION="5.0.2"
ARG WDC_VERSION="v3.5.0"
ARG WEEWX_UID=2749
ENV WEEWX_HOME="/home/weewx-data"

EXPOSE 9877

COPY src/start.sh /start.sh
COPY src/weewx-dwd.conf /tmp/weewx-dwd.conf
COPY src/extensions.py /tmp
RUN chmod +x /start.sh

# @see https://blog.nuvotex.de/running-syslog-in-a-container/
# @todo https://www.weewx.com/docs/5.0/usersguide/monitoring/#logging-on-macos
RUN apt-get update &&\
    apt-get install -q -y --no-install-recommends sudo=1.8.27-1+deb10u6 rsyslog=8.1901.0-1+deb10u2 python3-pip=18.1-5 python3-venv=3.7.3-1 cron=3.0pl1-134+deb10u1 python3-configobj=5.0.6-3 python3-requests=2.21.0-1 python3-paho-mqtt=1.4.0-1 &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system --gid ${WEEWX_UID} weewx &&\
    adduser --system --uid ${WEEWX_UID} --ingroup weewx weewx

RUN usermod -aG sudo weewx &&\
    echo "weewx ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure timezone.
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

WORKDIR /tmp

RUN wget -nv -O "weewx-interceptor.zip" "https://github.com/matthewwall/weewx-interceptor/archive/master.zip" &&\
    wget -nv -O "weewx-wdc-${WDC_VERSION}.zip" "https://github.com/Daveiano/weewx-wdc/releases/download/${WDC_VERSION}/weewx-wdc-${WDC_VERSION}.zip" &&\
    wget -nv -O "weewx-dwd.zip" "https://github.com/roe-dl/weewx-DWD/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-forecast.zip" "https://github.com/chaunceygardiner/weewx-forecast/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-mqtt.zip" https://github.com/matthewwall/weewx-mqtt/archive/master.zip &&\
    wget -nv -O "weewx-cmon.zip" "https://github.com/bellrichm/weewx-cmon/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-xaggs.zip" "https://github.com/tkeffer/weewx-xaggs/archive/master.zip" &&\
    wget -nv -O "weewx-xcumulative.tar.gz" "https://github.com/gjr80/weewx-xcumulative/releases/download/v0.1.0/xcum-0.1.0.tar.gz" &&\
    wget -nv -O "weewx-GTS.zip" "https://github.com/roe-dl/weewx-GTS/archive/master.zip"

RUN mkdir /tmp/weewx-wdc/ &&\
    unzip /tmp/weewx-wdc-${WDC_VERSION}.zip -d /tmp/weewx-wdc/

# weewx-dwd
RUN mkdir /tmp/weewx-dwd/ &&\
    unzip /tmp/weewx-dwd.zip -d /tmp/weewx-dwd/ &&\
    cp -R /tmp/weewx-dwd/weewx-DWD-master/usr/ / &&\
    cp -R /tmp/weewx-dwd/weewx-DWD-master/etc/ / &&\
    sed -i -z -e "s|PTH=\"/etc/weewx/skins/Belchertown/dwd\"|PTH=\"${WEEWX_HOME}/skins/weewx-wdc/dwd\"|g" /usr/local/bin/wget-dwd &&\
    sed -i -z -e "s|config = configobj.ConfigObj(\"/etc/weewx/weewx.conf\")|config = configobj.ConfigObj(\"${WEEWX_HOME}/weewx.conf\")|g" /usr/local/bin/dwd-warnings &&\
    sed -i -z -e "s|#/usr/local/bin/dwd-cap-warnings --weewx --resolution=city 2>/dev/null >/dev/null|/usr/local/bin/dwd-cap-warnings --weewx --resolution=city 2>/dev/null >/dev/null|g" /etc/cron.hourly/dwd &&\
    sed -i -z -e "s|#/usr/local/bin/dwd-mosmix --weewx --daily --hourly XXXXX 2>/dev/null >/dev/null|/usr/local/bin/dwd-mosmix --weewx --daily --hourly --json --database O461 2>/dev/null >/dev/null|g" /etc/cron.hourly/dwd

# Icons
RUN wget -nv -O "icons-dwd.zip" "https://www.dwd.de/DE/wetter/warnungen_aktuell/objekt_einbindung/icons/wettericons_zip.zip?__blob=publicationFile&v=3" &&\
    wget -nv -O "warnicons-dwd.zip" "https://www.dwd.de/DE/wetter/warnungen_aktuell/objekt_einbindung/icons/warnicons_nach_stufen_50x50_zip.zip?__blob=publicationFile&v=2" &&\
    wget -nv -O "icons-carbon.zip" "https://public-images-social.s3.eu-west-1.amazonaws.com/weewx-wdc-carbon-icons.zip" &&\
    mkdir -p ${WEEWX_HOME}/public_html/dwd/icons && mkdir -p ${WEEWX_HOME}/public_html/dwd/warn_icons &&\
    unzip /tmp/icons-dwd.zip -d ${WEEWX_HOME}/public_html/dwd/icons &&\
    unzip /tmp/icons-carbon.zip -d ${WEEWX_HOME}/public_html/dwd/icons &&\
    unzip /tmp/warnicons-dwd.zip -d ${WEEWX_HOME}/public_html/dwd/warn_icons

WORKDIR ${WEEWX_HOME}

RUN chown -R weewx:weewx ${WEEWX_HOME}

USER weewx

RUN python3 -m venv ${WEEWX_HOME}/weewx-venv &&\
    . ${WEEWX_HOME}/weewx-venv/bin/activate &&\
    python3 -m pip install --no-cache-dir paho-mqtt==1.6.1 weewx==${WEEWX_VERSION}

RUN . ${WEEWX_HOME}/weewx-venv/bin/activate &&\
    weectl station create "${WEEWX_HOME}" --no-prompt \
        --driver=weewx.drivers.simulator \
        --altitude="250,meter" \
        --latitude=51.209 \
        --longitude=14.085 \
        --location="Haselbachtal, Saxony, Germany" \
        --register="y" \
        --station-url="https://www.weewx-hbt.de/" \
        --units="metric"

RUN . ${WEEWX_HOME}/weewx-venv/bin/activate &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-interceptor.zip &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-forecast.zip &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-cmon.zip &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-xaggs.zip &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-xcumulative.tar.gz &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-GTS.zip &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-wdc/ &&\
    weectl extension install -y --config "${WEEWX_HOME}/weewx.conf" /tmp/weewx-mqtt.zip

RUN . ${WEEWX_HOME}/weewx-venv/bin/activate &&\
    weectl extension list --config "${WEEWX_HOME}/weewx.conf" &&\
    weectl station reconfigure --weewx-root "${WEEWX_HOME}" --config "${WEEWX_HOME}/weewx.conf" --driver=user.interceptor --no-prompt

COPY src/skin.conf ./skins/weewx-wdc/
COPY src/dwd.py ./weewx-venv/lib/python3.10/site-packages/schemas/

# weewx-wdc.
RUN sed -i -e 's/device_type = acurite-bridge/device_type = ecowitt-client\n    port = 9877\n    address = 0.0.0.0/g' weewx.conf &&\
    sed -i -z -e 's/skin = Seasons\n        enable = true/skin = Seasons\n        enable = false/g' weewx.conf &&\
    sed -i -z -e 's/skin = forecast/skin = forecast\n        enable = false/g' weewx.conf &&\
    sed -i '/schema = schemas.wview_extended.schema/a \[\[dwd_binding\]\]\n        database = dwd_sqlite\n        table_name = forecast\n        manager = weewx.manager.Manager\n        schema = schemas.dwd.schema\n' "${WEEWX_HOME}"/weewx.conf >/dev/null &&\
    sed -i '/A SQLite database is simply a single file/a \[\[dwd_sqlite\]\]\n        database_name = dwd-forecast-O461.sdb\n        database_type = SQLite\n' "${WEEWX_HOME}"/weewx.conf >/dev/null &&\
    cat /tmp/weewx-dwd.conf >> weewx.conf &&\
    cat /tmp/extensions.py >> "${WEEWX_HOME}"/bin/user/extensions.py

# weewx-mqtt.
RUN sed -i -z -e 's|INSERT_SERVER_URL_HERE|mqtt://user:password@host:port\n        topic = weather\n        unit_system = METRIC\n        binding = loop\n        [[[inputs]]]\n            [[[[windSpeed]]]]\n                format = %.0f\n            [[[[windGust]]]]\n                format = %.0f|g' weewx.conf

USER root
RUN chown -R weewx:weewx ${WEEWX_HOME}

USER weewx

VOLUME [ "${WEEWX_HOME}/public_html" ]
VOLUME [ "${WEEWX_HOME}/archive" ]

ENTRYPOINT [ "/start.sh" ]
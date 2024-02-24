FROM python:3.10-buster

LABEL org.opencontainers.image.authors="David Baetge <david.baetge@gmail.com>"

ARG WEEWX_VERSION="5.0.2"
ARG WDC_VERSION="v3.5.0"
ARG WEEWX_UID=2749
ENV WEEWX_HOME="/home/weewx-data"

EXPOSE 9877

COPY src/start.sh /start.sh
COPY src/extensions.py /tmp
RUN chmod +x /start.sh

# @see https://blog.nuvotex.de/running-syslog-in-a-container/
# @todo https://www.weewx.com/docs/5.0/usersguide/monitoring/#logging-on-macos
RUN apt-get update &&\
    apt-get install -q -y --no-install-recommends rsyslog=8.1901.0-1+deb10u2 python3-pip=18.1-5 python3-venv=3.7.3-1 python3-paho-mqtt=1.4.0-1 &&\
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system --gid ${WEEWX_UID} weewx &&\
    adduser --system --uid ${WEEWX_UID} --ingroup weewx weewx

# Configure timezone.
RUN ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

WORKDIR /tmp

RUN wget -nv -O "weewx-interceptor.zip" "https://github.com/matthewwall/weewx-interceptor/archive/master.zip" &&\
    wget -nv -O "weewx-wdc-${WDC_VERSION}.zip" "https://github.com/Daveiano/weewx-wdc/releases/download/${WDC_VERSION}/weewx-wdc-${WDC_VERSION}.zip" &&\
    wget -nv -O "weewx-forecast.zip" "https://github.com/chaunceygardiner/weewx-forecast/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-mqtt.zip" "https://github.com/matthewwall/weewx-mqtt/archive/master.zip" &&\
    wget -nv -O "weewx-cmon.zip" "https://github.com/bellrichm/weewx-cmon/archive/refs/heads/master.zip" &&\
    wget -nv -O "weewx-xaggs.zip" "https://github.com/tkeffer/weewx-xaggs/archive/master.zip" &&\
    wget -nv -O "weewx-xcumulative.tar.gz" "https://github.com/gjr80/weewx-xcumulative/releases/download/v0.1.0/xcum-0.1.0.tar.gz" &&\
    wget -nv -O "weewx-GTS.zip" "https://github.com/roe-dl/weewx-GTS/archive/master.zip"

RUN mkdir /tmp/weewx-wdc/ &&\
    unzip /tmp/weewx-wdc-${WDC_VERSION}.zip -d /tmp/weewx-wdc/

WORKDIR ${WEEWX_HOME}

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

# weewx-wdc.
RUN sed -i -e 's/device_type = acurite-bridge/device_type = ecowitt-client\n    port = 9877\n    address = 0.0.0.0/g' weewx.conf &&\
    sed -i -z -e 's/skin = Seasons\n        enable = true/skin = Seasons\n        enable = false/g' weewx.conf &&\
    sed -i -z -e 's/skin = forecast/skin = forecast\n        enable = false/g' weewx.conf &&\
    cat /tmp/extensions.py >> "${WEEWX_HOME}"/bin/user/extensions.py

# weewx-mqtt.
RUN sed -i -z -e 's|INSERT_SERVER_URL_HERE|mqtt://user:password@host:port\n        topic = weather\n        unit_system = METRIC\n        binding = loop\n        [[[inputs]]]\n            [[[[windSpeed]]]]\n                format = %.0f\n            [[[[windGust]]]]\n                format = %.0f|g' weewx.conf

VOLUME [ "${WEEWX_HOME}/public_html" ]
VOLUME [ "${WEEWX_HOME}/archive" ]

ENTRYPOINT [ "/start.sh" ]
FROM python:3.10-buster

ARG WEEWX_VERSION="4.7.0"
ARG WEEWX_UID=2749
ENV WEEWX_HOME="/home/weewx"

EXPOSE 9877

COPY install-input.txt /tmp/
COPY start.sh /start.sh
RUN chmod +x /start.sh

# @see https://blog.nuvotex.de/running-syslog-in-a-container/
RUN apt-get update
RUN apt-get install -q -y rsyslog

RUN addgroup --system --gid ${WEEWX_UID} weewx \
  && adduser --system --uid ${WEEWX_UID} --ingroup weewx weewx

WORKDIR /tmp

RUN wget -O "weewx-${WEEWX_VERSION}.tar.gz" "https://www.weewx.com/downloads/released_versions/weewx-${WEEWX_VERSION}.tar.gz"
RUN wget -O "weewx-interceptor.zip" "https://github.com/matthewwall/weewx-interceptor/archive/master.zip"
RUN tar xvfz "weewx-${WEEWX_VERSION}.tar.gz"

WORKDIR /tmp/weewx-${WEEWX_VERSION}

# @todo Get requirements from repo.
RUN pip install --no-cache-dir configobj pyserial Cheetah3 Pillow
RUN python ./setup.py build && python ./setup.py install < /tmp/install-input.txt

WORKDIR ${WEEWX_HOME}

RUN bin/wee_extension --install /tmp/weewx-interceptor.zip
RUN bin/wee_config --reconfigure --driver=user.interceptor --no-prompt

RUN sed -i -e 's/device_type = acurite-bridge/device_type = ecowitt-client\n    port = 9877\n    address = 0.0.0.0/g' weewx.conf

CMD "/start.sh"
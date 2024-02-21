[![Test & Lint](https://github.com/Daveiano/weewx-wdc-interceptor-docker/actions/workflows/test.yml/badge.svg)](https://github.com/Daveiano/weewx-wdc-interceptor-docker/actions/workflows/test.yml)

# weewx-wdc-interceptor-docker

A simple Dockerfile to run [weewx](https://github.com/weewx/weewx) with the [interceptor](https://github.com/matthewwall/weewx-interceptor) driver.
The [weewx-forecast](https://github.com/chaunceygardiner/weewx-forecast/) extension is also installed along with
[weewx-wdc](https://github.com/Daveiano/weewx-wdc), [weewx-xcumulative](https://github.com/gjr80/weewx-xcumulative), [weewx-xaggs](https://github.com/tkeffer/weewx-xaggs),
[weewx-GTS](https://github.com/roe-dl/weewx-GTS), and [weewx-cmon](https://github.com/bellrichm/weewx-cmon).

There are branches available with [weewx-DWD](https://github.com/roe-dl/weewx-DWD), [weewx-mqtt](https://github.com/matthewwall/weewx-mqtt) and both extensions together.

WeeWX is installed via the [`pip` installation method](https://www.weewx.com/docs/5.0/quickstarts/pip/).

## Usage

* Make changes to the [`Dockerfile`s install command](https://github.com/Daveiano/weewx-wdc-interceptor-docker/blob/main/Dockerfile#L48) and `src/skin.conf`
* Build `docker build . -t "weewx"`
  * Default build args:
    * **ARG** WEEWX_VERSION="5.0.2"
    * **ARG** WDC_VERSION="v3.5.0-alpha2"
* Run `docker run -d --restart unless-stopped -p 9877:9877 --name weewx weewx`
* Step into with `docker exec -it weewx /bin/bash`

Logs are in /var/log/syslog.

### Working with named volumes

```
docker volume create weewx-db
docker volume create weewx-html
docker run -d --restart unless-stopped -p 9877:9877 --name weewx -v weewx-db:/home/weewx-data/archive -v weewx-html:/home/weewx-data/public_html weewx
```

Run nginx with weewx generated files: `docker run -it --rm -d -p 8080:80 --name web -v weewx-html:/usr/share/nginx/html nginx`

### docker compose

A simple docker-compose.yml is included which starts a nginx server on `localhost:8080`.

`docker compose up -d`


### [Weather Data Center Skin](https://github.com/Daveiano/weewx-wdc) or any other skin

Comment the lines 32 and 48 in the Dockerfile to deactivate the weewx-wdc skin. Or replace the download and file name
with your own skin you want to install.

## Admin scripts

### backup.sh

Saves a backup of a named volume to the desired location. This can be run via cron to backup the SQLite DB.
The backup file has a date suffix. Optionally, you can add a S3 Bucket and path as a third parameter to copy the backup to S3.
The local backup gets removed in this case.

Usage: `./admin_scripts/backup.sh <VOLUME> <OUTPUT_DIRECTORY> <OPTIONAL S3 BUCKET AND PATH>`

Example: `"./admin_scripts/backup.sh weewx-db ./exports weewx-backup-bucket s3-bucket-name/path"`

### sync-s3.sh

Sync the generated HTML reports to a S3 bucket for web hosting. This needs the [aws cli](LINK) installed and configured.
The volume path for a named volume should normally be something like `/var/lib/docker/volumes/weewx-html/_data`.
Optionally you can add a third parameter with the Cloudfront Distribution ID to trigger an Invalidation for index.html.

For more information about AWS S3 static website hosting, see here https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-create-buckets

Usage: `./admin_scripts/sync-s3.sh <LOCAL FILE PATH> <S3 BUCKET AND PATH> <OPTIONAL CF DISTRIBUTION ID>`

Example: `"./admin_scripts/sync-s3.sh /var/lib/docker/volumes/weewx-html/_data weewx_web/"`

I am using these two scripts as cronjobs on my PI installation:

```
# m h  dom mon dow   command
*/10 * * * * PATH=/usr/bin:/usr/local/bin && /home/pi/weewx-interceptor-docker/admin_scripts/sync-s3.sh /var/lib/docker/volumes/weewx-html/_data www.weewx-hbt.de/ XXXXXXXXXXXXXX
0 8 * * * PATH=/usr/bin:/usr/local/bin && /home/pi/weewx-interceptor-docker/admin_scripts/backup.sh weewx-db /tmp weewx-backup-sdb
```

## Test

The Dockerfile is tested using [dgoss](https://github.com/aelsabbahy/goss/tree/master/extras/dgoss):

`dgoss run -p 9877:9877  weewx`

## Credits and further reading

https://www.dl1nux.de/erfahrungen-mit-dnt-wetterstation-weatherscreen-pro-und-weewx/

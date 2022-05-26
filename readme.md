# weewx-interceptor-docker

A simple Dockerfile to run [weewx](https://github.com/weewx/weewx) with the [interceptor](https://github.com/matthewwall/weewx-interceptor) driver.
The [weewx-forecast](https://github.com/chaunceygardiner/weewx-forecast/) extension is also installed.

## Usage

* Make changes to src/install-input.txt
* Build `docker build . -t "weewx"`
* Run `docker run -d -p 9877:9877 --name weewx weewx`
* Step into with `docker exec -it weewx /bin/bash`

Logs are in /var/log/syslog.

### Working with named volumes

```
docker volume create weewx-db
docker volume create weewx-html
docker run -d -p 9877:9877 --name weewx -v weewx-db:/home/weewx/archive -v weewx-html:/home/weewx/public_html weewx
```

Run nginx with weewx generated files: `docker run -it --rm -d -p 8080:80 --name web -v weewx-html:/usr/share/nginx/html nginx`

`docker run -d --cpu-shares 4000 --cpus 2 -p 9877:9877 --name weewx -v weewx-db:/home/weewx/archive -v weewx-html:/home/weewx/public_html weewx`

### docker compose

A simple docker-compose.yml is included which starts a nginx server on `localhost:8080`.

`docker compose up -d`


### install-input.txt

The template for the weewx install manager:

| Value in txt                  | weewx Spec          |
|-------------------------------|---------------------|
| Haselbachtal, Saxony, Germany | Station description |
| 250, meter                    | Altitude            |
| 51.209                        | latitude            |
| 14.085                        | longitude           |
| y                             | Register station    |
| https://www.weewx-hbt.de/     | Station Link        |
| metric                        | unit display        |
| 3 (is set to interceptor during installation) | Driver              |

#### Here is the install output with the full dialogue:

```
Enter a brief description of the station, such as its location.  For example:
Santa's Workshop, North Pole
description [My Little Town, Oregon]:
Specify altitude, with units 'foot' or 'meter'.  For example:
35, foot
12, meter
altitude [700, foot]:
Specify latitude in decimal degrees, negative for south.
latitude [0.00]: Specify longitude in decimal degrees, negative for west.
longitude [0.00]:
You can register your station on weewx.com, where it will be included
in a map. You will need a unique URL to identify your station (such as a
website, or WeatherUnderground link).
Include station in the station registry (y/n)? [n]: Unique URL: [http://acme.com]:
Indicate the preferred units for display: ['us', 'metric', 'metricwx']
unit system [us]:
Installed drivers include:
  0) AcuRite         (weewx.drivers.acurite)
  1) CC3000          (weewx.drivers.cc3000)
  2) FineOffsetUSB   (weewx.drivers.fousb)
  3) Simulator       (weewx.drivers.simulator)
  4) TE923           (weewx.drivers.te923)
  5) Ultimeter       (weewx.drivers.ultimeter)
  6) Vantage         (weewx.drivers.vantage)
  7) WMR100          (weewx.drivers.wmr100)
  8) WMR300          (weewx.drivers.wmr300)
  9) WMR9x8          (weewx.drivers.wmr9x8)
 10) WS1             (weewx.drivers.ws1)
 11) WS23xx          (weewx.drivers.ws23xx)
 12) WS28xx          (weewx.drivers.ws28xx)
choose a driver [3]:
```

### [Weather Data Center Skin](https://github.com/Daveiano/weewx-wdc) or any other skin

Comment the lines 31 and 49 in the Dockerfile to deactivate the weewx-wdc skin. Or replace the download and file name
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
Optionally you can add a third parameter with the Cloudfront Distribution ID to trigger an Invalidation.

For more information about AWS S3 static website hosting, see here https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-create-buckets

Usage: `./admin_scripts/sync-s3.sh <LOCAL FILE PATH> <S3 BUCKET AND PATH> <OPTIONAL CF DISTRIBUTION ID>`

Example: `"./admin_scripts/sync-s3.sh /var/lib/docker/volumes/weewx-html/_data weewx_web/"`

###

I am using these two scripts as cronjobs on my PI installation:

```
# m h  dom mon dow   command
*/10 * * * * PATH=/usr/bin:/usr/local/bin && /home/pi/weewx-interceptor-docker/admin_scripts/sync-s3.sh /var/lib/docker/volumes/weewx-html/_data www.weewx-hbt.de/ E3J11K1FGUODP7
0 8 * * * PATH=/usr/bin:/usr/local/bin && /home/pi/weewx-interceptor-docker/admin_scripts/backup.sh weewx-db /tmp weewx-backup-sdb
```

## Test

The Dockerfile is tested using [dgoss](https://github.com/aelsabbahy/goss/tree/master/extras/dgoss):

`dgoss run -p 9877:9877  weewx`

## Credits and further reading

https://www.dl1nux.de/erfahrungen-mit-dnt-wetterstation-weatherscreen-pro-und-weewx/

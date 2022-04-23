# weewx-interceptor-docker

A simple Dockerfile to run [weewx](https://github.com/weewx/weewx) with the [interceptor](https://github.com/matthewwall/weewx-interceptor) driver.

## Usage

Docs are in /var/log/syslog.

* Make changes to src/install-input.txt
* Build `docker build . -t "weewx"`
* Run `docker run -d -p 9877:9877 --name weewx weewx`
* Step into with `docker exec -it weewx /bin/bash`

### Working with named volumes

```
docker volume create weewx-db
docker volume create weewx-html
docker run -d -p 9877:9877 --name weewx -v weewx-db:/home/weewx/archive -v weewx-html:/home/weewx/public_html weewx
```

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
| https://weewx.ddev.site/      | Station Link        |
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

## Admin scripts

### backup.sh

Saves a backup of a named volume to the desired location. This can be run via cron to backup the SQLite DB.
The backup file has a date suffix. Optionaly you can add a third paramter with the Cloudfront Distribution ID to trigger an Invalidation.

Usage: `./admin_scripts/backup.sh <VOLUME> <OUTPUT_DIRECTORY> <OPTIONAL CF DISTRIBUTION ID>`

Example: `"./admin_scripts/backup.sh weewx-db ./exports"`

### sync-s3.sh

Sync the generated html reports to a S3 bucket for web hosting. This needs the [aws cli](LINK) installed and configured.

The volume path for a named volume should normaly be something like `/var/lib/docker/volumes/weewx-html/_data`.

For more information about AWS S3 static website hosting, see here https://docs.aws.amazon.com/AmazonS3/latest/userguide/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-create-buckets

Usage: `./admin_scripts/sync-s3.sh <LOCAL FILE PATH> <S3 BUCKET AND PATH>`

Example: `"./admin_scripts/sync-s3.sh /var/lib/docker/volumes/weewx-html/_data weewx_web/"`

## Credits and further reading

https://www.dl1nux.de/erfahrungen-mit-dnt-wetterstation-weatherscreen-pro-und-weewx/

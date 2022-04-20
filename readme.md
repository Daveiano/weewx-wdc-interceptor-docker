# weewx-interceptor-docker

## Usage

```
docker build . -t "weewx"
docker run -d -p 9877:9877 --name weewx weewx 
docker exec -it weewx /bin/bash
```

## install-input.txt

| Value in txt                  | weewx Spec          |
|-------------------------------|---------------------|
| Haselbachtal, Saxony, Germany | Station description |
| 250, meter                    | Altitude            |
| 51.209                        |                     |
| 14.085                        |                     |
| y                             |                     |
| https://weewx.ddev.site/      |                     |
| metric                        |                     |
| 3                             |                     |
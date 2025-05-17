# Feature Info API for OpenStreetMap

Attempt to create an API to get information about OSM features around a location. The current goal is to create a function that mimics the same output as the existing feature info function on the official [OSM website](https://www.openstreetmap.org). Find the source code of the existing function [here](https://github.com/openstreetmap/openstreetmap-website/blob/6d0c2913326fbfdf3578416853e31d7a950d97ed/app/assets/javascripts/index/query.js#L252-L307).

## Setup

Tested on Debian/Ubuntu systems. Ensure you have Docker installed. See [official instructions](https://docs.docker.com/engine/install/debian/).

**Note:** Depending on you installation the docker commands are differently:

- it might be necessary that you have to add `sudo` before your docker commmands
- Docker Compose can either be called by using `docker-compose` or `docker compose` (either with `-`(hyphen) or whitespace). It depends on your installation.

```shell
# download sample data (or use your own)

# region according to Geofabrik download name, examples:
#    - europe/andorra
#    - europe/germany/baden-wuerttemberg/karlsruhe-regbez
#    - europe/germany/baden-wuerttemberg
export REGION=europe/andorra
export DATE=$(date --date="3 days ago" +"%y%m%d")

wget -O data/sample.pbf https://download.geofabrik.de/${REGION}-${DATE}.osm.pbf

# [optional] shut down existing compose stack
docker compose down --volumes --remove-orphans

# start services
docker compose up -d --build

# load data into db
docker compose run --rm osm2pgsql \
  --slim \
  --output=flex \
  --style=/data/flex_style.lua \
  --prefix=raw \
  /data/sample.pbf

# replication init
docker compose run --rm osm2pgsql replication init \
 --verbose \
 --prefix=raw \
 --osm-file=/data/sample.pbf

# perform initial subdivide
docker compose exec postgres psql -f /data/initial_subdivide.sql

# set trigger
docker compose exec postgres psql -f /data/trigger.sql

# add function to DB
docker compose exec postgres psql -f /data/query_function.sql

# replication update
docker compose run --rm osm2pgsql replication update \
  --prefix=raw \
  --verbose
```

Demo client can be accessed via <http://localhost:4173/>.

## Request API

Request the API with your browser or any other tool <http://localhost:9000/functions/postgisftw.osm_website_combi/items.json?latitude=42.533888&longitude=1.5929665&radius=35&min_lon=1.590091&min_lat=42.526629&max_lon=1.607210&max_lat=42.53863>

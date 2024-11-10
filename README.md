# Feature Info API for OpenStreetMap

Attempt to create an API to get information about OSM features around a location. The current goal is to create a function that mimics the same output as the existing feature info function on the official [OSM website](https://www.openstreetmap.org). Find the source code of the existing function [here](https://github.com/openstreetmap/openstreetmap-website/blob/6d0c2913326fbfdf3578416853e31d7a950d97ed/app/assets/javascripts/index/query.js#L252-L307).

## Setup

Tested on Linux and WSL:

```sh
# download sample data (or use your own)
wget -O data/sample.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf

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

# add function to DB
docker compose exec postgres psql -f /data/query_function.sql
```

Demo client can be accessed via <http://localhost:4173/>.

Replication can be executed like this:

```shell
# replication init
docker compose run --rm osm2pgsql replication init \
 --verbose \
 --prefix=raw \
 --osm-file=/data/sample.pbf

# replication update
docker compose run --rm osm2pgsql replication update \
  --prefix=raw \
  --verbose
```

## Request API

Request the API with your browser or any other tool <http://localhost:9000/functions/postgisftw.osm_website_combi/items.json?latitude=42.533888&longitude=1.5929665&radius=35&min_lon=1.590091&min_lat=42.526629&max_lon=1.607210&max_lat=42.53863>

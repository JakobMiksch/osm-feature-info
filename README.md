# Feature Info API for OpenStreetMap

Attempt to create an API to get information about OSM features around a location.

## Setup

Tested on Linux and WSL:

```sh
# when cloning the first time
# SSH version
git clone --recursive git@github.com:JakobMiksch/osm_feature_info.git
# HTTPS version
git clone --recursive https://github.com/JakobMiksch/osm_feature_info.git

# if case you forgot to use the "--recursive" flag
git submodule update --init

# download sample data
wget -O data/sample.pbf https://download.geofabrik.de/europe/germany/bremen-latest.osm.pbf

# [optional] shut down existing compose stack if existing
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

# post-process import
docker compose exec postgres psql -f data/post_process_tables.sql

# add function to DB
docker compose exec postgres psql -f /data/query_function.sql
```


## Request API

Request the API with your browser or any other tool:

- **HTML**: <http://localhost:9000/functions/postgisftw.osm_feature_info/items.html?latitude=53.112&longitude=8.755&distance=50&limit=10000>
- **JSON**: <http://localhost:9000/functions/postgisftw.osm_feature_info/items.json?latitude=53.112&longitude=8.755&distance=50&limit=10000>

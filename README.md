# Feature Info API for OpenStreetMap

Attempt to create an API to get information about OSM features around a location.

## Setup

### Using Docker

Tested on Linux and WSL. Adapt for other operating systems.

```sh
cp .env_template .env
# Optionally change environment variables inside .env

# start services
docker compose up -d

# download sample data
wget -O data/sample.pbf https://download.geofabrik.de/europe/germany/bremen-latest.osm.pbf

# load data into db
docker compose run --rm osm2pgsql \
  --slim \
  --output=flex \
  --style=/data/flex_style.lua \
  --prefix=raw \
  /data/sample.pbf

# post-process import
docker compose exec db psql -f data/post_process_tables.sql

# add function to DB
docker compose exec db psql -f /data/query_function.sql
```

### Without Docker

1. create PostGIS database
2. load OSM data:

    ```sh
    # load data into db
    osm2pgsql \
    --slim \
    --output=flex \
    --style=data/flex_style.lua \
    --prefix=raw \
    data/sample.pbf
    ```

3. Load these scripts to the database:
    - `data/query_function.sql`
    - `data/post_process_tables.sql`
4. Install `pg_featureserv` (Download link for Linux: <https://postgisftw.s3.amazonaws.com/pg_featureserv_latest_linux.zip>) and run it via:

    ```sh
    export DATABASE_URL=postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}/${PGDATABASE}
    export PGFS_WEBSITE_BASEMAPURL="https://tile.openstreetmap.de/{z}/{x}/{y}.png"
    ./pg_featureserv
    ```

## Request API

Request the API with your browser or any other tool:

- HTML: <http://localhost:9000/functions/postgisftw.osm_feature_info/items.html?latitude=53.112&longitude=8.755&distance=50&limit=10000>
- JSON: <http://localhost:9000/functions/postgisftw.osm_feature_info/items.json?latitude=53.112&longitude=8.755&distance=50&limit=10000>


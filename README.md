# Feature Info API for OpenStreetMap

Attempt to create an API to get information about OSM features around a location. The current goal is to create a function that mimics the same output as the existing feature info function on the official [OSM website](https://www.openstreetmap.org). Find the source code of the existing function [here](https://github.com/openstreetmap/openstreetmap-website/blob/6d0c2913326fbfdf3578416853e31d7a950d97ed/app/assets/javascripts/index/query.js#L252-L307).

## Setup

Tested on Debian/Ubuntu systems.

### From scratch

1. Ensure you have a Postgres/PostGIS database available and run `postgres/docker-entrypoint-initdb.d/01_create_postgis.sql`.
2. Install [osm2pgsql](https://osm2pgsql.org/) with minimal version `2.0.0`
3. Setup Themepark

    - clone the [Themepark repo](https://github.com/osm2pgsql-dev/osm2pgsql-themepark) into a location of your choice
    - in your shell link the Themepark via this environment variable:

    ```shell
    export LUA_PATH="YOUR_PATH_TO/osm2pgsql-themepark/lua/?.lua;;"
    ```

4. Import an OSM extract into the database:

    ```shell
    # set database connection
    export PGHOST=???
    export PGPORT=???
    export PGDATABASE=???
    export PGUSER=???

    # set password by environment variable or run "osm2pgsql" using "-W" to prompt for the password
    export PGPASSWORD=???

    osm2pgsql \
    --slim \
    --output=flex \
    --style=./data/flex_style.lua \
    --prefix=raw \
    ./PATH_TO_YOUR/OSM_EXTRACT.pbf
    ```

5. Apply the SQL-function that queries the OSM features around a location:

    ```shell
    # use the same environment variables as above
    # you can also prompt for password using `-W`
    psql -f ./data/query_function.sql
    ```

6. Install [pg_featureserv](https://github.com/CrunchyData/pg_featureserv) and run:

    ```shell
    # use the environment variables from above
    export DATABASE_URL=postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}/${PGDATABASE}
    export PGFS_WEBSITE_BASEMAPURL=https://tile.openstreetmap.de/{z}/{x}/{y}.png
    export PGFS_PAGING_LIMITDEFAULT=100
    pg_featureserv
    ```

7. make a query and get a GeoJSON as response to ensure it works as expected:

    ```shell
    export latitude=42.533888
    export longitude=1.5929665
    export radius=35
    export min_lon=1.590091
    export min_lat=42.526629
    export max_lon=1.607210
    export max_lat=42.53863

    curl "http://localhost:9000/functions/postgisftw.osm_website_combi/items.json?latitude=${latitude}&longitude=${longitude}&radius=${radius}&min_lon=${min_lon}&min_lat=${min_lat}&max_lon=${max_lon}&max_lat=${max_lat}"
    ```

8. [optional] Use the demo web client for testing and debugging. See respective [README](web-client/README.md). You might need to fix some CORS issues.

### Using Docker

Ensure you have Docker installed. See [official instructions](https://docs.docker.com/engine/install/debian/).

**Note:** Depending on you installation the docker commands are differently:

- it might be necessary that you have to add `sudo` before your docker commmands
- Docker Compose can either be called by using `docker-compose` or `docker compose` (either with `-`(hyphen) or whitespace). It depends on your installation.

```shell
# download sample data (or use your own)
wget -O data/sample.pbf https://download.geofabrik.de/europe/andorra-latest.osm.pbf

# [optional] shut down existing compose stack
docker compose down --volumes --remove-orphans

# start services
docker compose up -d

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

# rerun this function
docker compose exec postgres psql -f /data/query_function.sql
```

## Request API

Request the API with your browser or any other tool <http://localhost:9000/functions/postgisftw.osm_website_combi/items.json?latitude=42.533888&longitude=1.5929665&radius=35&min_lon=1.590091&min_lat=42.526629&max_lon=1.607210&max_lat=42.53863>

CREATE EXTENSION postgis;

CREATE SCHEMA IF NOT EXISTS postgisftw;

-- we need to split big polygons to ensure high performance in point in polygon queries
CREATE TABLE
    polygons_subdivided (
        osm_id int NOT NULL,
        osm_type char NOT NULL,
        geom Geometry(POLYGON, 4326) NOT NULL
    );

CREATE INDEX idx_polygons_subdivided_geom ON polygons_subdivided USING gist (geom);

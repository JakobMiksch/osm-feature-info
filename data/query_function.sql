CREATE SCHEMA IF NOT EXISTS postgisftw;

CREATE VIEW
  view_objects AS
SELECT
  g.osm_type,
  g.osm_id,
  r.tags,
  g.geog AS geog
FROM
  geometries AS g
  LEFT JOIN raw_nodes AS n ON g.osm_id = n.id
  AND g.osm_type = 'N'
  LEFT JOIN raw_ways AS w ON g.osm_id = w.id
  AND g.osm_type = 'W'
  LEFT JOIN raw_rels AS r ON g.osm_id = r.id
  AND g.osm_type = 'R';

DROP FUNCTION IF EXISTS postgisftw.osm_website_objects_around;

CREATE
OR REPLACE FUNCTION postgisftw.osm_website_objects_around (
  latitude float,
  longitude float,
  radius int,
  min_lat float,
  min_lon float,
  max_lat float,
  max_lon float
) RETURNS TABLE (
  osm_type char,
  osm_id bigint,
  tags jsonb,
  geom geometry
) AS $$
    SELECT osm_type, osm_id, tags, geog::geometry FROM view_objects
  WHERE ST_DWithin(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, radius)
  AND NOT ST_Intersects(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography)
  AND ST_Covers(ST_MakeEnvelope(min_lon, min_lat, max_lon, max_lat, 4326)::geography, geog)
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.osm_website_objects_enclosing;

CREATE
OR REPLACE FUNCTION postgisftw.osm_website_objects_enclosing (
  latitude float,
  longitude float,
  min_lat float,
  min_lon float,
  max_lat float,
  max_lon float
) RETURNS TABLE (
  osm_type char,
  osm_id bigint,
  tags jsonb,
  geom geometry
) AS $$
    SELECT
    osm_type,
    osm_id,
    tags,
    CASE
        WHEN NOT ST_Covers (
          ST_MakeEnvelope (min_lon, min_lat, max_lon, max_lat, 4326)::geography,
          geog
        ) THEN NULL::geometry
        ELSE geog::geometry
    END AS geog
    FROM view_objects
  WHERE ST_Covers(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography)
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.osm_website_combi;

CREATE
OR REPLACE FUNCTION postgisftw.osm_website_combi (
  latitude float,
  longitude float,
  radius int,
  min_lat float,
  min_lon float,
  max_lat float,
  max_lon float
) RETURNS TABLE (
  osm_type char,
  osm_id bigint,
  query_type text,
  tags jsonb,
  geom geometry
) AS $$
  SELECT osm_type, osm_id, 'around' as query_type, tags, geom FROM postgisftw.osm_website_objects_around( latitude, longitude, radius, min_lat, min_lon, max_lat, max_lon )

  UNION

  SELECT osm_type, osm_id, 'enclosing' as query_type, tags, geom FROM postgisftw.osm_website_objects_enclosing( latitude, longitude, min_lat, min_lon, max_lat, max_lon )
$$ LANGUAGE sql STABLE PARALLEL SAFE;

CREATE SCHEMA IF NOT EXISTS postgisftw;

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
    SELECT osm_type, osm_id, tags, geog::geometry FROM (
      SELECT gn.osm_type, gn.osm_id, r.tags, gn.geog AS geog
      FROM geom_nodes AS gn
      JOIN raw_nodes AS r ON gn.osm_id = r.id

      UNION

      SELECT gw.osm_type, gw.osm_id, r.tags, gw.geog  AS geog
      FROM geom_ways AS gw
      JOIN raw_ways AS r ON gw.osm_id = r.id

      UNION

      SELECT gr.osm_type, gr.osm_id, r.tags, gr.geog AS geog
      FROM geom_rels AS gr
      JOIN raw_rels AS r ON gr.osm_id = r.id
  ) AS osm_objects
  WHERE ST_DWithin(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, radius)
  AND not ST_Intersects(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography)
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
    -- geog::geometry
    CASE
        WHEN NOT ST_Covers (
          ST_MakeEnvelope (min_lon, min_lat, max_lon, max_lat, 4326)::geography,
          geog
        ) THEN NULL::geometry
        ELSE geog::geometry
    END AS geog
    FROM (
      SELECT gw.osm_type, gw.osm_id, r.tags, gw.geog  AS geog
      FROM geom_ways AS gw
      JOIN raw_ways AS r ON gw.osm_id = r.id

      UNION

      SELECT gr.osm_type, gr.osm_id, r.tags, gr.geog AS geog
      FROM geom_rels AS gr
      JOIN raw_rels AS r ON gr.osm_id = r.id
  ) AS osm_objects
  WHERE ST_Covers(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography)
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.osm_feature_info_geog;

CREATE
OR REPLACE FUNCTION postgisftw.osm_feature_info_geog (latitude float, longitude float, radius int) RETURNS TABLE (
  osm_type char,
  osm_id bigint,
  tags jsonb,
  geom geometry
) AS $$
  SELECT gn.osm_type, gn.osm_id, r.tags, gn.geog::geometry
  FROM geom_nodes AS gn
  JOIN raw_nodes AS r ON gn.osm_id = r.id
  WHERE ST_DWithin(gn.geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, radius)

  UNION

  SELECT gw.osm_type, gw.osm_id, r.tags, gw.geog::geometry
  FROM geom_ways AS gw
  JOIN raw_ways AS r ON gw.osm_id = r.id
  WHERE ST_DWithin(gw.geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, radius)

  UNION

  SELECT gr.osm_type, gr.osm_id, r.tags, gr.geog::geometry
  FROM geom_rels AS gr
  JOIN raw_rels AS r ON gr.osm_id = r.id
  WHERE ST_DWithin(gr.geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, radius)
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.osm_feature_info_webmercator_unprecise;

CREATE
OR REPLACE FUNCTION postgisftw.osm_feature_info_webmercator_unprecise (latitude float, longitude float, radius int) RETURNS TABLE (
  osm_type char,
  osm_id bigint,
  tags jsonb,
  geom geometry
) AS $$
  SELECT gn.osm_type, gn.osm_id, r.tags, gn.geom_3857 ::geometry
  FROM geom_nodes AS gn
  JOIN raw_nodes AS r ON gn.osm_id = r.id
  WHERE ST_DWithin(gn.geom_3857, ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 3857),  radius)

  UNION

  SELECT gw.osm_type, gw.osm_id, r.tags, gw.geom_3857 ::geometry
  FROM geom_ways AS gw
  JOIN raw_ways AS r ON gw.osm_id = r.id
  WHERE ST_DWithin(gw.geom_3857, ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 3857), radius)

  UNION

  SELECT gr.osm_type, gr.osm_id, r.tags, gr.geom_3857 ::geometry
  FROM geom_rels AS gr
  JOIN raw_ways AS r ON gr.osm_id = r.id
  WHERE ST_DWithin(gr.geom_3857, ST_Transform(ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), 3857), radius)
$$ LANGUAGE sql STABLE PARALLEL SAFE;

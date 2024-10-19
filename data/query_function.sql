CREATE SCHEMA IF NOT EXISTS postgisftw;


DROP FUNCTION IF EXISTS postgisftw.osm_feature_info;

CREATE OR REPLACE FUNCTION postgisftw.osm_feature_info(
    latitude float,
    longitude float,
    distance int
)
RETURNS TABLE(osm_type char, osm_id bigint, tags jsonb, geom geometry) AS
$$
  SELECT gn.osm_type, gn.osm_id, r.tags, gn.geog::geometry
  FROM geom_nodes AS gn
  JOIN raw_nodes AS r ON gn.osm_id = r.id
  WHERE ST_DWithin(gn.geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, distance)

  UNION

  SELECT gw.osm_type, gw.osm_id, r.tags, gw.geog::geometry
  FROM geom_ways AS gw
  JOIN raw_ways AS r ON gw.osm_id = r.id
  WHERE ST_DWithin(gw.geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, distance)

  UNION

  SELECT gr.osm_type, gr.osm_id, r.tags, gr.geog::geometry
  FROM geom_rels AS gr
  JOIN raw_rels AS r ON gr.osm_id = r.id
  WHERE ST_DWithin(gr.geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, distance)
$$
LANGUAGE sql STABLE PARALLEL SAFE;

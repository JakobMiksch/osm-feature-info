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

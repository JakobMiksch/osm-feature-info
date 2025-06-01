DROP VIEW IF EXISTS view_osm_objects;

CREATE OR REPLACE VIEW
  view_osm_objects AS
SELECT
  g.osm_id,
  g.osm_type,
  CASE
    WHEN g.osm_type = 'N' then n.tags
    WHEN g.osm_type = 'W' then w.tags
    WHEN g.osm_type = 'R' then r.tags
    ELSE NULL
  END as tags,
  g.count_vertices,
  g.geom_type,
  g.geog AS geog
FROM
  geometries AS g
  LEFT JOIN raw_nodes AS n ON g.osm_id = n.id
  AND g.osm_type = 'N'
  LEFT JOIN raw_ways AS w ON g.osm_id = w.id
  AND g.osm_type = 'W'
  LEFT JOIN raw_rels AS r ON g.osm_id = r.id
  AND g.osm_type = 'R';

DROP FUNCTION IF EXISTS convert_osm_type;

CREATE OR REPLACE FUNCTION long_osm_type(short_osm_type CHAR)
RETURNS TEXT AS $$
BEGIN
    RETURN
        CASE
            WHEN short_osm_type = 'N' THEN 'node'
            WHEN short_osm_type = 'W' THEN 'way'
            WHEN short_osm_type = 'R' THEN 'relation'
            ELSE NULL
        END;
END;
$$ LANGUAGE plpgsql;

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
  osm_type text,
  osm_id bigint,
  tags jsonb,
  geometry_type text,
  geom geometry
) AS $$
    SELECT
    long_osm_type(osm_type) as osm_type,
    osm_id,
    tags,
    GeometryType(geog::geometry) as geometry_type,
    -- only return geometry if it is in viewport
    CASE
        WHEN NOT ST_Covers (
          ST_MakeEnvelope (min_lon, min_lat, max_lon, max_lat, 4326)::geography,
          geog
        ) THEN NULL::geometry
        ELSE geog::geometry
    END AS geog
    FROM view_osm_objects
  WHERE ST_DWithin(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography, radius)
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.osm_website_objects_enclosing_small;

CREATE
OR REPLACE FUNCTION postgisftw.osm_website_objects_enclosing_small (
  latitude float,
  longitude float,
  min_lat float,
  min_lon float,
  max_lat float,
  max_lon float
) RETURNS TABLE (
  osm_type text,
  osm_id bigint,
  tags jsonb,
  geometry_type text,
  geom geometry
) AS $$
    SELECT
    long_osm_type(osm_type) as osm_type,
    osm_id,
    tags,
    GeometryType(geog::geometry) as geometry_type,
    -- only return geometry if it is in viewport
    CASE
        WHEN NOT ST_Covers (
          ST_MakeEnvelope (min_lon, min_lat, max_lon, max_lat, 4326)::geography,
          geog
        ) THEN NULL::geometry
        ELSE geog::geometry
    END AS geog
    FROM view_osm_objects
  WHERE ST_Intersects(geog, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography)
  AND count_vertices <= max_vertices()
$$ LANGUAGE sql STABLE PARALLEL SAFE;

DROP FUNCTION IF EXISTS postgisftw.osm_website_objects_enclosing_large;

CREATE
OR REPLACE FUNCTION postgisftw.osm_website_objects_enclosing_large (
  latitude float,
  longitude float,
  min_lat float,
  min_lon float,
  max_lat float,
  max_lon float
) RETURNS TABLE (
  osm_type text,
  osm_id bigint,
  tags jsonb,
  geometry_type text,
  geom geometry
) AS $$
  SELECT
      long_osm_type(p.osm_type) as osm_type,
      p.osm_id,
      CASE
        WHEN p.osm_type = 'N' then n.tags
        WHEN p.osm_type = 'W' then w.tags
        WHEN p.osm_type = 'R' then r.tags
        ELSE NULL
      END as tags,
      GeometryType(geog::geometry) as geometry_type,
    -- only return geometry if it is in viewport
      CASE
        WHEN NOT ST_Covers (
          ST_MakeEnvelope (min_lon, min_lat, max_lon, max_lat, 4326)::geography,
          v.geog
        ) THEN NULL::geometry
      ELSE v.geog::geometry
    END AS geog
      FROM polygons_subdivided as p
  LEFT JOIN view_osm_objects AS v ON p.osm_id = v.osm_id  AND p.osm_type = v.osm_type
  -- TODO: maybe we do not need to join nodes, because they are never a polygon. But it should not harm either ...
  LEFT JOIN raw_nodes AS n ON p.osm_id = n.id
  AND p.osm_type = 'N'
  LEFT JOIN raw_ways AS w ON p.osm_id = w.id
  AND p.osm_type = 'W'
  LEFT JOIN raw_rels AS r ON p.osm_id = r.id
  AND p.osm_type = 'R'
  WHERE ST_Intersects(geom, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326));
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
  osm_type text,
  osm_id bigint,
  query_type text,
  tags jsonb,
  geometry_type text,
  geom geometry
) AS $$
  SELECT osm_type, osm_id, 'around' as query_type,  tags, geometry_type, geom FROM postgisftw.osm_website_objects_around( latitude, longitude, radius, min_lat, min_lon, max_lat, max_lon )

  UNION

  SELECT osm_type, osm_id, 'enclosing' as query_type, tags, geometry_type, geom FROM postgisftw.osm_website_objects_enclosing_small( latitude, longitude, min_lat, min_lon, max_lat, max_lon )

  UNION

  SELECT osm_type, osm_id, 'enclosing' as query_type, tags, geometry_type, geom FROM postgisftw.osm_website_objects_enclosing_large( latitude, longitude, min_lat, min_lon, max_lat, max_lon )

$$ LANGUAGE sql STABLE PARALLEL SAFE;

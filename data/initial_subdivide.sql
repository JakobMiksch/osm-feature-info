-- set constant 'max_vertices'
INSERT INTO osm2pgsql_properties (property, value)
VALUES ('_max_vertices', '256')
ON CONFLICT (property)
DO UPDATE SET value = EXCLUDED.value;

CREATE OR REPLACE FUNCTION max_vertices()
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT value FROM osm2pgsql_properties where property='_max_vertices');
END;
$$ LANGUAGE plpgsql;

-- compute subdivided polygons
TRUNCATE polygons_subdivided; -- ensure table is empty
-- start subdivide
INSERT INTO
    polygons_subdivided (osm_id, osm_type, geom)
SELECT
    osm_id,
    osm_type,
    ST_SubDivide (geog::geometry, max_vertices()) AS geom
FROM
    geometries
WHERE
   ST_NPoints(geog::geometry) > max_vertices()
    AND ST_GeometryType(geog::geometry) IN ('ST_Polygon', 'ST_MultiPolygon');

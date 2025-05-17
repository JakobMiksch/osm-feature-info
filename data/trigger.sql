CREATE
OR REPLACE FUNCTION perform_polygon_subdivide () RETURNS TRIGGER AS $$
BEGIN

    IF ST_NPoints(NEW.geog::geometry) > max_vertices()
       AND ST_GeometryType(NEW.geog::geometry) IN ('ST_Polygon', 'ST_MultiPolygon')
    THEN
        INSERT INTO polygons_subdivided (osm_id, osm_type, geom)
        VALUES (
            NEW.osm_id,
            NEW.osm_type,
            ST_SubDivide(NEW.geog::geometry, max_vertices())
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_polygon_trigger
AFTER INSERT ON geometries FOR EACH ROW
EXECUTE FUNCTION perform_polygon_subdivide ();

CREATE
OR REPLACE FUNCTION delete_subdivided_polygon () RETURNS TRIGGER AS $$
BEGIN
    -- we do not check the vertices count like in the other statements, because it does not matter in this case
    IF ST_GeometryType(OLD.geog::geometry) IN ('ST_Polygon', 'ST_MultiPolygon')
    THEN
        DELETE FROM polygons_subdivided WHERE osm_id = OLD.osm_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_polygon_trigger
AFTER DELETE ON geometries FOR EACH ROW
EXECUTE FUNCTION delete_subdivided_polygon ();

CREATE
OR REPLACE FUNCTION update_subdivided_polygon () RETURNS TRIGGER AS $$
BEGIN
    IF ST_NPoints(NEW.geog::geometry) > max_vertices()
    THEN
        IF ST_GeometryType(NEW.geog::geometry) IN ('ST_Polygon', 'ST_MultiPolygon') THEN
            DELETE FROM polygons_subdivided WHERE osm_id = OLD.osm_id;
            INSERT INTO polygons_subdivided (osm_id, osm_type, geom)
            VALUES (
                NEW.osm_id,
                NEW.osm_type,
                ST_SubDivide(NEW.geog::geometry, max_vertices())
            );
        END IF;
    ELSE
        -- edge case that object became less vertices than 'max_vertices'
        -- therefore we remove it from subdivied table
        DELETE FROM polygons_subdivided WHERE osm_id = OLD.osm_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_polygon_trigger
AFTER
UPDATE ON geometries FOR EACH ROW
EXECUTE FUNCTION update_subdivided_polygon ();

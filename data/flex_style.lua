local function has_area_tags(tags)
    if tags.area == 'yes' then
        return true
    end
    if tags.area == 'no' then
        return false
    end

    return tags.aeroway
        or tags.amenity
        or tags.building
        or tags.harbour
        or tags.historic
        or tags.landuse
        or tags.leisure
        or tags.man_made
        or tags.military
        or tags.natural
        or tags.office
        or tags.place
        or tags.power
        or tags.public_transport
        or tags.shop
        or tags.sport
        or tags.tourism
        or tags.water
        or tags.waterway
        or tags.wetland
        or tags['abandoned:aeroway']
        or tags['abandoned:amenity']
        or tags['abandoned:building']
        or tags['abandoned:landuse']
        or tags['abandoned:power']
        or tags['area:highway']
        or tags['building:part']
end


local geom_nodes = osm2pgsql.define_table({
    name = 'geom_nodes',
    ids = { type = 'any', type_column = 'osm_type', id_column = 'osm_id' },
    columns = {
        { column = 'geom_3857', type = 'point', not_null = true },
        { column = 'geom_4326', type = 'point', projection = '4326', not_null = true }
    },
    indexes = {
        { column = 'geom_3857',  method = 'gist' },
        { column = 'geom_4326',  method = 'gist' }
    }
})

function osm2pgsql.process_node(object)
    geom_nodes:insert({
        geom_3857 = object:as_point(),
        geom_4326 = object:as_point()
    })
end

local geom_ways = osm2pgsql.define_table({
    name = 'geom_ways',
    ids = { type = 'any', type_column = 'osm_type', id_column = 'osm_id' },
    columns = {
        { column = 'geom_3857', type = 'geometry', not_null = true },
        { column = 'geom_4326', type = 'geometry', projection = '4326', not_null = true }
    },
    indexes = {
        { column = 'geom_3857',  method = 'gist' },
        { column = 'geom_4326',  method = 'gist' }
    }
})

function osm2pgsql.process_way(object)
    if object.is_closed and has_area_tags(object.tags) then
        geom_ways:insert({
            geom_3857 = object:as_polygon(),
            geom_4326 = object:as_polygon()
        })
    else
        geom_ways:insert({
            geom_3857 = object:as_linestring(),
            geom_4326 = object:as_linestring()
        })
    end
end

local geom_rels = osm2pgsql.define_table({
    name = 'geom_rels',
    ids = { type = 'any', type_column = 'osm_type', id_column = 'osm_id' },
    columns = {
        { column = 'geom_3857', type = 'geometry', not_null = true },
        { column = 'geom_4326', type = 'geometry', projection = '4326', not_null = true }
    },
    indexes = {
        { column = 'geom_3857',  method = 'gist' },
        { column = 'geom_4326',  method = 'gist' }
    }
})

function osm2pgsql.process_relation(object)
    local relation_type = object:grab_tag('type')

    if relation_type == 'route' then
        geom_rels:insert({
            geom_3857 = object:as_multilinestring(),
            geom_4326 = object:as_multilinestring()
        })
        return
    end

    if relation_type == 'boundary' or (relation_type == 'multipolygon' and object.tags.boundary) then
        geom_rels:insert({
            geom_3857 = object:as_multilinestring():line_merge(),
            geom_4326 = object:as_multilinestring():line_merge()
        })
        return
    end

    if relation_type == 'multipolygon' then
        geom_rels:insert({
            geom_3857 = object:as_multipolygon(),
            geom_4326 = object:as_multipolygon()
        })
    end
end

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
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    columns = {{
        column = 'geog',
        type = 'point',
        projection = '4326',
        not_null = true,
        sql_type = 'geography(point)'
    }}
})

function osm2pgsql.process_node(object)
    geom_nodes:insert({
        geog = object:as_point()
    })
end

local geom_ways = osm2pgsql.define_table({
    name = 'geom_ways',
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    columns = {{
        column = 'geog',
        type = 'geometry',
        projection = '4326',
        not_null = true,
        sql_type = 'geography(geometry)'
    }}
})

function osm2pgsql.process_way(object)
    if object.is_closed and has_area_tags(object.tags) then
        geom_ways:insert({
            geog = object:as_polygon()
        })
    else
        geom_ways:insert({
            geog = object:as_linestring()
        })
    end
end

local geom_rels = osm2pgsql.define_table({
    name = 'geom_rels',
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    columns = {{
        column = 'geog',
        type = 'geometry',
        projection = '4326',
        not_null = true,
        sql_type = 'geography(geometry)'
    }}
})

function osm2pgsql.process_relation(object)
    local relation_type = object:grab_tag('type')

    if relation_type == 'route' then
        geom_rels:insert({
            geog = object:as_multilinestring()
        })
        return
    end

    if relation_type == 'boundary' or (relation_type == 'multipolygon' and object.tags.boundary) then
        geom_rels:insert({
            geog = object:as_multilinestring():line_merge()
        })
        return
    end

    if relation_type == 'multipolygon' then
        geom_rels:insert({
            geog = object:as_multipolygon()
        })
    end
end

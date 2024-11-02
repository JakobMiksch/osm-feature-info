local themepark, theme, cfg = ...

themepark:set_option('srid', 4326)

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

themepark:add_table{
    name = 'geom_nodes',
    geog = 'point',
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
    }},
    indexes = {{
        column = 'geog',
        method = 'gist'
    }},
    tiles = false
}

themepark:add_proc('node', function(object, data)
    themepark:insert('geom_nodes', {
        geog = object:as_point()
    }, object.tags)
end)

themepark:add_table{
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
    }},
    indexes = {{
        column = 'geog',
        method = 'gist'
    }},
    tiles = false
}

themepark:add_proc('way', function(object, data)

    attributes = {}
    if object.is_closed and has_area_tags(object.tags) then
        attributes = {
            geog = object:as_polygon()
        }
    else
        attributes = {
            geog = object:as_linestring()
        }
    end

    themepark:insert('geom_ways', attributes, object.tags)
end)

themepark:add_table{
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
    }},
    indexes = {{
        column = 'geog',
        method = 'gist'
    }},
    tiles = false
}
themepark:add_proc('relation', function(object, data)
    local relation_type = object:grab_tag('type')
    local geog

    if relation_type == 'route' then
        geog = object:as_multilinestring()
    elseif relation_type == 'boundary' or (relation_type == 'multipolygon' and object.tags.boundary) then
        geog = object:as_multilinestring():line_merge()
    elseif relation_type == 'multipolygon' then
        geog = object:as_multipolygon()
    end

    if geog then
        themepark:insert('geom_rels', {
            geog = geog
        }, object.tags)
    end
end)

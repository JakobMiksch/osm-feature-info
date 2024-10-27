local themepark = require('themepark')

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
    geom = 'point',
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    tiles = false
}

themepark:add_proc('node', function(object, data)
    themepark:insert('geom_nodes', {
        geom = object:as_point()
    }, object.tags)
end)

themepark:add_table{
    name = 'geom_ways',
    geom = 'geometry',
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    tiles = false
}

themepark:add_proc('way', function(object, data)

    attributes = {}
    if object.is_closed and has_area_tags(object.tags) then
        attributes = {
            geom = object:as_polygon()
        }
    else
        attributes = {
            geom = object:as_linestring()
        }
    end

    themepark:insert('geom_ways', attributes, object.tags)
end)

themepark:add_table{
    name = 'geom_rels',
    geom = 'geometry',
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    tiles = false
}

themepark:add_proc('relation', function(object, data)
    local relation_type = object:grab_tag('type')

    if relation_type == 'route' then
        themepark:insert('geom_rels', {
            geom = object:as_multilinestring()
        }, object.tags)
        return
    end

    if relation_type == 'boundary' or (relation_type == 'multipolygon' and object.tags.boundary) then
        themepark:insert('geom_rels', {
            geom = object:as_multilinestring():line_merge()
        }, object.tags)
        return
    end

    if relation_type == 'multipolygon' then
        themepark:insert('geom_rels', {
            geom = object:as_multipolygon()
        }, object.tags)
    end
end)

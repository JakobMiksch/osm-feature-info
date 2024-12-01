local themepark = ...

-- reuse function from other theme
local has_area_tags = themepark:init_theme('basic').has_area_tags

themepark:add_table{
    name = 'geometries',
    ids = {
        type = 'any',
        type_column = 'osm_type',
        id_column = 'osm_id'
    },
    columns = {{
        column = 'geog',
        type = 'geometry',
        projection = 4326,
        not_null = true,
        sql_type = 'geography(geometry)'
    }},
    indexes = {{
        column = 'geog',
        method = 'gist'
    }},
    tiles = false
}

themepark:add_proc('node', function(object)
    themepark:insert('geometries', {
        geog = object:as_point()
    }, object.tags)
end)


themepark:add_proc('way', function(object)
    local attributes
    if object.is_closed and has_area_tags(object.tags) then
        attributes = {
            geog = object:as_polygon()
        }
    else
        attributes = {
            geog = object:as_linestring()
        }
    end

    themepark:insert('geometries', attributes, object.tags)
end)

themepark:add_proc('relation', function(object)
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
        themepark:insert('geometries', {
            geog = geog
        }, object.tags)
    end
end)
local theme = {}

-- Helper function to remove some of the tags we usually are not interested in.
-- Returns true if there are no tags left.
function theme.clean_tags(tags)
    tags.odbl = nil
    tags.created_by = nil
    tags.source = nil
    tags['source:ref'] = nil

    return next(tags) == nil
end

return theme

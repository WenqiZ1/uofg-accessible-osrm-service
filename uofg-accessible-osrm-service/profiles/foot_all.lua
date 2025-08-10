api_version = 1

properties = {
    max_speed_for_map_matching = 40,
    weight_name = 'duration',
}

function way_function(way, result)
    local highway = way:get_value_by_key("highway")
    if highway then
        result.forward_mode = mode.walking
        result.backward_mode = mode.walking
        result.forward_speed = 5  -- km/h
        result.backward_speed = 5
        result.name = way:get_value_by_key("name")
        -- 移除 get_length() 调用
    end
end

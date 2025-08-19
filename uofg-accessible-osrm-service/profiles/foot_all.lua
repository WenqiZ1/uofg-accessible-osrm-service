api_version = 1

function setup()
  return {
    properties = {
      weight_name = 'duration',
      max_speed_for_map_matching = 20/3.6,
      u_turn_penalty = 20,
      continue_straight_at_waypoint = true,
    },

    default_mode = mode.walking,
    default_speed = 5,
    oneway_handling = 'specific',
    turn_penalty = 30.0,

    barrier_whitelist = {},
    access_tag_whitelist = { 'yes', 'foot', 'permissive' },
    access_tag_blacklist = { 'no', 'private' },

    restricted_access_tag_list = {},
    restricted_highway_whitelist = {},

    construction_whitelist = {},

    use_turn_restrictions = false,
  }
end

function process_node(profile, node, result)
  local access = node:get_value_by_key("access")
  if access and profile.access_tag_blacklist[access] then
    result.barrier = true
  end
end

function process_way(profile, way, result)
  local highway = way:get_value_by_key("highway")

  if not highway then
    return
  end

  if highway == "motorway" or highway == "motorway_link" then
    return
  end

  result.forward_mode = mode.walking
  result.backward_mode = mode.walking
  result.forward_speed = profile.default_speed
  result.backward_speed = profile.default_speed
end

function process_turn(profile, turn)
  turn.duration = profile.turn_penalty
  if turn.has_traffic_light then
    turn.duration = turn.duration + 2
  end
end

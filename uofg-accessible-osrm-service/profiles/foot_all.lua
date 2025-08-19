api_version = 4

function setup()
  return {
    properties = {
      weight_name = 'duration',
      max_speed_for_map_matching = 20/3.6,
      u_turn_penalty = 20,
      continue_straight_at_waypoint = true,
      use_turn_restrictions = false
    },
    default_mode = mode.walking,
    default_speed = 5,
    oneway_handling = 'specific',
    turn_penalty = 30.0
  }
end

function process_node(profile, node, result)
  local access = node:get_value_by_key("access")
  if access == 'no' or access == 'private' then
    result.barrier = true
  end
end

function process_way(profile, way, result)
  local h = way:get_value_by_key("highway")
  if not h then return end
  if h == "motorway" or h == "motorway_link" then return end
  if way:get_value_by_key("foot") == "no" then return end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = profile.default_speed
  result.backward_speed = profile.default_speed
  result.name = way:get_value_by_key("name") or h
end

function process_turn(profile, turn)
  local t = profile.turn_penalty
  if turn.has_traffic_light then t = t + 2 end
  turn.duration = t
  turn.weight   = t
end

return {
  setup = setup,
  process_node = process_node,
  process_way  = process_way,
  process_turn = process_turn
}

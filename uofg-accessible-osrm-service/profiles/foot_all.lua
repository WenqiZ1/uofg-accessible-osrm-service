api_version = 4

-- Target: realistic pedestrian ETA and shortest-time behaviour
-- Key changes vs your previous file:
--  - Small per-turn cost (1s) instead of 30s
--  - Modest extra at traffic lights (+6s)
--  - Reasonable walking speeds by highway type
--  - Light preference for pedestrian-only corridors

function setup()
  return {
    properties = {
      weight_name = "duration",
      max_speed_for_map_matching = 40/3.6,
      weight_precision = 1,
      use_turn_restrictions = true,
      continue_straight_at_waypoint = true,
      ignore_in_grid = false
    },
    default_mode    = mode.walking,
    default_speed   = 5.2,   -- km/h ≈ 1.44 m/s (close to Google walking)
    oneway_handling = true
  }
end

-- Baseline speeds (km/h)
-- Pedestrian corridors slightly faster; traffic roads slightly slower for pedestrians.
local SPEED = {
  footway = 5.6,
  path = 5.4,
  pedestrian = 5.6,
  steps = 5.0,               -- All-Access allows steps
  living_street = 5.0,
  residential = 4.8,
  service = 4.6,
  track = 4.4,
  tertiary = 4.3, tertiary_link = 4.3,
  secondary = 4.0, secondary_link = 4.0,
  primary = 3.8, primary_link = 3.8,
  unclassified = 4.6
}

function process_node(profile, node, result)
  local access = node:get_value_by_key("access")
  if access == 'no' or access == 'private' then
    -- treat hard "no" nodes as barriers
    result.barrier = true
  end
end

function process_way(profile, way, result)
  local h = way:get_value_by_key("highway")
  if not h then return end
  if way:get_value_by_key("foot") == "no" then return end

  -- Base speed
  local spd = SPEED[h] or profile.default_speed

  -- Light boost for clearly pedestrian-priority tags
  local foot_tag = way:get_value_by_key("foot")
  local footway  = way:get_value_by_key("footway")
  local sidewalk = way:get_value_by_key("sidewalk")
  if (foot_tag == "designated" or foot_tag == "yes"
      or footway == "sidewalk" or sidewalk == "both" or sidewalk == "yes") then
    spd = spd * 1.06
  end

  -- Defensive clamp
  if spd < 3.0 then spd = 3.0 end
  if spd > 6.2 then spd = 6.2 end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name = way:get_value_by_key("name") or h
end

function process_turn(profile, turn)
  -- Small base cost to avoid zig-zag artefacts, but not 30s per turn :)
  local base = 1.0
  if turn.has_traffic_light then base = base + 6.0 end
  turn.duration = base
  turn.weight   = base
end

return {
  setup = setup,
  process_node = process_node,
  process_way  = process_way,
  process_turn = process_turn
}

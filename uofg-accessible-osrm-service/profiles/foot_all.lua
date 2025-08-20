-- all.lua  (API v4)
-- Target: realistic pedestrian ETA + light accessibility-aware penalty
api_version = 4

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
    default_speed   = 5.2,   -- km/h ≈ 1.44 m/s
    oneway_handling = true
  }
end

-- Baseline speeds (km/h)
local SPEED = {
  footway = 5.6, path = 5.4, pedestrian = 5.6, steps = 5.0, -- All-Access allows steps
  living_street = 5.0, residential = 4.8, service = 4.6, track = 4.4,
  tertiary = 4.3, tertiary_link = 4.3, secondary = 4.0, secondary_link = 4.0,
  primary = 3.8, primary_link = 3.8, unclassified = 4.6
}

-- map 3..9 to a light multiplicative ETA factor (F_all in [1.00, ~1.35])
local function acc_to_F_all(acc)
  if not acc then return 1.0 end
  if acc < 3 then acc = 3 end
  if acc > 9 then acc = 9 end
  local beta = 0.35 -- light penalty, preserves through-campus directness
  local F = 1.0 + beta * ((acc - 3.0) / 6.0)
  if F < 1.0 then F = 1.0 end
  if F > 1.35 then F = 1.35 end
  return F
end

local function get_access_score(way)
  -- Prefer precomputed access_score (3..9)
  local acc = tonumber(way:get_value_by_key("access_score"))
  if acc then return acc end
  -- Otherwise compute from slope/surface 1..3
  local slope = tonumber(way:get_value_by_key("slope_score")) or 2
  local surf  = tonumber(way:get_value_by_key("surface_score")) or 2
  return 2 * slope + surf
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
  if way:get_value_by_key("foot") == "no" then return end

  -- base speed
  local spd = SPEED[h] or profile.default_speed

  -- gentle boost for pedestrian-priority tags
  local foot_tag = way:get_value_by_key("foot")
  local footway  = way:get_value_by_key("footway")
  local sidewalk = way:get_value_by_key("sidewalk")
  if (foot_tag == "designated" or foot_tag == "yes"
      or footway == "sidewalk" or sidewalk == "both" or sidewalk == "yes") then
    spd = spd * 1.06
  end

  -- defensive clamps before applying factor
  if spd < 3.0 then spd = 3.0 end
  if spd > 6.2 then spd = 6.2 end

  -- ---- accessibility-aware light ETA penalty (via speed scaling) ----
  local acc = get_access_score(way)             -- 3..9, lower=better
  local F_all = acc_to_F_all(acc)               -- 1.00..~1.35
  spd = spd / F_all                             -- enlarge ETA but keep it realistic
  -- -------------------------------------------------------------------

  -- final clamp after scaling
  if spd < 2.6 then spd = 2.6 end  -- avoid too slow
  if spd > 6.2 then spd = 6.2 end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name = way:get_value_by_key("name") or h
end

function process_turn(profile, turn)
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

-- foot_stepfree.lua  (API v4)
-- Goal: step-free feasibility, strong WEIGHT penalties, and mildly increased ETA
api_version = 4

function setup()
  return {
    properties = {
      weight_name = "accessibility",   -- keep custom weight to steer path choice
      max_speed_for_map_matching = 40/3.6,
      weight_precision = 1,
      use_turn_restrictions = true,
      continue_straight_at_waypoint = true,
      ignore_in_grid = false
    },
    default_mode    = mode.walking,
    default_speed   = 4.9,   -- km/h, slightly conservative baseline
    oneway_handling = true
  }
end

-- conservative pedestrian speeds (km/h)
local SPEED = {
  footway=5.0, path=4.8, pedestrian=5.0,
  living_street=4.6, residential=4.5, service=4.3, track=3.6,
  tertiary=3.9, tertiary_link=3.9, secondary=3.7, secondary_link=3.7,
  primary=3.5, primary_link=3.5, unclassified=4.4
}

-- textual surface fallback -> factor (for WEIGHT only, not ETA)
local SURFACE_TEXT_FACTOR = {
  asphalt=1.0, concrete=1.0, ["paving_stones:fine"]=1.05, paving_stones=1.1,
  compacted=1.08, fine_gravel=1.12, gravel=1.25,
  sett=1.3, ["cobblestone:flattened"]=1.3, cobblestone=1.45,
  unpaved=1.25, dirt=1.35, ground=1.2, grass=1.5, sand=1.6
}

-- helper: 3..9 -> mild ETA factor (F_eta in [1.00, ~1.25])
local function acc_to_F_eta(acc)
  if not acc then return 1.0 end
  if acc < 3 then acc = 3 end
  if acc > 9 then acc = 9 end
  local beta_eta = 0.30 -- milder than weight penalties; avoids overlong ETAs
  local F = 1.0 + beta_eta * ((acc - 3.0) / 6.0)
  if F < 1.0 then F = 1.0 end
  if F > 1.25 then F = 1.25 end
  return F
end

local function get_access_score(way)
  local acc = tonumber(way:get_value_by_key("access_score"))
  if acc then return acc end
  local slope = tonumber(way:get_value_by_key("slope_score")) or 2
  local surf  = tonumber(way:get_value_by_key("surface_score")) or 2
  return 2 * slope + surf
end

function process_node(profile, node, result) end

function process_way(profile, way, result)
  local h = way:get_value_by_key("highway")
  if not h then return end

  -- ban stairs for step-free
  if h == "steps" then
    result.forward_mode  = mode.inaccessible
    result.backward_mode = mode.inaccessible
    return
  end

  if way:get_value_by_key("foot") == "no" then return end

  -- ---- ETA part (duration via speed) ----
  local spd = SPEED[h] or profile.default_speed

  local foot_tag = way:get_value_by_key("foot")
  local footway  = way:get_value_by_key("footway")
  local sidewalk = way:get_value_by_key("sidewalk")
  if (foot_tag == "designated" or foot_tag == "yes"
      or footway == "sidewalk" or sidewalk == "both" or sidewalk == "yes") then
    spd = spd * 1.03
  end

  -- defensive clamp before ETA scaling
  if spd < 3.0 then spd = 3.0 end
  if spd > 5.4 then spd = 5.4 end

  -- Mild ETA increase based on access_score (solve "Step-Free too short time")
  local acc = get_access_score(way)         -- 3..9
  local F_eta = acc_to_F_eta(acc)           -- 1.00..~1.25
  spd = spd / F_eta

  -- final clamp after scaling
  if spd < 2.6 then spd = 2.6 end
  if spd > 5.4 then spd = 5.4 end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name = way:get_value_by_key("name") or h

  -- ---- Accessibility WEIGHT part (steers path choice) ----
  -- base per-metre time from ETA (sec per metre)
  local base_rate = 1.0 / (spd / 3.6)

  -- surface factor: prefer numeric score; fallback to text
  local s_num = way:get_value_by_key("surface_score")
             or way:get_value_by_key("surf_ratin")
             or way:get_value_by_key("surface:score")
             or way:get_value_by_key("surface_rating")
  local factor = 1.0
  if s_num then
    -- 1..3 -> map to gentle..strong (for WEIGHT only)
    local x = tonumber(s_num) or 2
    if x < 1 then x = 1 end
    if x > 3 then x = 3 end
    local map = { [1]=1.00, [2]=1.25, [3]=1.70 }  -- tuneable
    factor = map[x] or 1.25
  else
    local s_txt = (way:get_value_by_key("surface") or ""):lower()
    factor = SURFACE_TEXT_FACTOR[s_txt] or 1.0
  end

  -- optional: make slope explicit in WEIGHT too (not ETA)
  local slope = tonumber(way:get_value_by_key("slope_score")) or 2
  local slope_map = { [1]=1.00, [2]=1.35, [3]=1.90 }  -- tuneable
  factor = factor * (slope_map[slope] or 1.35)

  -- also consider composite access_score if present (3..9)
  local acc_map = { [3]=1.00,[4]=1.15,[5]=1.35,[6]=1.65,[7]=2.10,[8]=2.70,[9]=3.40 }
  factor = factor * (acc_map[acc] or 1.0)

  local rate = base_rate * factor
  if rate < 0.25 then rate = 0.25 end
  if rate > 12.0 then rate = 12.0 end
  result.forward_rate  = rate
  result.backward_rate = rate
end

function process_turn(profile, turn)
  local base = 2.0
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

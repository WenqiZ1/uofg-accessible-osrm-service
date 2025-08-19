-- profiles/foot_stepfree.lua  (v4)
-- Goal: more realistic ETA for step-free routing while keeping accessibility-weighted path choice.

api_version = 4

function setup()
  return {
    properties = {
      weight_name = "accessibility",        -- keep custom weight
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

-- Slightly conservative pedestrian speeds (km/h)
-- Compared to All-Access: keep them a little lower to avoid optimistic ETAs.
local SPEED = {
  footway=5.0,           -- was ~5.4–5.6 in fast profiles
  path=4.8,
  pedestrian=5.0,
  living_street=4.6,
  residential=4.5,
  service=4.3,
  track=3.6,
  tertiary=3.9, tertiary_link=3.9,
  secondary=3.7, secondary_link=3.7,
  primary=3.5, primary_link=3.5,
  unclassified=4.4
}

-- Optional textual surface fallback factors (affect WEIGHT via rate only; not ETA)
local SURFACE_TEXT_FACTOR = {
  asphalt=1.0, concrete=1.0, ["paving_stones:fine"]=1.05, paving_stones=1.1,
  compacted=1.08, fine_gravel=1.12, gravel=1.25,
  sett=1.3, ["cobblestone:flattened"]=1.3, cobblestone=1.45,
  unpaved=1.25, dirt=1.35, ground=1.2, grass=1.5, sand=1.6
}

-- Numeric score (e.g., surface_score / surf_ratin / surface:score / surface_rating)
-- mapped to multiplicative penalty for WEIGHT (not ETA).
local function score_to_factor(s)
  local x = tonumber(s); if not x then return nil end
  if x < 0 then x = 0 end; if x > 10 then x = 10 end
  local map = { [0]=1.0,[1]=1.03,[2]=1.06,[3]=1.12,[4]=1.25,[5]=1.42,[6]=1.65,[7]=1.95,[8]=2.35,[9]=2.9,[10]=3.6 }
  local lo,hi = math.floor(x), math.ceil(x)
  if map[lo] and map[hi] then
    local t = x - lo; return map[lo]*(1-t)+map[hi]*t
  end
  return map[lo] or 1.0
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

  -- --- ETA part (duration) --- --
  local spd = SPEED[h] or profile.default_speed

  -- small boost for clearly pedestrian-priority tags (kept modest)
  local foot_tag = way:get_value_by_key("foot")
  local footway  = way:get_value_by_key("footway")
  local sidewalk = way:get_value_by_key("sidewalk")
  if (foot_tag == "designated" or foot_tag == "yes"
      or footway == "sidewalk" or sidewalk == "both" or sidewalk == "yes") then
    spd = spd * 1.03    -- gentle boost only
  end

  -- defensive clamp
  if spd < 3.0 then spd = 3.0 end
  if spd > 5.4 then spd = 5.4 end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name = way:get_value_by_key("name") or h

  -- --- Accessibility WEIGHT part (does not change ETA) --- --
  local s_num = way:get_value_by_key("surface_score")
             or way:get_value_by_key("surf_ratin")
             or way:get_value_by_key("surface:score")
             or way:get_value_by_key("surface_rating")
  local factor = score_to_factor(s_num)
  if not factor then
    local s_txt = (way:get_value_by_key("surface") or ""):lower()
    factor = SURFACE_TEXT_FACTOR[s_txt] or 1.0
  end

  -- Optional: if you also store access_score, multiply here to strengthen avoidance
  local acc = tonumber(way:get_value_by_key("access_score"))
  if acc and acc >= 3 then
    local acc_map = { [3]=1.00,[4]=1.15,[5]=1.35,[6]=1.65,[7]=2.1,[8]=2.7,[9]=3.4,[10]=4.2 }
    factor = factor * (acc_map[acc] or 1.0)
  end

  -- Rate controls WEIGHT per metre; ETA still uses speed above.
  local base_rate = 1.0 / (spd / 3.6)     -- sec per metre from the ETA speed
  local rate = base_rate * factor
  if rate < 0.25 then rate = 0.25 end
  if rate > 12.0 then rate = 12.0 end
  result.forward_rate  = rate
  result.backward_rate = rate
end

function process_turn(profile, turn)
  -- Slightly higher than All-Access to avoid optimistic ETAs on complex junctions
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

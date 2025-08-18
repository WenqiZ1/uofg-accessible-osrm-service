-- Step-Free profile (Render-ready, no external requires)
-- Rules:
--   1) Forbid stairs (highway=steps)
--   2) Penalize surfaces with higher numeric score (surface_score / surf_ratin / surface:score / surface_rating)
--   3) If no numeric score, lightly penalize rough textual surfaces
--   4) ETA from speed; route choice from rate (weight_name="accessibility")

function setup()
  return {
    properties = {
      weight_name = "accessibility",
      max_speed_for_map_matching = 40/3.6,
      weight_precision = 1,
      use_turn_restrictions = true,
      continue_straight_at_waypoint = true,
      ignore_in_grid = false
    },
    default_mode    = mode.walking,
    default_speed   = 5.0,    -- km/h, used for ETA
    oneway_handling = true
  }
end

-- Baseline walking speeds for ETA (km/h)
local SPEED = {
  footway=5.0, path=4.8, pedestrian=5.0, living_street=4.8,
  residential=4.8, service=4.6, track=3.6,
  tertiary=4.2, secondary=4.0, primary=3.8, unclassified=4.4
}

-- Light fallback penalties for rough textual surfaces (if no numeric score provided)
local SURFACE_TEXT_FACTOR = {
  -- smoother
  asphalt=1.0, concrete=1.0, paving_stones=1.1, ["paving_stones:fine"]=1.05,
  compacted=1.05, fine_gravel=1.1, gravel=1.2,
  -- rougher
  sett=1.25, cobblestone=1.35, ["cobblestone:flattened"]=1.25,
  unpaved=1.25, dirt=1.3, ground=1.2, grass=1.4, sand=1.5
}

-- Map a numeric surface score -> multiplicative factor on per-meter cost (>=1)
local function score_to_factor(s)
  -- Interpret any numeric value; higher = worse
  local x = tonumber(s)
  if not x then return nil end
  if x < 0 then x = 0 end
  if x > 10 then x = 10 end
  -- Piecewise: gentle at low scores, stronger later; adjust to taste
  -- 0/1 -> 1.0 ; 2 -> 1.1 ; 3 -> 1.2 ; 4 -> 1.35 ; 5 -> 1.55 ; 6 -> 1.8 ; 7 -> 2.1 ; 8 -> 2.5 ; 9 -> 3.0 ; 10 -> 3.6
  local map = { [0]=1.0, [1]=1.0, [2]=1.1, [3]=1.2, [4]=1.35, [5]=1.55, [6]=1.8, [7]=2.1, [8]=2.5, [9]=3.0, [10]=3.6 }
  -- If not integer, interpolate roughly:
  local lo = math.floor(x); local hi = math.ceil(x)
  if map[lo] and map[hi] then
    local t = x - lo
    return map[lo]*(1-t) + map[hi]*t
  end
  return map[math.floor(x)] or 1.0
end

function process_node(profile, node, result)
  -- extend here for elevators/kerbs if needed
end

function process_way(profile, way, result)
  local h = way:get_value_by_key("highway")
  if not h then return end

  -- Step-Free hard ban on stairs
  if h == "steps" then
    result.forward_mode  = mode.inaccessible
    result.backward_mode = mode.inaccessible
    return
  end

  -- Respect explicit foot=no
  local foot = way:get_value_by_key("foot")
  if foot == "no" then return end

  -- ETA speeds
  local spd = SPEED[h] or 4.6
  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name = way:get_value_by_key("name") or h

  -- === Surface-based penalty ===
  -- Preferred numeric tag (higher is worse):
  local s_num = way:get_value_by_key("surface_score")
                 or way:get_value_by_key("surf_ratin")
                 or way:get_value_by_key("surface:score")
                 or way:get_value_by_key("surface_rating")

  local factor = score_to_factor(s_num)

  if not factor then
    -- No numeric score; fall back to textual 'surface'
    local s_txt = (way:get_value_by_key("surface") or ""):lower()
    factor = SURFACE_TEXT_FACTOR[s_txt] or 1.0
  end

  -- Build per-meter cost (rate): base_rate from time, then multiply by factor
  local base_rate = 1.0 / (spd / 3.6)     -- seconds per meter
  local rate = base_rate * factor
  if rate < 0.2 then rate = 0.2 end
  if rate > 10.0 then rate = 10.0 end

  result.forward_rate  = rate
  result.backward_rate = rate
end

function process_turn(profile, turn)
  -- modest turn costs
  if turn.has_traffic_light then
    turn.duration = 2.0
    turn.weight   = 2.0
  else
    turn.duration = 1.0
    turn.weight   = 1.0
  end
end

api_version = 4

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
    default_speed   = 5.0,
    oneway_handling = true
  }
end

local SPEED = {
  footway=5.0, path=4.8, pedestrian=5.0, living_street=4.8,
  residential=4.8, service=4.6, track=3.6,
  tertiary=4.2, secondary=4.0, primary=3.8, unclassified=4.4
}

local SURFACE_TEXT_FACTOR = {
  asphalt=1.0, concrete=1.0, ["paving_stones:fine"]=1.05, paving_stones=1.1,
  compacted=1.05, fine_gravel=1.1, gravel=1.2,
  sett=1.25, ["cobblestone:flattened"]=1.25, cobblestone=1.35,
  unpaved=1.25, dirt=1.3, ground=1.2, grass=1.4, sand=1.5
}

local function score_to_factor(s)
  local x = tonumber(s); if not x then return nil end
  if x < 0 then x = 0 end; if x > 10 then x = 10 end
  local map = { [0]=1.0,[1]=1.0,[2]=1.1,[3]=1.2,[4]=1.35,[5]=1.55,[6]=1.8,[7]=2.1,[8]=2.5,[9]=3.0,[10]=3.6 }
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

  -- 禁楼梯
  if h == "steps" then
    result.forward_mode  = mode.inaccessible
    result.backward_mode = mode.inaccessible
    return
  end

  if way:get_value_by_key("foot") == "no" then return end

  local spd = SPEED[h] or 4.6
  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name = way:get_value_by_key("name") or h

  -- surface 数值分：越高越差
  local s_num = way:get_value_by_key("surface_score")
             or way:get_value_by_key("surf_ratin")
             or way:get_value_by_key("surface:score")
             or way:get_value_by_key("surface_rating")
  local factor = score_to_factor(s_num)
  if not factor then
    local s_txt = (way:get_value_by_key("surface") or ""):lower()
    factor = SURFACE_TEXT_FACTOR[s_txt] or 1.0
  end

  -- rate = 基于时间的每米成本 × 惩罚因子
  local base_rate = 1.0 / (spd / 3.6)          -- 秒/米
  local rate = base_rate * factor
  if rate < 0.2 then rate = 0.2 end
  if rate > 10.0 then rate = 10.0 end

  result.forward_rate  = rate
  result.backward_rate = rate
end

function process_turn(profile, turn)
  turn.duration = turn.has_traffic_light and 2.0 or 1.0
  turn.weight   = turn.duration
end

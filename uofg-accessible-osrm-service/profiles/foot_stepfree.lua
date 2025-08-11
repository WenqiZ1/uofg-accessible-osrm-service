-- Step-Free walking profile (robust, CH/MLD 皆可)
api_version = 1

properties = {
  weight_name = 'duration',
  max_speed_for_map_matching = 40,  -- km/h
}

-- 基础速度（km/h）
local BASE_SPEED = 5.0

-- 允许的步行道路类型（保底不清网）
local ALLOWED_HW = {
  primary=true, secondary=true, tertiary=true, unclassified=true,
  residential=true, service=true, living_street=true,
  footway=true, path=true, pedestrian=true, track=true,
  steps=false  -- 明确不要楼梯
}

-- “强过滤”阈值（触发则剔除该 way）
local MAX_SLOPE_PCT = 8      -- 超过 8% 视为非步行无台阶友好
local MIN_ACCESS_SCORE = 4   -- 你自定义的 access_score（如存在）最低分

-- “软惩罚”参数（不剔除，只降速）
local PENALTY = {
  slope_moderate = 0.85,     -- 5–8% 坡度
  surface_rough = 0.80,      -- 粗糙表面
  smoothness_bad = 0.75,     -- smoothness=bad/very_bad
  kerb_raised = 0.85,        -- 路缘较高
}

-- 判定为“粗糙表面”的集合
local ROUGH_SURFACE = {
  cobblestone=true, sett=true, unpaved=true, gravel=true, fine_gravel=true,
  compacted=true, ground=true, dirt=true, grass=true, sand=true
}

-- 解析 incline（返回百分比数字或 nil）
local function parse_incline(val)
  if not val then return nil end
  -- 常见： "5%", "-7%", "up", "down", "0.08", "8"
  val = tostring(val)
  if val == "up" or val == "down" then return nil end
  local pct = val:match("^%s*([%-]?%d+%.?%d*)%s*%%%s*$")
  if pct then return tonumber(pct) end
  local num = val:match("^%s*([%-]?%d+%.?%d*)%s*$")
  if num then
    local n = tonumber(num)
    -- 值在(0,1] 多数是小数形式的“比例”，放大为百分比
    if n and n > 0 and n <= 1 then return n * 100 end
    return n
  end
  return nil
end

-- 取数字标签
local function num_tag(way, key)
  local v = way:get_value_by_key(key)
  if not v then return nil end
  local n = tonumber(v)
  return n
end

function way_function(way, result)
  local highway = way:get_value_by_key("highway")
  if not highway then return end
  if highway == "steps" then return end
  if not ALLOWED_HW[highway] then return end

  -- 显式禁止步行
  local access = way:get_value_by_key("access")
  local foot   = way:get_value_by_key("foot")
  if access == "no" and foot ~= "yes" then return end
  if foot == "no" then return end
  -- wheelchair=no 严格一点：不直接剔除，仅做轻惩罚（避免清网）
  local wheelchair = way:get_value_by_key("wheelchair")

  -- 自定义 access_score（若存在且过低则剔除）
  local acc_score = num_tag(way, "access_score")
  if acc_score and acc_score < MIN_ACCESS_SCORE then return end

  -- 坡度：自定义 slope_score 优先，其次 inclines
  local slope_score = num_tag(way, "slope_score")
  local incline_pct = parse_incline(way:get_value_by_key("incline"))

  -- 强过滤：极陡坡
  if incline_pct and math.abs(incline_pct) > MAX_SLOPE_PCT then
    return
  end

  -- 基础速度
  local speed = BASE_SPEED

  -- 软惩罚：中等坡度
  if incline_pct and math.abs(incline_pct) > 5 and math.abs(incline_pct) <= MAX_SLOPE_PCT then
    speed = speed * PENALTY.slope_moderate
  end

  -- 表面与可达性加权
  local surface = way:get_value_by_key("surface")
  if ROUGH_SURFACE[surface or ""] then
    speed = speed * PENALTY.surface_rough
  end

  local smooth = way:get_value_by_key("smoothness")
  if smooth == "bad" or smooth == "very_bad" or smooth == "horrible" then
    speed = speed * PENALTY.smoothness_bad
  end

  local kerb = way:get_value_by_key("kerb")
  if kerb == "raised" or kerb == "rolled" then
    speed = speed * PENALTY.kerb_raised
  end

  if wheelchair == "no" then
    speed = speed * 0.9
  elseif wheelchair == "yes" then
    speed = speed * 1.05
  end

  -- 最低速度保护（避免 0）
  if speed < 1.5 then speed = 1.5 end

  result.name = way:get_value_by_key("name")
  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = speed
  result.backward_speed = speed
end

function turn_function(turn)
  -- 没有特别的转向惩罚
end

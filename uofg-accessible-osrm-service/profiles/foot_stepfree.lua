-- OSRM profile API version 0
api_version = 0

-- 可选：setup 在 v0 里不会影响 way_function 的可达性判断，但可以保留
function setup()
  return {
    properties = {
      weight_name = 'duration',
      u_turn_penalty = 0,
      continue_straight_at_waypoint = true
    }
  }
end

-- 基础速度（km/h），不同 highway 给个合理基线，保证“永远 > 0”
local BASE_SPEED = {
  footway = 5, path = 4, pedestrian = 4, living_street = 5,
  residential = 5, service = 5, track = 3, steps = 3,
  tertiary = 4, secondary = 4, primary = 3, unclassified = 4
}

-- 你的可达性分数 -> 速度下限
local ACCESS_SPEED = { [2]=5.0,[3]=4.0,[4]=3.0,[5]=2.4,[6]=2.0,[7]=1.2,[8]=0.8,[9]=0.6 }

local function penalty_factor(score, surf_ratin, slope_rating, is_steps)
  -- 越大越慢（乘到 duration 上）
  local p = 1.0
  if score and score > 2 then p = p + (score - 2) * 0.6 end
  if surf_ratin and surf_ratin >= 3 then p = p * 1.4 end
  if slope_rating and slope_rating >= 3 then p = p * 1.4 end
  if is_steps then p = p * 6.0 end  -- 楼梯巨惩罚（若不硬禁）
  return p
end

function way_function(way, result)
  local highway = way:get_value_by_key('highway')
  if not highway then return end

  -- 明确禁止步行的边直接丢弃
  local foot = way:get_value_by_key('foot')
  if foot == 'no' then return end

  -- 楼梯：如果明确标注不可替代的无障碍（step_free=no），才硬禁
  local is_steps  = (highway == 'steps')
  local step_free = way:get_value_by_key('step_free')
  if is_steps and (step_free == 'no' or step_free == nil) then
    -- 如果你确实想完全禁用楼梯，保留这行 return；若想保留、仅惩罚，则注释掉 return
    return
  end

  -- 读取你数据表里的字段（nil 安全）
  local score      = tonumber(way:get_value_by_key('access_sco')) or 6
  local surf_ratin = tonumber(way:get_value_by_key('surf_ratin')) or 2
  local slope_rate = tonumber(way:get_value_by_key('MEAN_Recla')) or 2

  -- 先取 highway 对应的基线速度，再和可达性速度取 max，保证 > 0
  local base_speed = BASE_SPEED[highway] or 3.0
  local access_min = ACCESS_SPEED[score] or 2.0
  local speed = math.max(base_speed, access_min)
  if speed < 0.5 then speed = 0.5 end

  -- 设置为可走（**关键：不要 return，不要设 0 速度**）
  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = speed
  result.backward_speed = speed
  result.name           = way:get_value_by_key('name') or highway

  -- 惩罚：把 duration 放大（旧 API 里 duration 会基于速度计算）
  local pf = penalty_factor(score, surf_ratin, slope_rate, is_steps)
  if result.duration and result.duration > 0 then
    result.duration = result.duration * pf
    if result.weight then result.weight = result.duration end
  end
end

function node_function(node, result)
  -- 这里保持空实现即可
end

function segment_function(segment, result)
  -- v0 可不实现
end

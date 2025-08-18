-- 基于 OSRM v5.x 步行模板的极简示例（要点）
-- 你的 Render 镜像里已有 foot_all.lua，可参考其写法把本片段合入

local walking_speed_kph = 5.0

-- 映射分数到保底速度（km/h），nil -> 2.5（保底）
local ACCESS_SPEED = { [2]=5.0,[3]=4.0,[4]=3.0,[5]=2.4,[6]=1.6,[7]=1.0,[8]=0.6,[9]=0.4 }

local function penalty_factor(score, surf_ratin, slope_rating, is_steps)
  local p = 1.0
  if score and score > 2 then p = p + (score - 2) * 0.6 end
  if surf_ratin and surf_ratin >= 3 then p = p * 1.5 end
  if slope_rating and slope_rating >= 3 then p = p * 1.5 end
  if is_steps then p = p * 6.0 end
  return p
end

function process_way(profile, way, result)
  local highway = way:get_value_by_key('highway')
  if not highway then return end                -- 没有 highway 直接跳过

  -- 读取你在 OSM 里写入的自定义属性（nil 安全）
  local score      = tonumber(way:get_value_by_key('access_sco'))
  local surf_ratin = tonumber(way:get_value_by_key('surf_ratin'))
  local slope_rate = tonumber(way:get_value_by_key('MEAN_Recla'))  -- 按你的列名

  local surface    = way:get_value_by_key('surface')
  local step_free  = way:get_value_by_key('step_free')             -- 如果你写了这个
  local is_steps   = (highway == 'steps')

  -- 仅硬禁“明确不可达的楼梯”；务必不要扩大到其它类型！
  if is_steps and (step_free == 'no' or step_free == nil) then
    return
  end

  -- 其余一律可走：给出一个>0的速度，避免被当作“无边”
  local base_speed = ACCESS_SPEED[score or 6] or 2.0
  if base_speed < 0.1 then base_speed = 0.1 end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = base_speed
  result.backward_speed = base_speed
  result.name           = way:get_value_by_key('name') or highway

  -- 惩罚（保持连通、强烈偏好无障碍）
  local pf = penalty_factor(score, surf_ratin, slope_rate, is_steps)
  if result.duration and result.duration > 0 then
    result.duration = result.duration * pf
    if result.weight then result.weight = result.duration end
  end
end


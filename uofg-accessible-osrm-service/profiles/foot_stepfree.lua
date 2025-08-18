-- 基于 OSRM v5.x 步行模板的极简示例（要点）
-- 你的 Render 镜像里已有 foot_all.lua，可参考其写法把本片段合入

local walking_speed_kph = 5.0

-- 根据 access_sco（分越高越差）映射速度（km/h）
local ACCESS_SPEED = {
  [2] = 5.0,  -- 最好
  [3] = 4.0,
  [4] = 3.0,
  [5] = 2.4,
  [6] = 1.6,
  [7] = 1.0,
  [8] = 0.6,
  [9] = 0.4   -- 很差但仍保留连通
}

-- 额外惩罚（倍率），在 duration 基础上乘以该系数
local function penalty_factor(score, surf_ratin, slope_rating, is_steps)
  local p = 1.0
  if score and score > 2 then
    p = p + (score - 2) * 0.6         -- 分数每+1，额外+0.6 倍时长
  end
  if surf_ratin and surf_ratin >= 3 then
    p = p * 1.5                        -- 表面较差
  end
  if slope_rating and slope_rating >= 3 then
    p = p * 1.5                        -- 坡度较陡
  end
  if is_steps then
    p = p * 6.0                        -- 楼梯极重惩罚（下面可能直接禁用）
  end
  return p
end

function setup()
  return {
    properties = {
      weight_name = 'duration',     -- 用时长作为权重
      max_speed_for_map_matching = walking_speed_kph
    }
  }
end

function process_way(profile, way, result)
  -- 仅处理可步行的道路（你可以参考 foot_all.lua 的标准判断）
  local highway = way:get_value_by_key('highway')
  if not highway then return end

  -- 取你的自定义字段
  local access_sco  = tonumber(way:get_value_by_key('access_sco'))        -- 2~9，分越高越差
  local surf_ratin  = tonumber(way:get_value_by_key('surf_ratin'))        -- 表面评分
  local slope_rate  = tonumber(way:get_value_by_key('MEAN_Recla'))        -- 你表里的坡度列名（按需改名）
  local surface     = way:get_value_by_key('surface')
  local step_free   = way:get_value_by_key('step_free')                   -- 若你另存了无障碍标记
  local is_steps    = (highway == 'steps')

  -- 1) 对“明确不可达”的楼梯硬禁用（无电梯/坡道信息时）
  --    如果你有楼梯旁的电梯/坡道连通，请不要在这里硬禁；或改用极大惩罚代替。
  if is_steps and (step_free == 'no' or step_free == nil) then
    return
  end

  -- 2) 基础速度：按 access_sco 映射（没有则取保守值）
  local speed = ACCESS_SPEED[access_sco or 6] or 2.0
  -- 保障连通性：不要把速度设为 0
  if speed < 0.1 then speed = 0.1 end

  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = speed
  result.backward_speed = speed

  -- 3) 额外惩罚，作用到权重/时长上（强烈回避差的路段，但仍可通过）
  local pf = penalty_factor(access_sco, surf_ratin, slope_rate, is_steps)
  -- OSRM 的 Lua 接口中通常以 duration 近似 = 距离 / 速度，再乘惩罚系数
  -- 这里只需告诉引擎有惩罚（部分版本支持 result.weight；不支持时，可通过 turn/segment penalties 或低速实现）
  result.duration = result.duration * pf
  -- 如果你的 osrm-backend 版本支持：
  if result.weight then
    result.weight = result.duration
  end
end

function process_turn(profile, turn)
  -- 可选：对转弯增加少量惩罚（略）
end

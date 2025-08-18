-- step-free profile: optimize accessibility cost while keeping ETA from speed
-- access_score: 3 (best) .. 9 (worst)

local find_access_tag = require("lib/access").find_access_tag
local utils           = require("lib/utils")

function setup()
  return {
    properties = {
      weight_name = "accessibility",     -- 选路依据：自定义权重
      max_speed_for_map_matching = 40/3.6,
      weight_precision = 1,
      use_turn_restrictions = true,
      continue_straight_at_waypoint = true,
      ignore_in_grid = false
    },
    default_mode     = mode.walking,
    default_speed    = 5.0,              -- km/h，用于 ETA
    oneway_handling  = true,
    -- 可选：直接排除极差边
    -- excludable = { { condition = "access_score > 8", exclude = true } }
  }
end

local SPEED = {                           -- km/h：ETA 仍按速度算
  footway=5.0, path=4.8, pedestrian=5.0, living_street=4.8,
  residential=4.8, service=4.6, track=3.5, steps=3.0,
  tertiary=4.2, secondary=4.0, primary=3.8, unclassified=4.4
}

-- 把 access_score -> rate 因子（每米成本倍数，>=1）
local function score_to_factor(s)
  -- 默认友好：3
  local score = tonumber(s) or 3
  if score < 3 then score = 3 end
  if score > 9 then score = 9 end
  -- 线性或略指数：3→1.0, 4→1.2, 5→1.5, 6→1.9, 7→2.4, 8→3.0, 9→3.8（可按需调整）
  local map = { [3]=1.0, [4]=1.2, [5]=1.5, [6]=1.9, [7]=2.4, [8]=3.0, [9]=3.8 }
  return map[score] or 1.0
end

function process_node(profile, node, result)
  -- 可按需处理 elevator/kerb 等节点，这里留空
end

function process_way(profile, way, result)
  local highway = way:get_value_by_key("highway")
  if not highway then return end

  -- Step-Free：硬禁楼梯
  if highway == "steps" then
    result.forward_mode  = mode.inaccessible
    result.backward_mode = mode.inaccessible
    return
  end

  -- 明确禁止步行的边直接丢弃
  local foot = way:get_value_by_key("foot")
  if foot == "no" then return end

  -- ETA 的速度设定
  local spd = SPEED[highway] or 4.6
  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = spd
  result.backward_speed = spd
  result.name           = way:get_value_by_key("name") or highway

  -- 读取你的可达性分数（若没打标，默认 3 = 友好）
  local access_score = way:get_value_by_key("access_score")
  local factor = score_to_factor(access_score)

  -- 关键：用 rate（每米成本）承载“可达性代价”
  -- OSRM 的权重 = 距离(米) * rate(秒/米或无量纲常数)，这里用相对因子即可
  -- 为避免极端，把 rate 下限设为 1/步行最快速度，上限做个夹取
  local base_rate = 1.0 / (spd / 3.6)   -- 以“时间权重”为基（秒/米）
  local rate = base_rate * factor

  -- 如果你希望“只优化可达性、ETA 不被影响”，也可以：
  --   rate = (1.0) * factor
  -- 这样权重与速度解耦，但通常与 ETA 稍有偏离；上面选择“以时间为基再乘因子”更直观
  if rate < 0.2 then rate = 0.2 end
  if rate > 10.0 then rate = 10.0 end

  result.forward_rate  = rate
  result.backward_rate = rate
end

function process_turn(profile, turn)
  -- 适度转向代价；也可按红绿灯加重
  if turn.has_traffic_light then
    turn.weight   = 2.0
    turn.duration = 2.0
  else
    turn.weight   = 1.0
    turn.duration = 1.0
  end
end


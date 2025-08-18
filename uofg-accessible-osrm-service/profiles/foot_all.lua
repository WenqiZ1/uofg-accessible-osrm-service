-- === foot_all.lua (All-Access 最短路/穿校园 优先) ===
properties = {
  use_turn_restrictions = true,

  -- 允许更多访问（校园里很多 private/permissive）
  access_tag_whitelist = { 'yes','permissive','designated','destination','private' },
  access_tag_blacklist  = { 'no' },

  allow_steps = true,   -- All Access 允许楼梯
}

-- 允许通过的一些 barrier（否则会被当成阻断）
local barrier_whitelist = {
  gate = true, bollard = true, lift_gate = true, entrance = true,
  cycle_barrier = true, sally_port = true, turnstile = true
}

-- 按道路类型给速度（km/h）。人行路更快，机动车道更慢 => 更偏 “穿校园”
local base_speed = {
  footway = 6.0, path = 6.0, pedestrian = 6.0, steps = 5.5,
  living_street = 5.0, service = 4.6, track = 4.6, residential = 4.6,
  tertiary = 4.2, tertiary_link = 4.2, secondary = 3.8, secondary_link = 3.8,
  primary = 3.5, primary_link = 3.5
}

function node_function (node, result)
  local barrier = node:get_value_by_key('barrier')
  if barrier and not barrier_whitelist[barrier] then
    -- 非白名单的 barrier 视作阻断
    result.barrier = true
  end
end

function way_function (way, result)
  local highway = way:get_value_by_key('highway')
  if not highway then return end

  -- 允许的道路类型
  local allowed = {
    footway=true, path=true, pedestrian=true, steps=true,
    living_street=true, service=true, track=true, residential=true,
    tertiary=true, tertiary_link=true, secondary=true, secondary_link=true,
    primary=true, primary_link=true
  }
  if not allowed[highway] then return end

  -- 基础速度
  local speed = base_speed[highway] or 4.5

  -- 对“人行优先”的标记再加速，进一步偏爱走校园内部通道
  local foot_tag = way:get_value_by_key('foot')
  local footway_tag = way:get_value_by_key('footway')
  local sidewalk   = way:get_value_by_key('sidewalk')
  if (foot_tag == 'designated' or foot_tag == 'yes'
      or footway_tag == 'sidewalk' or sidewalk == 'both' or sidewalk == 'yes') then
    speed = speed * 1.20
  end

  -- 对很差的路面略微降速（保持宽松，不要太狠）
  local surf_rate = tonumber(way:get_value_by_key('surf_ratin') or '') or 0
  if surf_rate >= 3 then
    speed = speed * 0.9
  end

  -- 设定行走模式与速度（OSRM 会用 路长/速度 计算权重）
  result.forward_mode   = mode.walking
  result.backward_mode  = mode.walking
  result.forward_speed  = speed
  result.backward_speed = speed
end

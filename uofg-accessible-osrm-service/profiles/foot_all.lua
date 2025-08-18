-- 顶部：允许更宽松的访问
properties = {
  -- 允许使用限制（turn restriction 等）没问题
  use_turn_restrictions = true,
  -- 关键：不要过度过滤 access
  -- 让私有步道也可走（如果你想更严格，可以去掉 'private'）
  access_tag_whitelist = { 'yes','permissive','designated','destination','private' },
  access_tag_blacklist = { 'no' }, -- 只屏蔽明确 no 的
  -- 楼梯允许
  allow_steps = true
}

-- way_function：只过滤明显不可走的（如 motorways 等），不要用 access_sco 做任何惩罚
function way_function(way, result)
  local highway = way:get_value_by_key('highway')
  if not highway then return end

  -- 允许的步行类型
  local allowed = {
    footway=true, path=true, pedestrian=true, living_street=true, service=true,
    track=true, residential=true, steps=true, tertiary=true, secondary=true, primary=true
  }
  if not allowed[highway] then return end

  -- 允许走 steps（All-Access 的设定）
  -- 如果你特别想“偏好非楼梯”，可以给 steps 轻微 penalty，但不要屏蔽
  local speed = 4.5 -- km/h，统一一个常数速度就行
  result.forward_speed = speed
  result.backward_speed = speed

  result.forward_mode = mode.walking
  result.backward_mode = mode.walking

  -- 只按距离
  result.weight = way:get_distance() -- 或者设置成 1，OSRM 会等价按距离
end


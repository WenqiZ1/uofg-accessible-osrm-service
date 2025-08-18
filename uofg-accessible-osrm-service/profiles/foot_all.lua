properties = {
  use_turn_restrictions = true,
  -- 宽松访问：把 private 也放开（校园里常见）
  access_tag_whitelist = { 'yes','permissive','designated','destination','private' },
  access_tag_blacklist = { 'no' },
  allow_steps = true
}

function way_function(way, result)
  local highway = way:get_value_by_key('highway')
  if not highway then return end

  local allowed = {
    footway=true, path=true, pedestrian=true, living_street=true, service=true,
    track=true, residential=true, steps=true, tertiary=true, secondary=true, primary=true
  }
  if not allowed[highway] then return end

  -- 恒定速度（km/h）
  local speed = 4.5

  result.forward_mode  = mode.walking
  result.backward_mode = mode.walking
  result.forward_speed = speed
  result.backward_speed= speed

  -- 不做任何额外惩罚，让它更倾向于“最短路”
  -- 不要设置 result.weight = way:get_distance()（没有这个 API）
end

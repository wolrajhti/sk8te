-- functions for jump trajectory
function yJump(x, ox, oy, a, b, sign)
  -- if DEBUG then print('yJump', x, ox, oy, a, b, sign, ' => ', oy + a * math.pow(x - ox - sign * math.sqrt(b / a), 2) - b) end
  return oy + a * math.pow(x - ox - sign * math.sqrt(b / a), 2) - b
end

function dyJump(x, ox, oy, a, b, sign)
  -- todo
end

function drawJump(ox, oy, a, b, sign)
  local pts = {ox, yJump(ox, ox, oy, a, b, sign)}
  for x = ox, ox + sign * 100, sign do
    table.insert(pts, x)
    table.insert(pts, yJump(x, ox, oy, a, b, sign))
  end
  love.graphics.line(pts)
end

-- functions for arc trajectory
function yArc(x, cx, cy, r)
  return cy + math.sqrt(math.pow(r, 2) - math.pow(math.min(x, cx + r) - cx, 2))
end

function dyArc(x, cx, cy, r)
  return 2 * x / math.sqrt(math.pow(r, 2) - math.pow(math.min(x, cx + r) - cx, 2))
end

function drawArc(cx, cy, r)
  local pts = {cx - r, yArc(cx - r, cx, cy, r)}
  for x = cx - r, cx + r, 1 do
    table.insert(pts, x)
    table.insert(pts, yArc(x, cx, cy, r))
  end
  love.graphics.line(pts)
end

function fallFromArc(x, vx, cx, cy, r)
  return (vx > 0 and x > cx + r) or (vx < 0 and  x < cx - r)
end

-- functions for line trajectory
function slope(x1, y1, x2, y2)
  if x1 ~= x2 then
    return (y2 - y1)/(x2 - x1)
  end
end

function yLine(x, a, b)
  return a * x + b
end

function dyLine(x, a, b)
  return a
end

function lineFrom2Pts(x1, y1, x2, y2)
  local a = slope(x1, y1, x2, y2)
  if a then
    return a, y1 - a * x1
  end
end

function ySeg(x, x1, y1, x2, y2)
  local a, b = lineFrom2Pts(x1, y1, x2, y2)
  return yLine(x, a, b)
end

function dySeg(x, x1, y1, x2, y2)
  local a, b = lineFrom2Pts(x1, y1, x2, y2)
  return dyLine(x, a, b)
end

function fallFromSeg(x, vx, x1, y1, x2, y2)
  return (vx > 0 and x > x2) or (vx < 0 and  x < x1)
end

-- intersection de deux droites
function interLines(x1, y1, x2, y2, x3, y3, x4, y4)
  print('----------- interLines -----------')
  print(string.format('{%d, %d} --- {%d, %d}', x1, y1, x2, y2))
  print(string.format('{%d, %d} --- {%d, %d}', x3, y3, x4, y4))
  local a1, b1 = lineFrom2Pts(x1, y1, x2, y2)
  local a2, b2 = lineFrom2Pts(x3, y3, x4, y4)
  -- print(string.format('interLines: %.2f * x + %.2f, %.2f * x + %.2f', a1, b1, a2, b2))
  -- print('verif', a1 * x1 + b1, y1)
  -- print('verif', a1 * x2 + b1, y2)
  -- print('verif', a2 * x3 + b2, y3)
  -- print('verif', a2 * x4 + b2, y4)
  if a1 and a2 and a1 ~= a2 then
    local x = (b2 - b1) / (a1 - a2)
    return x, a1 * x + b1
  elseif a1 then
    return x3, a1 * x3 + b1
  elseif a2 then
    return x1, a2 * x1 + b2
  end
end

-- test si l'intersection se trouve sur le segment
function inRange(x1, y1, x2, y2, xi, yi)
  local ax = slope(x1, x1, x2, xi)
  local ay = slope(y1, y1, y2, yi)
  if ax and ay then
    return 0 <= ax and ax < 1 and 0 <= ay and ay < 1
  elseif ax then
    return 0 <= ax and ax < 1 and yi == y1
  elseif ay then
    return xi == x1 and 0 <= ay and ay < 1
  end
end

-- intersection de deux segments
function interSegs(x1, y1, x2, y2, x3, y3, x4, y4)
  local xi, yi = interLines(x1, y1, x2, y2, x3, y3, x4, y4)
  if xi and yi then print('interLine =>', xi, yi) end
  if xi and yi and inRange(x1, y1, x2, y2, xi, yi) and inRange(x3, y3, x4, y4, xi, yi) then
    print('=> in range')
    return xi, yi
  end
end

-- produit scalaire
function dot(x1, y1, x2, y2)
  return x1 * x2 + y1 * y2
end

-- norm
function norm(x1, y1, x2, y2)
  return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
end

-- normalize
function normalize(x1, y1, norm)
  return x1 / norm, y1 / norm
end

-- at
function at(v1, v2, t)
  return v1 + t * (v2 - v1)
end

-- project
function proj(x1, y1, x2, y2, x, y)
  local n = norm(x1, y1, x2, y2)
  local xn, yn = normalize(x2 - x1, y2 - y1, n)
  local t = dot(xn, yn, normalize(x - x1, y - y1, n))
  return at(x1, x2, t), at(y1, y2, t), t
end

-- intersection d'un cercle
function interLineCircle(x1, y1, x2, y2, cx, cy, r)
  local px, py, t = proj(x1, y1, x2, y2, cx, cy)
  local n = norm(px, py, cx, cy)
  if n > r then return nil end
  local dist = (n % r) / r
  local offset = math.cos(math.asin(dist)) * r / norm(x1, y1, x2, y2)
  local xi1, yi1, xi2, yi2
  if t - offset > 0 and t - offset <= 1 then
    xi1, yi1 = at(x1, x2, t - offset), at(y1, y2, t - offset)
  end
  if t + offset > 0 and t + offset <= 1 then
    xi2, yi2 = at(x1, x2, t + offset), at(y1, y2, t + offset)
  end
  if xi1 and yi1 then
    return xi1, yi1, xi2, yi2
  else
    return xi2, yi2
  end
end
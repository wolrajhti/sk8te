function yLine(a, b, x, neg)
  return a * math.pow(x - (neg or 1) * math.sqrt(b / a), 2) - b
end

function dyLine()
end

function drawTrajectory(ox, oy, a, b, neg)
  local pts = {ox, oy}
  for x = 0, neg * 100, neg do
    table.insert(pts, ox + x)
    table.insert(pts, oy + yLine(a, b, x, neg))
  end
  love.graphics.line(pts)
end

function yArc(cx, cy, r, x)
  local y = cy + math.sqrt(math.pow(r, 2) - math.pow(x - cx, 2))
  return y
end

function dyArc(cx, cy, r, x)
  return 2 * x / math.sqrt(math.pow(r, 2) - math.pow(x - cx, 2))
end

function drawTrajectoryCircle(cx, cy, r)
  local pts = {cx - r, yArc(cx, cy, r, cx - r)}
  for x = cx - r, cx + r, 1 do
    table.insert(pts, x)
    table.insert(pts, yArc(cx, cy, r, x))
  end
  love.graphics.line(pts)
end

local ymax
local power = 0
local dp = 70000
local x, y = 100
local VX = 100
local vx, vy = VX, 0
local jump, touch = false, false
local w, h
local tr
local floors, f, fxi, fyi = {}
local olddy, dy = 0, 0
local neg = 1

-- pente de la droite
function a(x1, y1, x2, y2)
  if x1 ~= x2 then
    return (y2 - y1)/(x2 - x1)
  end
end

-- décalage à l'origine de la droite
function b(x1, y1, x2, y2, A)
  A = A or a(x1, y1, x2, y2)
  if A then
    return y1 - A * x1
  end
end

-- intersection de deux droites
function inter(x1, y1, x2, y2, x3, y3, x4, y4)
  local a1 = a(x1, y1, x2, y2)
  local b1 = b(x1, y1, x2, y2, a1)
  local a2 = a(x3, y3, x4, y4)
  local b2 = b(x3, y3, x4, y4, a2)
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
function inRange(xi, yi, x1, y1, x2, y2)
  local ax = a(x1, x1, x2, xi)
  local ay = a(y1, y1, y2, yi)
  if ax and ay then
    return 0 <= ax and ax < 1 and 0 <= ay and ay < 1
  elseif ax then
    return 0 <= ax and ax < 1 and yi == y1
  elseif ay then
    return xi == x1 and 0 <= ay and ay < 1
  end
end

-- intersection de deux segments
function interSeg(x1, y1, x2, y2, x3, y3, x4, y4)
  local xi, yi = inter(x1, y1, x2, y2, x3, y3, x4, y4)
  if xi and yi and inRange(xi, yi, x1, y1, x2, y2) and inRange(xi, yi, x3, y3, x4, y4) then
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
function interCircle(x1, y1, x2, y2, cx, cy, r)
  local px, py, t = proj(x1, y1, x2, y2, cx, cy)
  local n = norm(px, py, cx, cy)
  if n > r then return nil end
  local dist = (n % r) / r
  local offset = math.cos(math.asin(dist)) * r / norm(x1, y1, x2, y2)
  love.graphics.print(dist..', '..offset, 50, 500)
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

function love.draw()
  -- info
  love.graphics.print(string.format('x, y = %d, %d\nvx, power = %f, %d\n%d', x, y, vx, power, neg), 200, 100)
  -- position & trajectory
  if jump then
    love.graphics.circle('fill', x, y + yLine(tr[3], tr[4], x - tr[1], tr[5]), 10)
    drawTrajectory(unpack(tr))
  else
    if touch then
      drawTrajectory(x, y, math.pow(VX / vx, 2) * VX / 500, power / 100, neg)
    end
    love.graphics.circle('fill', x, y, 10)
  end
  -- floors
  for i, floor in ipairs(floors) do
    if floor.type == 'seg' then
      love.graphics.line(floor[1], floor[2], floor[3], floor[4])
    elseif floor.type == 'hp' then
      love.graphics.arc('line', floor[1], floor[2], floor[3], 0, math.pi)
    end
  end
end

function love.update(dt)
  -- trigger jump
  if touch and not jump then
     power = math.min(power + dp * dt, 40000)
     tr = {x, y, math.pow(VX / vx, 2) * VX / 500, power / 100, neg}
  end

  -- fall from floor
  if f then
     if f.type == 'seg' then
        if (vx > 0 and x > f[3]) or (vx < 0 and  x < f[1]) then
           jump, f = true, nil
           tr = {x, y, math.abs(vx) / 500, 0, neg}
        end
     elseif f.type == 'hp' then
        -- print('JUMP?')
        if (vx > 0 and x > f[1] + f[3]) or (vx < 0 and  x < f[1] - f[3]) then
          --  print('JUMP')
           jump, f = true, nil
           tr = {x, y, math.abs(vx) / 500, 0, neg}
        end
     end
  end

  -- update speed
  if f then
     if f.type == 'seg' then
        acc = 1e3 * a(f[1], f[2], f[3], f[4])
     elseif f.type == 'hp' then
        acc = 1e2 * dyArc(f[1], f[2], f[3], x)
     end
     vx = vx + acc * dt
  elseif not jump then
     vx = vx + (1--[[neg]] * VX - vx) * dt
  end
  if vx < 0 then
     neg = -1
  else
     neg = 1
  end
  -- print('speed', vx)

  -- resolve jump
  if jump then
     f = nil
     fxi, fyi = nil, nil
     power = 0
     olddy = dy
     tr[1] = tr[1] - vx * dt
     dy = yLine(tr[3], tr[4], x - tr[1], tr[5])
     -- falling
     if olddy < dy then
        -- test floor intersection
        _f, _fxi, _fyi = nil, nil, nil
        for i, floor in ipairs(floors) do
           if floor.type == 'seg' then
              _fxi, _fyi = interSeg(x, y + olddy, x + vx * dt, y + dy, floor[1], floor[2], floor[3], floor[4])
           elseif floor.type == 'hp' then
              _fxi, _fyi = interCircle(x, y + olddy, x + vx * dt, y + dy, floor[1], floor[2], floor[3])
           end
           if (_fxi and _fyi and fxi and fyi and _fxi < fxi) or (not fxi and not fyi) then
              _f, fxi, fyi = floor, _fxi, _fyi
           end
        end
        if fxi and fyi then
           y = fyi
           f = _f
           olddy, dy = 0, 0
           jump = false
        end
        --default floor
        if jump then
           if y + dy > ymax then
              y = ymax
              olddy, dy = 0, 0
              jump = false
           end
        end
     end
  end

  -- push new floors
  while #floors < 5 do
     local rx = math.random(-1 * w, 2 * w)
     local ry = math.random(50, h - 50)
     local len = math.random(0.8 * w, 2 * w)
     if math.random() > .9 then
        table.insert(floors, {
           rx, ry + math.random(-40, 40),
           rx + len, ry + math.random(-40, 40),
           type = 'seg'
        })
     else
        table.insert(floors, {
           len, ry, math.random(50, 100),
           type = 'hp'
        })
     end
  end

  -- update position
  if f then
     if f.type == 'seg' then
        y = a(f[1], f[2], f[3], f[4]) * x + b(f[1], f[2], f[3], f[4])
     elseif f.type == 'hp' then
        -- print('hp', f[1], f[2], f[3])
        y = yArc(f[1], f[2], f[3], x)
     end
     fxi = x
     fyi = y
  end

  -- update and pop old floors
  for i, floor in ipairs(floors) do
     if floor.type == 'seg' then
        floor[1] = floor[1] - vx * dt
        floor[3] = floor[3] - vx * dt
        if floor[3] < 0 then
          table.remove(floors, i)
        end
     elseif floor.type == 'hp' then
        floor[1] = floor[1] - vx * dt
        if floor[1] + floor[3] < 0 then
          table.remove(floors, i)
        end
     end
  end
end

function love.load()
  w, h = love.graphics.getDimensions()
  ymax = h - 50
  y = ymax
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit(0)
  else
    touch = true
  end
end

function love.keyreleased(key)
  touch = false
  jump = true
end
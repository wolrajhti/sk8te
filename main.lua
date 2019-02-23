class = require('middleclass.middleclass')
require 'geometry'
local Parc = require 'level'
local Skater = require 'player'
local Camera = require 'hump.camera'

-- GLOBALS
local ymax
local power = 0
local dp = 70000
local VX = 100
local p = Skater(100, 0, VX)
local jump, touch = false, false
local w, h
local tr
local floors, f, fxi, fyi = {}
local parc = Parc()
parc.floors = floors
local olddy, dy = 0, 0
local sign = 1
local camera = Camera(p.x, p.y, 0.5)
camera.smoother = Camera.smooth.damped(1)

math.randomseed(os.time())

function love.load()
  w, h = love.graphics.getDimensions()
  ymax = h - 50
  p.y = ymax
end

function love.update(dt)
  if not PAUSE then
  -- trigger jump
  if touch and not jump then
    power = math.min(power + dp * dt, 40000)
    tr = {p.x, p.y, math.pow(VX / p.vx, 2) * VX / 500, power / 100, sign}
  end

  -- fall from floor
  if f then
    if f.type == 'seg' then
      if fallFromSeg(p.x, p.vx, unpack(f)) then
        jump, f = true, nil
        tr = {p.x, p.y, math.abs(p.vx) / 500, 0, sign}
      end
    elseif f.type == 'arc' then
      if fallFromArc(p.x, p.vx, unpack(f)) then
          jump, f = true, nil
          tr = {p.x, p.y, math.abs(p.vx) / 500, 0, sign}
      end
    end
  end

  -- update speed
  print('old speed', p.vx)
  if f then
    if f.type == 'seg' then
      acc = 1e3 * dySeg(p.x, unpack(f))
    elseif f.type == 'arc' then
      acc = 1e2 * dyArc(p.x, unpack(f))
    end
    p.vx = p.vx + acc * dt
  elseif not jump then
    p.vx = p.vx + (1--[[sign]] * VX - p.vx) * dt
  end
  if p.vx < 0 then
    sign = -1
  else
    sign = 1
  end
  print('new speed', p.vx)

  -- resolve jump
  if jump then
    f, fxi, fyi = nil, nil, nil
    power = 0
    olddy = dy
    tr[1] = tr[1] - p.vx * dt
    dy = yJump(p.x, unpack(tr)) - p.y
    -- falling
    if olddy < dy then
    -- print(string.format('testing seg : {%d, %d} --- {%d, %d}', x, p.y + olddy, x + p.vx * dt, p.y + dy))
      -- test floor intersection
      _f, _fxi, _fyi = nil, nil, nil
      for i, floor in ipairs(floors) do
        if floor.type == 'seg' then
          -- print(string.format('              {%d, %d} --- {%d, %d}', unpack(floor)))
          _fxi, _fyi = interSegs(p.x, p.y + olddy, p.x + p.vx * dt, p.y + dy, floor[1], floor[2], floor[3], floor[4])
        elseif floor.type == 'arc' then
          _fxi, _fyi = interLineCircle(p.x, p.y + olddy, p.x + p.vx * dt, p.y + dy, floor[1], floor[2], floor[3])
        end
        if _fxi and _fyi and ((fxi and fyi and _fxi < fxi) or (not fxi and not fyi)) then
          print(string.format('              => %.2f, %.2f', _fxi, _fyi))
          _f, fxi, fyi = floor, _fxi, _fyi
        end
      end
      if fxi and fyi then
        p.y = fyi
        f = _f
        olddy, dy = 0, 0
        jump = false
      end
      --default floor
      if jump and p.y + dy > ymax then
        -- print('jump and p.y + dy > ymax :', p.y, '+', dy, '>', ymax)
        p.y = ymax
        olddy, dy = 0, 0
        jump = false
      end
    end
  end

  moveLevel(floors, w, h, p.vx * dt)
  movePlayer(p, f)
  end
  camera:lockPosition(p.x, p.y)
end

function love.draw()
  camera:attach()
  -- position & trajectory
  love.graphics.setColor(1, 0, 0)
  if jump then
    if olddy < dy then
      love.graphics.setColor(0, 1, 0)
    end
    love.graphics.circle('fill', p.x, yJump(p.x, unpack(tr)), 10)
    drawJump(unpack(tr))
  else
    if touch then
      drawJump(p.x, p.y, math.pow(VX / p.vx, 2) * VX / 500, power / 100, sign)
    end
    print(p.x, p.y)
    love.graphics.circle('fill', p.x, p.y, 10)
  end
  love.graphics.setColor(1, 1, 1)
  -- floors
  parc:draw()
  camera:detach()
  love.graphics.print(string.format('x, y = %d, %d\nvx, power = %f, %d\n%d', p.x, p.y, p.vx, power, sign), 200, 100)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit(0)
  elseif key == 'p' then
    PAUSE = not PAUSE
  else
    touch = true
  end
end

function love.keyreleased(key)
  touch = false
  jump = true
end
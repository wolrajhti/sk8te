class = require('middleclass.middleclass')
require 'geometry'
local Parc = require 'level'
local Skater = require 'player'
local Camera = require 'hump.camera'

-- GLOBALS
local power = 0
local dp = 70000
local VX = 100
local p = Skater(100, 0, VX)
local tr
local fxi, fyi
local parc = Parc()
local olddy, dy = 0, 0
local sign = 1
local camera = Camera(p.x, p.y, 1)
-- camera.smoother = Camera.smooth.damped(10)

math.randomseed(os.time())

function love.load()
  parc:setCamera(camera)
  p.y = parc.yMax
end

function love.update(dt)
  -- dt = .8 * dt
  -- trigger jump
  if p.isPushing and not p.isJumping then
    power = math.min(power + dp * dt, 40000)
    tr = {p.x, p.y, math.pow(VX / p.vx, 2) * VX / 500, power / 100, sign}
  end

  -- fall from floor
  if p.floor then
    if p.floor.type == 'seg' then
      if fallFromSeg(p.x, p.vx, unpack(p.floor)) then
        p.isJumping, p.floor = true, nil
        tr = {p.x, p.y, math.abs(p.vx) / 500, 0, sign}
      end
    elseif p.floor.type == 'arc' then
      if fallFromArc(p.x, p.vx, unpack(p.floor)) then
        p.isJumping, p.floor = true, nil
        tr = {p.x, p.y, math.abs(p.vx) / 500, 0, sign}
      end
    end
  end

  -- update speed
  print('old speed', p.vx)
  if p.floor then
    if p.floor.type == 'seg' then
      acc = 1e3 * dySeg(p.x, unpack(p.floor))
    elseif p.floor.type == 'arc' then
      acc = 1e1 * dyArc(p.x, unpack(p.floor))
    end
    p.vx = p.vx + acc * dt
  elseif not p.isJumping then
    p.vx = p.vx + (1--[[sign]] * VX - p.vx) * dt
  end
  if p.vx < 0 then
    sign = -1
  else
    sign = 1
  end
  print('new speed', p.vx)

  -- resolve jump
  if p.isJumping then
    p.floor, fxi, fyi = nil, nil, nil
    power = 0
    olddy = dy
    dy = yJump(p.x, unpack(tr)) - p.y
    -- falling
    if olddy < dy then
    -- print(string.format('testing seg : {%d, %d} --- {%d, %d}', x, p.y + olddy, x + p.vx * dt, p.y + dy))
      -- test floor intersection
      _f, _fxi, _fyi = nil, nil, nil
      for i, floor in ipairs(parc.floors) do
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
        p.floor = _f
        olddy, dy = 0, 0
        p.isJumping = false
      end
      --default floor
      if p.isJumping and p.y + dy > parc.yMax then
        -- print('jump and p.y + dy > parc.yMax :', p.y, '+', dy, '>', parc.yMax)
        p.y = parc.yMax
        olddy, dy = 0, 0
        p.isJumping = false
      end
    end
  end
  p:update(dt)
  parc:update()
  camera:lockPosition(p.x, p.y)
end

function love.draw()
  camera:attach()
  -- position & trajectory
  love.graphics.setColor(1, 0, 0)
  if p.isJumping then
    if olddy < dy then
      love.graphics.setColor(0, 1, 0)
    end
    love.graphics.circle('fill', p.x, yJump(p.x, unpack(tr)), 10)
    drawJump(unpack(tr))
  else
    if p.isPushing then
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
  local p, q = love.graphics.getDimensions()
  love.graphics.line(p / 2, 0, p / 2, q)
end

function love.keypressed(key)
  if key == 'escape' then
    love.event.quit(0)
  elseif key == 'p' then
    PAUSE = not PAUSE
  else
    p:push()
  end
end

function love.keyreleased(key)
  p:jump()
end
local Parc = class('Parc')

function Parc:initialize(yMax)
  self.floors = {}
  self.yMax = yMax or love.graphics.getHeight() - 50
end

function Parc:setCamera(camera)
  self.camera = camera
end

function Parc:draw()
  for i, f in ipairs(self.floors) do
    if f.type == 'seg' then
      love.graphics.line(f[1], f[2], f[3], f[4])
    elseif f.type == 'arc' then
      love.graphics.arc('line', f[1], f[2], f[3], 0, math.pi)
    end
  end
end

function Parc:update()
  local w, h = love.graphics.getDimensions()
  local x1, y1 = self.camera:worldCoords(0, 0, 0, 0, w, h)
  local x2, y2 = self.camera:worldCoords(w, h, 0, 0, w, h)
  -- push new floors
  local i, floor = 1, nil
  while i < 10 do
    floor = self.floors[i]
    if not floor then
      local rx = math.random(-1 * w, 2 * w)
      local ry = math.random(50, h - 50)
      local len = math.random(0.8 * w, 2 * w)
      if math.random() > .5 then
        local a, b = self.camera:worldCoords(rx, ry, 0, 0, w, h)
        local c, d = self.camera:worldCoords(rx + len, ry + math.random(-40, 40), 0, 0, w, h)
        table.insert(self.floors, {
          a, b, c, d,
          type = 'seg'
        })
      else
        local a, b = self.camera:worldCoords(len, ry, 0, 0, w, h)
        table.insert(self.floors, {
          a, b, math.random(50, 100),
          type = 'arc'
        })
      end
      i = i + 1
    elseif floor.type == 'seg' and (floor[1] > x2 or floor[3] < x1) then
      table.remove(self.floors, i)
    elseif floor.type == 'arc' and (floor[1] + floor[3] < x1) then
      table.remove(self.floors, i)
    else
      i = i + 1
    end
  end
end

return Parc
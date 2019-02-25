local Parc = class('Parc')

function Parc:initialize()
  self.floors = {}
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

function moveLevel(floors, w, h, camera)
  local x1, y1 = camera:worldCoords(0, 0, 0, 0, w, h)
  local x2, y2 = camera:worldCoords(w, h, 0, 0, w, h)
  -- push new floors
  local i, floor = 1, nil
  while i < 10 do
    floor = floors[i]
    if not floor then
      local rx = math.random(-1 * w, 2 * w)
      local ry = math.random(50, h - 50)
      local len = math.random(0.8 * w, 2 * w)
      if math.random() > .5 then
        local a, b = camera:worldCoords(rx, ry, 0, 0, w, h)
        local c, d = camera:worldCoords(rx + len, ry + math.random(-40, 40), 0, 0, w, h)
        table.insert(floors, {
          a, b, c, d,
          type = 'seg'
        })
      else
        local a, b = camera:worldCoords(len, ry, 0, 0, w, h)
        table.insert(floors, {
          a, b, math.random(50, 100),
          type = 'arc'
        })
      end
      i = i + 1
    elseif floor[1] > x2 or floor[3] < x1 then
      table.remove(floors, i)
    else
      i = i + 1
    end
  end
end

return Parc
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

function moveLevel(floors, w, h, dx)
  -- push new floors
  while #floors < 5 do
    local rx = math.random(-1 * w, 2 * w)
    local ry = math.random(50, h - 50)
    local len = math.random(0.8 * w, 2 * w)
    if math.random() > .5 then
      table.insert(floors, {
        rx, ry,
        rx + len, ry + math.random(-40, 40),
        type = 'seg'
      })
    else
      table.insert(floors, {
        len, ry, math.random(50, 100),
        type = 'arc'
      })
    end
  end

  -- update and pop old floors
  for i, floor in ipairs(floors) do
    if floor.type == 'seg' then
      floor[1] = floor[1] - dx
      floor[3] = floor[3] - dx
      if floor[3] < 0 then
        table.remove(floors, i)
      end
    elseif floor.type == 'arc' then
      floor[1] = floor[1] - dx
      if floor[1] + floor[3] < 0 then
        table.remove(floors, i)
      end
    end
  end
end

return Parc
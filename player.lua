local Skater = class('Skater')

function Skater:initialize(x, y, vx, vy)
  self.x, self.y = x, y
  self.vx, self.vy = vx, vy
end

function movePlayer(p, f)
  -- update position
  if f then
    if f.type == 'seg' then
      print('old y', p.y)
      p.y = ySeg(p.x, unpack(f))
      print('new y', p.y)
    elseif f.type == 'arc' then
      p.y = yArc(p.x, unpack(f))
    end
  end
end

return Skater
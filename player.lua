local Skater = class('Skater')

function Skater:initialize(x, y, vx, vy)
  self.x, self.y = x, y
  self.vx, self.vy = vx, vy
  self.isPushing, self.isJumping = false, false
end

function Skater:push()
  self.isPushing, self.isJumping = true, false
end

function Skater:jump()
  self.isPushing, self.isJumping = false, true
end

function Skater:update(dt)
  self.x = self.x + self.vx * dt
  -- update position
  if self.floor then
    if self.floor.type == 'seg' then
      self.y = ySeg(self.x, unpack(self.floor))
    elseif self.floor.type == 'arc' then
      self.y = yArc(self.x, unpack(self.floor))
    end
  end
end

return Skater
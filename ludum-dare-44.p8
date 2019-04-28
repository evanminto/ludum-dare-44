pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- class.lua
-- compatible with lua 5.1 (not 5.0).
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end




vector = class(function(v, x, y)
  v.x = x or 0
  v.y = y or 0
end)

function vector:add(v)
  return vector(self.x + v.x, self.y + v.y)
end

function vector:multiply(scalar)
  return vector(self.x * scalar, self.y * scalar)
end

function vector:get_diff(v)
  return vector(abs(v.x - self.x), abs(v.y - self.y))
end

function vector:clone()
  return vector(self.x,self.y)
end

function intersect(min1, max1, min2, max2)
  return max(min1,max1) > min(min2,max2) and
         min(min1,max1) < max(min2,max2)
end

sprite = class(function(s,name)
  if name == "player" then
    s.x = 0
    s.y = 20
    s.w = 8
    s.h = 12
  end
end)

function sprite:draw(x,y,flipx)
  sspr(self.x,self.y,self.w,self.h,x,y, self.w,self.h, flipx)
end

player = class(function(p)
  p.pos = vector(0,0)
  p.vel = vector()
  p.d = vector()
  p.height = 12
  p.width = 8
  p.gravity = 0.4
  p.onplatform = false
  p.movingl = false
  p.movingr = false
  p.holdingjumpbutton = false
  p.jumpblocked = false

  p.facingleft = false

  p.xmin = 0
  p.xmax = 1024
  p.ymin = -10000
  p.ymax = 10000

  p.health = 100
  p.time = 100

  for i=1,128 do
    for j=1,128 do
      if fget(mget(i,j), flags.playerspawn) then
        p.pos = vector(i*8, j*8 + 8 - p.height)
      end
    end
  end

  p.spawnpos = p.pos:clone()
  p.checkpointpos = p.pos:clone()

  p.sprite = sprites.player
end)

function player:tick()
  self.time -= 1
  self:checkhealthtime()
end

function player:hurt()
  self.health -= 25
  self:checkhealthtime()
end

function player:checkhealthtime()
  if self.health <= 0 then
    self:die()
  end

  if self.time <= 0 then
    self:outoftime()
  end
end

function player:respawn()
  self.pos = self.spawnpos:clone()
  self.health = 100
  self.time = 100
  self.facingleft = false
end

function player:die()
  self:respawn()
end

function player:outoftime()
  self:respawn()
end

function player:fall()
  self.pos = self.checkpointpos:clone()
  self:hurt()
  self.facingleft = false
end

function player:time2health()
  self.time -= 5
  self.health += 5
  self:checkhealthtime()
end

function player:health2time()
  self.health -= 5
  self.time += 5
  self:checkhealthtime()
end

function player:preupdate()
  self.d = vector()
  self.xmin = 0
  self.xmax = 1024
  self.ymin = -10000
  self.ymax = 10000

  if btn(0) and btn(1) then
    if self.movingl then
      self.d.x += 2
      self.facingleft = false
    elseif self.movingr then
      self.d.x -= 2
      self.facingleft = true
    end
  elseif btn(0) then
    self.d.x -= 2
    self.movingl = true
    self.movingr = false
    self.facingleft = true
  elseif btn(1) then
    self.d.x += 2
    self.movingl = false
    self.movingr = true
    self.facingleft = false
  end

  if btn(2) then
    self.holdingjumpbutton = true
  else
    self.holdingjumpbutton = false

    -- Velocity threshhold for late jumping
    if not self.jumpblocked and self.vel.y > 0.75 then
      self.jumpblocked = true
    end
  end

  if btn(4) then
    self:time2health()
  elseif btn(5) then
    self:health2time()
  end

  if self.holdingjumpbutton and not self.jumpblocked then
    self.d.y -= 4.5
  end

  self.vel.y += self.gravity
  self.d = self.d:add(self.vel)
end

function player:updatex()
  self.pos.x += self.d.x
  self.pos.x = mid(self.xmin, self.pos.x, self.xmax)
  self.d.x = 0
end

function player:updatey()
  if self.onplatform then
    self.vel.y = min(self.vel.y, 0)

    if self.holdingjumpbutton then
      self.jumpblocked = true
    end

    if self.jumpblocked and not self.holdingjumpbutton then
      self.jumpblocked = false
    end
  end

  self.pos.y += self.d.y
  self.pos.y = mid(self.ymin, self.pos.y, self.ymax)
  self.d.y = 0
end

function player:postupdate()
  local tiles = self:gettiles(false, false)

  foreach(tiles, function(t)
    if fget(mget(t[1],t[2]), flags.checkpoint) then
      self.checkpointpos = self.pos:clone()
    end
  end)

  if self.pos.y > 128 then
    self:fall()
  end

  if frame % 30 == 0 then
    self:tick()
  end
end

function player:draw()
  local s = sprite("player")

  s:draw(self.pos.x,self.pos.y, self.facingleft)
end

function player:gettiles(x,y)
  local d = vector()
  if x then d.x = self.d.x end
  if y then d.y = self.d.y end

  local top = flr((self.pos.y + d.y) / 8)
  local left = flr((self.pos.x + d.x) / 8)
  local bottom = flr((self.pos.y + self.height - 0.001 + d.y) / 8)
  local right = flr((self.pos.x + self.width - 0.001 + d.x) / 8)

  local vmid = nil
  local hmid = nil

  if bottom - top > 1 then
    vmid = bottom - 1
  end
  if right - left > 1 then
    vmid = right - 1
  end

  local tiles = {}
  tiles.bottom = {}

  add(tiles,{left,top})
  if hmid ~= nil then add(tiles,{hmid,top}) end
  add(tiles,{right,top})
  if vmid ~= nil then
    add(tiles,{left,vmid})
    if hmid ~= nil then add(tiles,{hmid,vmid}) end
    add(tiles,{right,vmid})
  end
  add(tiles,{left,bottom})
  if hmid ~= nil then add(tiles,{hmid,bottom}) end
  add(tiles,{right,bottom})

  return tiles
end

level = class(function(l)
  l.player = player()
  l.width = 1024
end)

function level:update()
  self.player.onplatform = false
  self.player:preupdate()

  local xtiles = self.player:gettiles(true, false)

  local xmax = self.player.xmax
  local xmin = self.player.xmin
  foreach(xtiles, function(t)
    if fget(mget(t[1],t[2]), flags.obstacle) then
      if self.player.d.x > 0 then
        xmax = min(xmax, t[1] * 8 - self.player.width)
      end
      if self.player.d.x < 0 then
        xmin = max(xmin, t[1] * 8 + self.player.width)
      end
    end
  end)
  self.player.xmax = xmax
  self.player.xmin = xmin

  self.player:updatex()

  local ytiles = self.player:gettiles(false, true)

  local ymax = self.player.ymax
  foreach(ytiles, function(t)
    if fget(mget(t[1],t[2]), flags.obstacle) then
      if self.player.d.y > 0 then
        self.player.onplatform = true
        ymax = min(ymax, t[2] * 8 - self.player.height)
      end
    end
  end)
  self.player.ymax = ymax

  self.player:updatey()
  self.player:postupdate()
end

function level:draw()
  local camerax = self.player.pos.x - 64 + 4
  local cameray = self.player.pos.y - 64 + 4

  camera(0, 0)
  map(0, 16, 0, 0, 32, 32)

  local clampedcamerax = mid(0, camerax, self.width - 128)
  local clampedcameray = mid(0, cameray, 128 - 128)

  camera(clampedcamerax, clampedcameray)

  map(0,0,0,0,128,32,2)
  self.player:draw()

  camera()
  print('health: ' .. self.player.health, 4,4, 1)
  print('time: ' .. self.player.time, 92,4, 1)
end

function _init()
  printh("\n\n\n")
end

function _update()
  frame += 1

  levels[1]:update()
end

function _draw()
  levels[1]:draw()
end

frame = 0

sprites = {
  player = 0,
  roof = 23,
}

flags = {
  obstacle = 1,
  checkpoint = 2,
  playerspawn = 3,
}

levels = {
  level()
}

__gfx__
07777770000000002222222200000000000000000000000074440404444444444040744400000000000000008444484444844448000000000000000000000000
77000077088088002222222200000000000000000000000046664646664664666464666400000000000000004666646666466664000000000000000000000000
70000007888888802222222200000000000000000000000004664646664664666464664000000000000000004666646666466664000000000000000000000000
7bbbbbb7888888802222222200000000000000000000000000444444444664444444440000000000000000004666646666466664000000000000000000000000
7bbbbbb7888888802222222200000000000000000000000000446666664664666666640000000000000000008444484444844448000000000000000000000000
7bbbbbb708888800222222220000000000000000000000000004444444466444444440000000000000000000400cccccccccccc4000000000000000000000000
7bbbbbb70088800022222222000000000000000000000000000046666664466666640000000000000000000040c7ccccccc7ccc4000000000000000000000000
77777777000800002222222200000000000000000000000000000444444444444440000000000000000000004c7ccccccc7cccc4000000000000000000000000
00000000000000000000000000000000000000000000000000004788888848888884000005555550000000004ccccccccccc7cc4000000000000000000000000
00000000000000000000000000000000000000000000000000004888888848888884000055000055000000004cccccccccc7ccc4000000000000000000000000
00000000000000000000000000000000000000000000000000000444444444444440000050500005000000004ccccccccc7cccc4000000000000000000000000
00000000000000000000000000000000000000000000000000004784788888847884000050550005000000004cccccccc7ccccc4000000000000000000000000
00000000000000000000000000000000000000000000000000004884888888848884000050005505000000004cccc7cc7cccccc4000000000000000000000000
00000000000000000000000000000000000000000000000000004884888888848884000050000505000000004ccc7cccccccccc4000000000000000000000000
00000000000000000000000000000000000000000000000000000444444444444440000055000055000000004cccccccccccccc4000000000000000000000000
00000000000000000000000000000000000000000000000000004888888847888884000055555555000000004cccccccccccccc4000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004cccccccc7ccccc4000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004ccccccc7c0cccc4000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004cccccc7000cccc4000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000004ccccc7ccc0ccc04000000000000000000000000
600ff000600ff0000600000000000000000000000000000000000000000000000000000000000000000000004cccc7ccccc0c00400000000000000000a0d8d00
000ff000000ff000000ff00000000000000000000000000000000000000000000000000000000000000000004ccc7ccccccc00040000000000000000000dd000
60cccc0060cccc0060cffc0000000000000000000000000000000000000000000000000000000000000000004cc7cccccc00000400000000000000000a66a600
66c6666666c6666666c666660000000000000000000000000000000000000000000000000000000000000000444444444444444400000000000000000606a600
6cc60cc06cc60cc06cc60cc00000000000000000000000000000000000000000078800080000000000000000000000000000000000000000000000000606a600
6ccccc006ccccc006ccccc000000000000000000000000000000000000000000078878780000000000000000000000000000000000000000000000000d06a600
0999990009999900099999000000000000000000000000000000000000000000078887880000000000000000000000000000000000000000000000000066a600
0ccccc000ccccc000ccccc000000000000000000000000000000000000000000078878780000000000000000000000000000000000000000000000000666a600
0c000c000c00090009000c0000000000000000000000000000000000000000000700888000000000000000000000000000000000000000000000000006000600
0c000c000c00099009900c0000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000006000600
0900090009000000000009000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000d000d00
0990099009900000000009900000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000dd00dd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000
__gff__
0000000000000202020000020200000000000000000002020200000202000000000000000000000000000002020000000000000000000000040800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0707070f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f390f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070707080f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f380f0f0f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171717180f0f0f0f0f0f0f0f0f0f0f0f0f0f060707070707070707080f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c1717180f0f0f0f0f0f0f0f0f0f380f0f0f161717171717171717180f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1717180f0f0f0f06070707070707080f0f160b0c170b0c170b0c180f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1717180f0f0f0f16171717171717180f0f161b1c171b1c171b1c180f0f0f1717170f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

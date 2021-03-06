pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

flags = {
  drawable = 0,
  obstacle = 1,
  checkpoint = 2,
  playerspawn = 3,
  win = 4,
  enemy = 5,
  powerup = 6,
}

sprites = {
  player = 0,
  roof = 23,
  teleporter = 77,
}

sound = {
  jump = 0,
  time2health = 1,
  health2time = 2,
  damage = 3,
  powerup = 4,
}

config = {
  -- amount the player moves left/right every frame
  movespeed = 2.5,
  slowmovespeed = 0.75,

  -- vertical speed applied while jumping (dampened by gravity)
  jumpspeed = 3.75,
  -- gravitational acceleration
  gravity = 0.55,
  -- max frames that player can hold a jump
  maxjumpframes = 30,
  -- suppresses gravity while holding a jump. 0 doesn't suppress, 1 completely suppresses
  ascentcontrol = 0.7,
  -- lets the player jump if they were on a platform within the past n frames
  latejumpframes = 1,

  layers = {
    {
      start = {112,16},
      size = {16,31},
      camerafollow = 0,
      transparent = 11,
      repeatx = 1,
    },
    {
      start = {0,16},
      size = {74,16},
      camerafollow = 0.125,
      transparent = {2,5},
      repeatx = 2,
    },
    {
      start = {0,16},
      size = {74,16},
      camerafollow = 0.25,
      transparent = {2,7,14},
      repeatx = 2,
    },
    {
      level = true,
      size = {128,16},
      camerafollow = 1,
      flags = {
        flags.drawable
      },
      transparent = 0,
      enemies = true,
    }
  },

  levelsections = {
    {
      start = {0,0},
    },
    {
      start = {0,32},
    },
    {
      start = {0,48},
    },
  },

  -- player animation
  playeranimrate = 4,

  -- player health
  maxhealth = 58,
  starthealth = 29,
  falldmgamount = 7,
  atkdmgamount = 8,
  hitstuntime = 30,
  fallimmobile = 15,
  hitstunflashframerate = 2,
  respawnframes = 30,

  -- powerup
  poweruphealth = 15,
  poweruptime = 15,
  powerupflashframes = 4,

  -- player time
  maxtime = 58,
  starttime = 29,
  tickframes = 60,
  tickamount = 0.05,
  tickevent = 'move',

  -- amount lost/gained each time you convert between health/time
  conversionhealth = 2,
  conversiontime = 2,

  -- enemies
  enemyspeed = 0.75,
  -- allow the player to visually collide without getting hurt
  enemyhitboxinset = {3,2},
  enemyanimrate = 8,

  -- ui
  healthtext = 'HEALTH',
  timetext = 'BATTERY',
  healthconverttext = 'Z',
  timeconverttext = 'X',

  epiloguelocktimer = 120,
}

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

function intersect(min1, max1, min2, max2)
  return max(min1,max1) > min(min2,max2) and
         min(min1,max1) < max(min2,max2)
end

hitbox = class(function(hb, x, y, w, h)
  hb.x = x
  hb.y = y
  hb.w = w
  hb.h = h
end)

function hitbox:getx1()
  return self.x + self.w
end

function hitbox:gety1()
  return self.y + self.h
end

function hitbox:iscolliding(other)
  return intersect(self.x, self.x + self.w, other.x, other.x + other.w) and
         intersect(self.y, self.y + self.h, other.y, other.y + other.h)
end

function animateoptions(numoptions, rate, f)
  f = f or frame
  return flr(f / rate) % numoptions
end

animation = class(function(a, frames, rate)
  a.frames = frames
  a.rate = rate or 2

  a.playing = true
end)

function animation:draw(x, y, flipx)
  local i = 0

  if self.playing then
    i = animateoptions(#self.frames, self.rate)
  end

  local frame = self.frames[i + 1]
  frame:draw(x,y,flipx)
end

function animation:start()
  self.playing = true
end

function animation:stop()
  self.playing = false
end

sprite = class(function(s,name)
  if name == "player" then
    s.x = 0
    s.y = 20
    s.w = 8
    s.h = 12
  elseif name == "player2" then
    s.x = 8
    s.y = 20
    s.w = 8
    s.h = 12
  elseif name == "player3" then
    s.x = 16
    s.y = 20
    s.w = 8
    s.h = 12
  elseif name == "enemy" then
    s.x = 120
    s.y = 20
    s.w = 8
    s.h = 12
  elseif name == "enemy2" then
    s.x = 112
    s.y = 20
    s.w = 8
    s.h = 12
  elseif name == 'powerup' then
    s.x = 72
    s.y = 16
    s.w = 8
    s.h = 8
  elseif name == 'teleporter' then
    s.x = 104
    s.y = 32
    s.w = 8
    s.h = 8
  end
end)

function sprite:draw(x,y,flipx, sizex,sizey)
  local w = self.w
  local h = self.h

  if sizex then
    x += (w - sizex) / 2
    w = sizex
  end

  if sizey then
    y += h - sizey
    h = sizey
  end

  sspr(self.x,self.y,self.w,self.h, x,y, w,h, flipx)
end

player = class(function(p)
  p.pos = vector(0,0)
  p.vel = vector()
  p.d = vector()
  p.height = 12
  p.width = 8
  p.lastonplatform = nil
  p.onplatform = false
  p.movingl = false
  p.movingr = false

  p.jumptimer = 0
  p.holdingjumpbutton = false
  p.jumpblocked = false

  p.health2timesfxplayed = false
  p.time2healthsfxplayed = false

  p.facingleft = false

  p.xmin = 0
  p.xmax = 1024
  p.ymin = -10000
  p.ymax = 10000

  p.health = config.starthealth
  p.time = config.starttime

  p.won = false

  p.hitstuntimer = 0
  p.respawntimer = 0
  p.fallimmobiletimer = 0

  p.poweringup = false
  p.poweringuptimer = 0

  p.pos = p:getspawnpos()

  p.spawnpos = p.pos:clone()
  p.checkpointpos = p.pos:clone()

  p.standingsprite = sprite("player")
  p.walkinganimation = animation({
    sprite("player2"),
    sprite("player3"),
  }, config.playeranimrate)

  p.sprite = p.standingsprite
end)

function player:getspawnpos()
  for i=0,127 do
    for j=0,127 do
      if fget(mget(i,j), flags.playerspawn) then
        local t = maptiletoleveltile(i,j)
        return vector(t[1]*8, t[2]*8 + 8 - self.height)
      end
    end
  end

  return vector(0,0)
end

function player:init()
  self.xmax = levels[1].width
  self.respawntimer = config.respawnframes
end

function player:gethitbox()
  return hitbox(
    self.pos.x,
    self.pos.y + 2,
    6,
    12
  )
end

function player:win()
  self.won = true
  levels[1]:stop()
  epiloguelocktimer = config.epiloguelocktimer
end

function player:tick()
  self.time -= config.tickamount
  self:checkhealthtime()
end

function player:hurt(amount)
  self.health -= amount
  self:checkhealthtime()
  sfx(sound.damage)
end

function player:starthitstun()
  if self.hitstuntimer == 0 then
    self.hitstuntimer = config.hitstuntime
  end
end

function player:attacked()
  if self.hitstuntimer == 0 then
    self:hurt(config.atkdmgamount)
  end
  self:starthitstun()
end

function player:powerup()
  self.health += config.poweruphealth
  self.time += config.poweruptime
  self:checkhealthtime()
  sfx(sound.powerup)
  self.poweringup = true
  self.poweringuptimer = config.powerupflashframes
end

function player:checkhealthtime()
  if self.health <= 0 then
    self:die()
  end

  if self.time <= 0 then
    self.time = 0
  end

  if self.health > config.maxhealth then
    self.health = config.maxhealth
  end
  if self.time > config.maxtime then
    self.time = config.maxtime
  end
end

function player:respawn()
  self.pos = self.spawnpos:clone()
  self.checkpointpos = self.spawnpos:clone()
  self.health = config.starthealth
  self.time = config.starttime
  self.facingleft = false

  self.won = false
  self.hitstuntimer = 0
  self.respawntimer = config.respawnframes
  self.fallimmobiletimer = 0

  levels[1]:resetpowerups()
end

function player:die()
  self:respawn()
end

function player:outoftime()
  self:respawn()
end

function player:fall()
  self:starthitstun()
  self.pos = self.checkpointpos:clone()
  self:hurt(config.falldmgamount)
  self.facingleft = false
  self.fallimmobiletimer = config.fallimmobile
end

function player:time2health()
  local success = false
  if self.health + config.conversionhealth <= config.maxhealth and self.time -
  config.conversiontime > 0 then
    self.time -= config.conversiontime
    self.health += config.conversionhealth
    success = true
  end
  self:checkhealthtime()

  return success
end

function player:health2time()
  local success = false
  if self.time + config.conversiontime <= config.maxtime and self.health -
  config.conversionhealth > 0 then
    self.health -= config.conversionhealth
    self.time += config.conversiontime
    success = true
  end
  self:checkhealthtime()

  return success
end

function player:canmove()
  return self.respawntimer == 0 and self.fallimmobiletimer == 0
end

function player:getmovespeed()
  if self.time > 0 then
    return config.movespeed
  else
    return config.slowmovespeed
  end
end

function player:preupdate()
  self.d = vector()
  self.xmin = 0
  self.xmax = levels[1].width
  self.ymin = -10000
  self.ymax = 10000

  if self.poweringuptimer > 0 then
    self.poweringuptimer -= 1

    if self.poweringuptimer <= 0 then
      self.poweringup = false
    end
  end

  local gravity = config.gravity

  if self:canmove() and btn(0) and btn(1) then
    if self.movingl then
      self.d.x += self:getmovespeed()
      self.facingleft = false
    elseif self.movingr then
      self.d.x -= self:getmovespeed()
      self.facingleft = true
    end
  elseif self:canmove() and btn(0) then
    self.d.x -= self:getmovespeed()
    self.movingl = true
    self.movingr = false
    self.facingleft = true
  elseif self:canmove() and btn(1) then
    self.d.x += self:getmovespeed()
    self.movingl = false
    self.movingr = true
    self.facingleft = false
  else
    self.movingr = false
    self.movingl = false
  end

  if self:canmove() and (btn(0) or btn(1)) then
    if config.tickevent == 'move' then
      self:tick()
    end
  end

  if (self.movingl or self.movingr) and self.onplatform then
    self.sprite = self.walkinganimation
  else
    self.sprite = self.standingsprite
  end

  if self:canmove() and btn(2) then
    if (self.onplatform or (self.lastonplatform ~= nil and frame - self.lastonplatform <= config.latejumpframes)) and not self.jumpblocked then
      self.vel.y -= config.jumpspeed
      self.jumptimer = config.maxjumpframes
      sfx(sound.jump)
    end

    if self.jumptimer > 0 then
      gravity = config.gravity * ((1 - config.ascentcontrol) + config.ascentcontrol * (1 - self.jumptimer / config.maxjumpframes))
      self.jumptimer -= 1
      self.sprite = sprite('player2')
    end

    if config.tickevent == 'move' then
      self:tick()
    end

    self.jumpblocked = true
  else
    self.jumpblocked = false

    if not self.onplatform then
      self.sprite = sprite('player3')
    end
  end

  self.convertingtime2health = false
  self.convertinghealth2time = false

  if btn(4) then
    if not btn(5) then
      if self:canmove() then
        local success = self:time2health()
        if success then self.convertingtime2health = true end
        if success and not self.time2healthsfxplayed then
          sfx(sound.time2health)
          self.time2healthsfxplayed = true
        end
      end
    end
  else
      self.time2healthsfxplayed = false
  end

  if btn(5) then
    if not btn(4) then
      if self:canmove() then
        local success = self:health2time()
        if success then self.convertinghealth2time = true end
        if success and not self.health2timesfxplayed then
          sfx(sound.health2time)
          self.health2timesfxplayed = true
        end
      end
    end
  else
      self.health2timesfxplayed = false
  end

  if self.hitstuntimer > 0 then
    self.hitstuntimer -= 1
  end

  if self.respawntimer > 0 then
    self.respawntimer -= 1
  end

  if self.fallimmobiletimer > 0 then
    self.fallimmobiletimer -= 1
  end

  self.vel.y += gravity
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

  foreach(tiles, function(t)
    if fget(mget(t[1],t[2]), flags.win) then
      self:win()
    end
  end)

  if self.pos.y > 128 then
    self:fall()
  end

  if config.tickevent == 'time' and frame % config.tickframes == 0 then
    self:tick()
  end
end

function player:draw()
  if self.respawntimer > 0 then
    local option = animateoptions(5, 3, config.respawnframes - self.respawntimer)

    if self.respawntimer < config.respawnframes / 2 then
      local frame = config.respawnframes/2 - self.respawntimer

      if self.respawntimer < config.respawnframes / 4 then
        self.sprite:draw(self.pos.x,self.pos.y, self.facingleft, self.width * 2,
        self.height/2)
      else
        self.sprite:draw(self.pos.x,self.pos.y, self.facingleft, self.width/2,
        self.height * 1.5)
      end
    end

    if option == 0 then
      sprite('teleporter'):draw(self.pos.x+self.width/2,self.pos.y + 4)
      sprite('teleporter'):draw(self.pos.x-self.width/2,self.pos.y + 4)
    elseif option == 1 then
      sprite('teleporter'):draw(self.pos.x+self.width/2,self.pos.y + 4 - 3)
      sprite('teleporter'):draw(self.pos.x-self.width/2,self.pos.y + 4 - 3)
    elseif option == 2 then
      sprite('teleporter'):draw(self.pos.x+self.width/2,self.pos.y + 4 - 6)
      sprite('teleporter'):draw(self.pos.x-self.width/2,self.pos.y + 4 - 6)
    elseif option == 3 then
      sprite('teleporter'):draw(self.pos.x+self.width/2,self.pos.y + 4 - 9)
      sprite('teleporter'):draw(self.pos.x-self.width/2,self.pos.y + 4 - 9)
    elseif option == 4 then
      sprite('teleporter'):draw(self.pos.x+self.width/2,self.pos.y + 4 - 12)
      sprite('teleporter'):draw(self.pos.x-self.width/2,self.pos.y + 4 - 12)
    end
  elseif self.hitstuntimer <= 0 or animateoptions(2, config.hitstunflashframerate) == 0 then
    self.sprite:draw(self.pos.x,self.pos.y, self.facingleft)
  end
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

  -- don't detect collisions above the top of the screen
  if top < 0 then top = nil end
  if bottom < 0 then bottom = nil end

  if top ~= nil and bottom ~= nil and bottom - top > 1 then
    vmid = bottom - 1
  end
  if right - left > 1 then
    hmid = right - 1
  end

  local tiles = {}

  if top ~= nil then
    add(tiles,{left,top})
    if hmid ~= nil then add(tiles,{hmid,top}) end
    add(tiles,{right,top})
  end
  if vmid ~= nil then
    add(tiles,{left,vmid})
    if hmid ~= nil then add(tiles,{hmid,vmid}) end
    add(tiles,{right,vmid})
  end
  if bottom ~= nil then
    add(tiles,{left,bottom})
    if hmid ~= nil then add(tiles,{hmid,bottom}) end
    add(tiles,{right,bottom})
  end

  local newtiles = {}

  foreach(tiles, function(t)
    local newt = leveltiletomaptile(t[1],t[2])
    add(newtiles,newt)
  end)

  return newtiles
end

statbar = class(function(b, x, y, w, p)
  b.x = x
  b.y = y
  b.w = w
  b.p = p
end)

function statbar:draw()
  local width = self.w
  local statwidth = (self.w - 2) / 2

  sspr(120,32, 1,8, self.x,self.y)

  local j = 0

  local emptyhealth = (1 - self.p.health / config.maxhealth) * statwidth
  local nonemptytime = 59 + (self.p.time / config.maxtime) * statwidth

  for i=1,width do
    if i > width / 2 then
      pal(8,1)
      pal(14,12)
    end

    if i < emptyhealth then
      pal(8,5)
      pal(14,5)
    end

    if i > nonemptytime then
      pal(8,5)
      pal(14,5)
    end

    if levels[1].player.poweringup then
      pal()
      pal(8,7)
      pal(14,7)
    end

    sspr(120 + 1,32, 1,8, self.x+i,self.y)
    pal()
    j = i
  end

  sspr(120 + 7,32, 1,8, self.x+j+1,self.y)

  pal()
  if levels[1].player.convertinghealth2time then
    pal(8,1)
  elseif levels[1].player.convertingtime2health then
    pal(1,8)
  end
  spr(78, self.x + self.w / 2 - 3,self.y+8)
  pal()

  local healthconvertcolor = 14
  local healthtextcolor = 7
  if levels[1].player.convertinghealth2time then
    healthconvertcolor = 5
    healthtextcolor = 6
  end
  local timeconvertcolor = 12
  local timetextcolor = 7
  if levels[1].player.convertingtime2health then
    timeconvertcolor = 5
    timetextcolor = 6
  end

  print(config.healthtext, self.x + 3, self.y + 1, healthtextcolor)
  local text = config.timetext
  print(text, self.x + self.w - #text*4, self.y + 1, timetextcolor)


  print(config.healthconverttext, self.x + self.w / 2 -
  #config.healthconverttext*4 - 4, self.y + 8, healthconvertcolor)
  print(config.timeconverttext, self.x + self.w / 2 +
  #config.timeconverttext*4 + 3, self.y + 8, timeconvertcolor)
end

function leveltiletomaptile(x,y)
  local offset = ceil(x / 128)

  -- what the fuck? whatever, hacking this in for now.
  if x > 126 and x < 130 then
    offset = ceil(x / 127)
  end

  if config.levelsections[offset] then
    y += config.levelsections[offset].start[2]
    x = x % 128
  end

  return {x,y}
end

function maptiletoleveltile(x,y)
  local sectionindex = 0
  foreach(config.levelsections, function(s)
    if x >= s.start[1] and x < s.start[1] + 128 and y >= s.start[2] and y <
    s.start[2] + 16 then
      x += sectionindex * 128
      y -= s.start[2]
    end
    sectionindex += 1
  end)

  return {x,y}
end

function isobstacle(x, y)
  local xcell = flr(x / 8)
  local ycell = flr(y / 8)
  local newcell = leveltiletomaptile(xcell, ycell)
  return fget(mget(newcell[1],newcell[2]), flags.obstacle)
end

enemy = class(function(e, x, y)
  e.pos = vector(x, y)

  e.height = 12
  e.width = 8
  e.movingr = true
  e.movingl = false

  e.sprite = animation({
    sprite('enemy'),
    sprite('enemy2'),
  }, config.enemyanimrate)
end)

function enemy:gethitbox()
  return hitbox(
    self.pos.x + config.enemyhitboxinset[1],
    self.pos.y + config.enemyhitboxinset[2],
    8 - config.enemyhitboxinset[1],
    12 - config.enemyhitboxinset[2]
  )
end

function enemy:update()
  local newpos = self.pos

  if self.movingr then
    newpos = self.pos:add(vector(config.enemyspeed, 0))

    -- todo: fix weird math here
    if not isobstacle(newpos.x + self.width - 2, newpos.y + self.height + 1) or
    isobstacle(newpos.x + self.width - 3, newpos.y + self.height - 1) then
      self.movingr = false
      self.movingl = true
      newpos = self.pos:add(vector(-config.enemyspeed, 0))
    end
  elseif self.movingl then
    newpos = self.pos:add(vector(-config.enemyspeed, 0))

    -- todo: fix weird math here
    if not isobstacle(newpos.x - 1 + 2, newpos.y + self.height + 1) or
    isobstacle(newpos.x + 2, newpos.y + self.height - 1) then
      self.movingr = true
      self.movingl = false
      newpos = self.pos:add(vector(config.enemyspeed, 0))
    end
  end

  self.pos = newpos
end

function enemy:draw()
  self.sprite:draw(self.pos.x, self.pos.y, self.movingl)
end

powerup = class(function(p, x, y)
  p.pos = vector(x, y)
  p.sprite = sprite('powerup')
  p.collected = false
end)

function powerup:gethitbox()
  return hitbox(
    self.pos.x,
    self.pos.y,
    8,
    8
  )
end

function powerup:draw()
  local x = self.pos.x
  local y = self.pos.y - 1

  local frame = animateoptions(6,8)

  if frame == 0 or frame == 1 then
    y -= 3
  elseif frame == 2 or frame == 5 then
    y -= 2
  end

  if not self.collected then
    self.sprite:draw(x, y)
  end
end

textblock = class(function(tb, texts, color, rate, frameinterval, music)
  tb.texts = texts
  tb.index = 1
  tb.color = color
  tb.rate = rate
  tb.bgdrawn = false
  tb.firstdraw = false
  tb.frameinterval = frameinterval or 30
  tb.firstframe = nil
  tb.musicplaying = false
  tb.music = music
end)

function textblock:reset()
  self.firstdraw = false
  self.firstframe = nil
  self.bgdrawn = false
  self.musicplaying = false
end

function textblock:draw()
  if not self.bgdrawn then
    palt(0, true)
    rectfill(0, 0, 127, 127, 0)
    self.bgdrawn = true
  end

  if self.firstframe == nil then
    self.firstframe = frame
  end

  if not self.musicplaying then
    music(-1)
    music(self.music)
    self.musicplaying = true
  end

  local thisframe = frame - self.firstframe

  if (thisframe % self.rate) == self.frameinterval and self.index <= #self.texts then
    color(self.color)
    local strs = self.texts[self.index].texts

    if self.texts[self.index].color then
      color(self.texts[self.index].color)
    end

    if self.texts[self.index].align == 'center' then
      local cursor_x=peek(0x5f26)
      local cursor_y=peek(0x5f27)
      local len = #strs[1]
      print(strs[1] .. "\n\n", 64 - (len/2)*4, cursor_y)
    else
      foreach(strs, function(s)
        if not self.firstdraw then
          print(s, 4, 4)
          cursor(4,10)
          self.firstdraw = true
        else
          print(s)
        end
      end)
      print("\n")
    end

    self.index += 1
  end
  color()
end

level = class(function(l)
  l.player = player()
  l.width = 1024

  l.playing = false

  l.enemies = {}
  l.powerups = {}
end)

function level:init()
  local sectionindex = 0

  foreach(config.levelsections, function(s)
    for i=0,127 do
      for j=0,15 do
        local x = i + s.start[1]
        local y = j + s.start[2]
        if fget(mget(x,y), flags.enemy) then
          local xy = maptiletoleveltile(x,y)
          add(self.enemies, enemy(xy[1] * 8, xy[2] * 8 - 4))
        end
        if fget(mget(x,y), flags.powerup) then
          local xy = maptiletoleveltile(x,y)
          add(self.powerups, powerup(xy[1] * 8, xy[2] * 8))
        end
      end
    end
    sectionindex += 1
  end)

  self.width = #config.levelsections * 128 * 8

  self.player:init()
end

function level:start()
  if not self.playing then
    self.playing = true
    music(-1)
    music(0)
  end
end

function level:stop()
  if self.playing then
    self.playing = false
    music(-1)
  end
end

function level:resetpowerups()
  foreach(self.powerups, function(p)
    p.collected = false
  end)
end

function level:update()
  if not self.playing then return end

  self.player.onplatform = false

  self.player.d.y = 1
  local tiles = self.player:gettiles(false, true)

  foreach(tiles, function(t)
    if fget(mget(t[1],t[2]), flags.obstacle) then
      self.player.onplatform = true
    end
  end)

  if self.player.onplatform then
    self.player.lastonplatform = frame
  end

  self.player:preupdate()

  local xtiles = self.player:gettiles(true, false)

  local xmax = self.player.xmax
  local xmin = self.player.xmin
  foreach(xtiles, function(t)
    if fget(mget(t[1],t[2]), flags.obstacle) then
      local lt = maptiletoleveltile(t[1],t[2])
      local t1 = lt[1]
      local t2 = lt[2]
      if self.player.d.x > 0 then
        xmax = min(xmax, t1 * 8 - self.player.width)
      end
      if self.player.d.x < 0 then
        xmin = max(xmin, t1 * 8 + self.player.width)
      end
    end
  end)
  self.player.xmax = xmax
  self.player.xmin = xmin

  self.player:updatex()

  local ytiles = self.player:gettiles(false, true)

  local ymin = self.player.ymin
  local ymax = self.player.ymax
  foreach(ytiles, function(t)
    if fget(mget(t[1],t[2]), flags.obstacle) then
      local lt = maptiletoleveltile(t[1],t[2])
      local t1 = lt[1]
      local t2 = lt[2]
      if self.player.d.y > 0 then
        self.player.onplatform = true
        ymax = min(ymax, t2 * 8 - self.player.height)
      end
      if self.player.d.y < 0 then
        ymin = max(ymin, (t2+1) * 8)

        if ymin == self.player.pos.y then
          self.player.jumpblocked = true
        end
      end
    end
  end)
  self.player.ymin = ymin
  self.player.ymax = ymax

  self.player:updatey()
  self.player:postupdate()

  local tiles = self.player:gettiles(false, false)

  foreach(self.enemies, function(e)
    e:update()

    if e:gethitbox():iscolliding(self.player:gethitbox()) then
      self.player:attacked()
    end
  end)

  foreach(self.powerups, function(p)
    if not p.collected and p:gethitbox():iscolliding(self.player:gethitbox()) then
      self.player:powerup()
      p.collected = true
    end
  end)
end

function level:draw()
  if not self.playing then return end

  local camerax = self.player.pos.x - 64 + 4
  local cameray = self.player.pos.y - 64 + 4
  local clampedcamerax = mid(0, camerax, self.width - 128)
  local clampedcameray = mid(0, cameray, 128 - 128)

  foreach(config.layers, function(l)
    if l.camerafollow and l.camerafollow > 0 then
      camera(clampedcamerax * l.camerafollow, clampedcameray * l.camerafollow)
    else
      camera()
    end

    local flags = 0

    if l.flags then
      flags = getbitfield(l.flags)
    end

    palt()

    if l.transparent ~= nil then
      palt(0, false)

      if type(l.transparent) == 'table' then
        foreach(l.transparent, function(c)
          palt(c, true)
        end)
      else
        palt(l.transparent, true)
      end
    end

    if l.level then
      local sectionindex = 0
      foreach(config.levelsections, function(s)
        map(
          s.start[1],
          s.start[2],
          sectionindex * 128 * 8,
          0,
          l.size[1],
          l.size[2],
          flags
        )

        sectionindex += 1
      end)
    else
      l.repeatx = l.repeatx or 1
      for i=0,l.repeatx-1 do
        map(
          l.start[1],
          l.start[2],
          i * l.size[1] * 8,
          0,
          l.size[1],
          l.size[2],
          flags
        )
      end
    end
  end)

  foreach(self.enemies, function(e)
    e:draw()
  end)

  foreach(self.powerups, function(p)
    p:draw()
  end)

  self.player:draw()

  camera()

  statbar(4,2,118, self.player):draw()
end

function getbitfield(selectedflags)
  local result = 0
  foreach(selectedflags, function(f) result += 2 ^ f end)
  return result
end

function _init()
  printh("\n\n\n")

  levels[1]:init()
end

function _update()
  frame += 1

  if epiloguelocktimer > 0 then
    epiloguelocktimer -= 1
  end

  if not levels[1].playing and (btn(0) or btn(1) or btn(2) or btn(3) or btn(4)
  or btn(5)) and epiloguelocktimer == 0 then
    levels[1]:start()
    levels[1].player:respawn()
    prologue:reset()
    epilogue:reset()
  end

  levels[1]:update()
end

function _draw()
  if levels[1].playing then
    levels[1]:draw()
  elseif levels[1].player.won then
    epilogue:draw()
  else
    prologue:draw()
  end
end

epiloguelocktimer = 0

prologue = textblock({
  {
    texts = {"a mission as important as", "it is dangerous."},
    align = 'left'
  },
  {
    texts = {"untested technology in the", "hands of one person."},
    align = 'left'
  },
  {
    texts = {"a time machine running on a", "short battery."},
    align = 'left'
  },
  {
    texts = {"recharge with blood.", "rejuvenate with power."},
    align = 'left'
  },
  {
    texts = {"press any button"},
    align = 'center',
    color = 8,
  }
}, 7, 60, 30, 4)

epilogue = textblock({
  {
    texts = {"this brave individual dared to", "travel through time,"},
    align = 'left'
  },
  {
    texts = {"potentially decimating the", "fabric of reality,"},
    align = 'left'
  },
  {
    texts = {"so as to avoid late filing fees", "from the i.r.s."},
    align = 'left'
  },
  {
    texts = {"do your taxes on time", "or suffer the consequences."},
    align = 'left'
  },
  {
    texts = {"press any button to play again"},
    align = 'center',
    color = 8,
  }
}, 7, 60, 15, 4)

frame = 0

levels = {
  level()
}

__gfx__
077777700000000022222222e2e2e2e2e000e000e0e0e0e074440404444444444040744400000000000000008444484444844448000000000000000000000000
7700007708808800222222222e2e2e2e000000000e0e0e0e46664646664664666464666400000000000000004666646666466664000000000000000000000000
700000078888888022222222e2e2e2e200e000e0e0e0e0e004664646664664666464664000000000555000004666646666466664000000000000000000000000
7bbbbbb788888880222222222e2e2e2e000000000e0e0e0e00444444444664444444440000000000000000004666646666466664000000000000000000000000
7bbbbbb7888888802222222222222222e000e000e0e0e0e000446666664664666666640000000000555000008444484444844448000000000000000000000000
7bbbbbb70888880022222222e2e2e2e2000000000e0e0e0e0004444444466444444440000000000005000000455cccccccccccc4000000000000000000000000
7bbbbbb700888000222222222222222200e000e0e0e0e0e0000046666664466666640000000000000500000045c7ccccccc7ccc4000000000000000000000000
7777777700080000222222222e2e2e2e000000000e0e0e0e00000444444444444440000000000000050000004c7ccccccc7cccc4000000000000000000000000
00000000000000000000000000000000555555858858488800004788888848888884000005555550050000004ccccccccccc7cc4000000000000000000000000
00000000000000000000000000000000558545855558488800004888888848888884000055666655050000004cccccccccc7ccc4000000000000000000000000
00000000000000000000000000000000544545454455554500000444444444444440000056566665050000004ccccccccc7cccc4000000000000000000000000
00000000000000000000000000000000788585857585555400004784788888847884000056556665050000004cccccccc7ccccc4000000000000000000000000
00000000000000000000000000000000888585858885555400004884888888848884000056665565050000004cccc7cc7cccccc4000000000000000000000000
00000000000000000000000000000000888885858885555400004884888888848884000056666565050000004ccc7cccccccccc4000000000000000000000000
00000000000000000000000000000000444444454454454400000444444444444440000055666655050000004cccccccccccccc4000000000000000000000000
00000000000000000000000000000000888547858888455500004888888847888884000055555555050000004cccccccccccccc4000000000000000000000000
00000000000000000000000000000000000000000000000022225225222222220000000008807700000000004cccccccc7ccccc4000000000000000000000000
00000000000000000000000000000000000000000000000022222222555222220000000088887770000000004ccccccc7c5cccc4000000000000000000000000
00000000000000000000000000000000000000000000000022222252522522220000000088881117000000004cccccc7555cccc4000000000000000000000000
00000000000000000000000000000000000000000000000022225522552225220000000088877117000000004ccccc7ccc5ccc54000000000000000000000000
600ff000600ff0000600000000000000000000000000000022522222522222520000000088877117000000004cccc7ccccc5c554000000000a0d800000a00000
000ff000000ff000000ff00000000000000000000000000022552522552225220000000008881117000000004ccc7ccccccc555400000000000dd000000d8000
60cccc0060cccc0060cffc0000000000000000000000000025522222525555520000000000881117000000004cc7cccccc555554000000000a66a6000a6dd600
66cccc0066cccc0066cccc0000000000000000000000000055222222555555550000000000087770000000004444444444444444000000000606a0000606a000
6ccccc006ccccc006ccccc00222222222272222e222222222222222255555555078800080007700000aaaa000777777000000000000000000606a6000d66a600
6ccccc006ccccc006ccccc00222222222eeeeeee22222222555222225555555507887878000770000a0000a07007007700000000000000000d66a0000666a000
099999000999990009999900222222e27eeeeeeee222222252522222555555550788878800000000a00aa00a7077707700000000000000000066a6000066a600
0ccccc000ccccc000ccccc00222222eeeee22e2e2e22222255522552555555550788787877777777a0a00a0a0777777000000000000000000066a0000066a000
0c000c000c00090009000c0022222eeee2ee22eeee22222252522552555555550700888000000000a0a00a0a0707070000000000000000000d00060006000d00
0c000c000c00099009900c00227eeeeeeeeeeeeeeee2222255522552555555550700000000077000a00aa00a7070707000000000000000000dd0060006000dd0
09000900090000000000090022eeee2eeeeee2ee7ee22222525555525555555507000000007007000a0000a007777770000000000000000000000d000d000000
099009900990000000000990e2ee2ee2eeeeeeee27ee2e2e5555555555555555070000000700007000aaaa0000777700000000000000000000000dd00dd00000
22222277672222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006555555606666660
2222776666662222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000665815666eeeeee6
2277666776666622000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c000c00665566068888886
22767767766766220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066660068888886
276777766666666200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c0c0000000068888886
27677776666677620000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c1c0c1c00000000068888886
766677666676676600000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c1c1c1c0000000068888886
76666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111110000000006666660
66656666667666660000000022222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
76665666666666660000000022222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2656655666665662000000002222222200000000000cccccccccc000000000000000000000000000000000000000000000000000000000000000000000000000
266555555656666200000000222222220000000000cc00000000cc00000000000000000000000000000000000000000000000000000000000000000000000000
22666656566666220000000022277222000000000cc0000000000cc0000000000000000000000000000000000000000000000000000000000000000000000000
22666656666666220000000022777722000000000cc00000005550c0000000000000000000000000000000000000000000000000000000000000000000000000
2222666665662222000000002557575200000000cc006666606660cc000000000000000000000000000000000000000000000000000000000000000000000000
2222226666222222000000005575755500000000cccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000222222250000000052222222cccccccccccccccc0000000077777777777777770000c0000000000000000000000000008333333333333338
0000000000000000222222550000000055222222c777c5c5c5c5777c55555555333333333333333300000c000000000000000000000000003333333333333333
0000000000000000222225550000000055522222ccc7c5c5c5c57ccc55005500373333733737373700777ccc0000000000000000000000003377737773737333
0000000000000000222255550000000055552222ccccc5c5c5c5cccc500005003773373737773373077777000000000000000000000000003337337373737333
00000000000000002225555500000000555552226cccccccccccccc6500005003737377733373333777777700000000000000000000000003337337773373333
00000000000000002255555500000000555555226600000000000066550055003777373737773333770777700000000000000000000000003337337373737333
00000000000000002555555500000000555555526600000000000066555550003333333333333333700077000000000000000000000000003337337373737333
00000000000000005555555500000000555555556600000000000066055500007777777777777777077770000000000000000000000000003333333333333333
22222222222222250000000055555555000000005222222222222222aaaaaaaa0006666566666665666660003333333300000000000000003377737773373333
22222222222222550000000055555555000000005522222222222222555555550666666566666665666666603303030300000000000000003373737373737333
22222222222225550000000055555555000000005552222222222222aaaaaaaa0666666566666665666666603030303300000000000000003377337733737333
22222222222555550000000055555555000000005555522222222222555555556666666566666665666666650777777000000000000000003373737373737333
22222255555555550000000055555555000000005555555555222222555555556666666566666665666666650330303000000000000000003377737373373333
22225555555555550000000055555555000000005555555555552222555555556666666566666665666666650303033000000000000000003333333333333333
22555255525252520000000052525252000000002525252555255522555555556666666566666665666666650330303000000000000000003373773737377333
55252525252525250000000025252525000000005252525252525255555555556666666566666665666666650033330000000000000000008333333333333338
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0
f0f0f0f0f0f0f0f0f0f0f0000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f000000000f000000000000000000000000000f0f0000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000f0f0f0f0f00000f0f0f0f00000f0f00000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000f0000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000b3009100a0000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000a00000000000000000000000000000000000f060707070707080000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000091000000000000000000f0a0a0000000000000
000000000083b300a10000000000000000000000000000004100000041a1a1410000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000060707070708000000000f06080f00000000060
800000000060707080000000000000000000000000000000a0000000710000710000000000000000000000000000000000000000000000000000000000000000
f0f0f0f0f0f0f0f0f0f0f000000000000000000000000092000000000000000000000000000000000000b3a000617171717181000000f0f0618100f000000061
810000000061717181000000000000000000000000000000a1f051007100007100000000000000000000000000000000000000000000000000000000000000a0
f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000607070707171717181000000f000618100f0f0000061
810000000061b0c081000000000000000000000000000000a100a00071000071000000000000000000000000000000000000000000000000000000b300008391
f0f0f0f0f0f0f0f0a0f0f0000000000000a00000000000f0a00000000000000000000000000000910000617171717171717181000000f0006181f0f0f0000061
810000000061b1c18191000000000000a00000000000f0004100a100719191719200000000000000000000000000000000000000000000000000006070707070
f0f0f0f0f0f0f0f0a1f0f0000000000000a1000000000000a10000000000000000a00000000000607070707171717171717181000000f000618100f0f0000061
810000000061b2c27070707080000000a10000000000f000a000a1f0607070707080000000000000000000000000000000000000000000000000006171717171
f0f0f0f0f0f0f0f0a1f0f0000000000000a100000000b391a10000000000000000a10000b3a00061717171717171717171718100000000f0618100f000000061
81000000f06171717171717181000000a100000000000000a10051f061a100410000000000000000000000000000000000000000000000510000006171b0c071
f0f0f0f0f0f0f0f0a1f0f0000000000000a1000000006070800000000000000000a100006070707071b0c071b0c071b0c0718100000000f06181000000000061
810000000060707171b0c0718191b300a100000000000000a1f0a100610000710000000000000000000000000000000000000000000000a10000006171b1c171
f0f083f0f0f0f0f0a1f0f00000000000b3a1910000006171810000000000000000a1f0006171717171b1c171b1c171b1c1718100000000f06181000000000061
8100000000f0607171b1c1717070707080f00000510000004100a100610000710000000000000000000000000000000000000071000000a10000006171b2c271
f0607080f0f0f0f041f0f0f05100000060708000000061718100000000f08300006070707071717171b2c271b2c271b2c2718100000000f06181000000000061
8100000000f0617171b2c2717171717181f00000a1000000a100a1006100007100009100000000a00000008300009100000000a1000000a10000006171717171
f0617181f0f0f0f071f0f0f071000000617181000000617181000000006080000061717171717171717171717171717171718100000000006181000000000061
8100000000f06171717171717171717181000000a000f000a000a0006100007100004100000000510000006070707080000000a0000000a00000006171717171
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f06070707080f000000000f0
f000000000f0f0f0f0f0f0f0f0f0f0f0f000f0f0f000f0f0f0f0f0f0f0f0f0f000000000000000f0f0f0f0f0f0f0f0f0f0f000f00000f0f0f00000f0f0f0f0f0
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a0f0f00000000000000000000000f0f0f061b0c05181f00000000000
000000a0a0f000f00000000000000000000000a000000000000000000000000000000000000000000000000000000000000000000000f0f00000000000000000
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a1f0f000000000a000000000000000009161b2c27181a00000000000
0000b3a1a10000000000000000000000000000a10000000000f0000000000000000000000000000000000000a100000000a10000000000000060707070707070
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a1f0f0f0f000b3910091f00000000000607070707070800000000060
70707070708000000000000000000000000000a1000000000000000000000000000000000000000000000000a100000000a10000000000000000006171917191
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a1f0f0f0f060707070708000000000000061b0c05181000000000061
41414171418100000000000000000000000091a1b30000000000000000000000000000000000000000000000a100000000a10000000000000000006070707070
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f091b3a1f0f0f0f06151517180f000000000000061b2c27181a00000000061
b0c071b0c0810000f08391b30000000000607070707080000000000000000000000000000000000000000000a100000000a10000000000000000006171717171
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f06070707080f0f0f0617171718100000000000060707070707080000000f061
b1c171b1c1810000f06070707080000000614171715181000000009100b300000000000000000000000000007600000000760000000000000000006171717171
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0614181f0f0f0f061b0c05181000000000000f061b0c0418100000000f061
b2c271b2c2810000f061515151810000006171b0c07181000000607070707080000000a000000000000000007600000000760000000000000000006070707070
f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0619181f0f0f0f061b1c17181920000000000f061b2c2718100000000f061
7171517141810000f061b0c051810000006171b1c17181000000614141714181000000a1000000000000000076000000007600000000000000000061e6f64171
80f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f06070707080f0f0f061b1c1717080000000000060707070707080000000f061
b0c071b0c0810000f061b1c171810000006171b2c27181000000617171717181000000a1000000000000000000000000000000000000000000000061e7f77171
81f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a0f0f0f0f0a0f0f0f0f0f0f0f0f0614181f0f0f0f061b2c27181a00000000000f061b0c07181000000000061
b1c171b1c1810000f061b2c2718100000061715141718100000061717171718191b300a1000000000086960000000000000000000000009686000061b0b07171
81f0f0f0f0f0f0f0f0f051f0f0f0f0f0f0b3f091a1f0f0f0f0a1f083f0f0f0f0f0f0617181f0f0f0f06171715181a10000000000f061b2c29181a00000000061
b2c271b2c2810000f0614171718100000061517151718100000061717171717070707080000000000000a000000000000000000000000000a0000061b1b17171
81f0f0f0f0f0f091f0f0a0f0f0f0f0f0f060707080f0f0f0f060707080f0f0f0f06070707080f0f0f061b0c07170800000000000607070707070800000000061
517171517181000060707171718100000061715171718100000061717171714171b0c081000000000000a100000000000000000000000000a1000061b1b17171
81f0f0f0f0f0f071f0f0a1f0f071f0f0f061b0c081f0f0f0f061517181f0f0f0f0f0617181f0f0f0f061b1c1718000000000000000a1a0a1a0a1a00000000061
b0c071b0c08100006171b0c0718100000061717171718100000061717171717171b1c181000000000000a100000000000055650000f0f000a1000061b1b17171
81f0f0f0f0f0f0a0f0f0a1f0f0a0f0f0f061b1c181f0f0f0f061715181f0f0f0f092619181f0f0f0f061b1c1718100000000000000a0a183a1a0a10000000061
b1c171b1c18100006171b1c1718100000061717171718100000061717171717171b2c281a6a6000000b7a100000000000056660000f0f000a1b7a361b1b17171
81f0f0f051f0f0a1f0f0a1f0f0a1f0f0f061b1c181f0f0f0f060707080f0f0f0f06070707080f0f0f061b2c27181000000000000607070707070800000000061
b2c271b2c28100006171b2c2718100000061717171718100000061717171717171879797979797979797a7777777777777777777777777778797979797979797
__gff__
0000010101010303030001030300000000000000030303030301010303000000000000000000010100400003030000000000000101010101040810200000000001010000000000000000000000000000010100000001010000000000000000000000000000010101010101000000010100000000000000030303030100000101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000000000000000000000000000000000000000000000000000f000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0a0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1a0f0f0f0f000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1a0f0f0f0f000000000000000000000000000000000000000000000000000000381a0f000000000019000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1a0f0f0f0f000000000000000000000000000000000000000000000000000000060707080f0f060707080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1a0f0f0f0f000000000000000000000000000000000000000000000000000000161515183b19161514180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f193b38190f000000000000000000000000000000000000000000000000000006070707070707070707070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f060707070707080000000000000000000000000000000000000000000000000000061717141717141417080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f161417171518000000000000000000000000000000000000000000000607080000160b0c170b0c170b0c1800000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000003c0000000000000000000000000000000000
0a0f0a0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f16170b0c1718290000000000000000000000000000000000000000001617180000161b1c171b1c151b1c1800000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000000a00000000000000000000
1a191a390f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0607070707171b1c170708000000000000000000000000000000000000000f0f1617180000161b1c151b1c171b1c1800000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000000000000001a00000000000000000000
070707080f0f0f0f0f0f0f0f0f0f0f0f0f0f0f19190f3b0f0f380f0f0f0f0f060707080f0f1615171717152b2c1718000000000000000000000000000000000000000006070715180000161b1c171b1c151b1c1800000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000000a00000000001a00000000000000000000
171714180f0f0f0f0f0f0f0f0f0f0f0f0f0f060707070707070707080f0f0f161517180f0f1617151715171919170708000000000a0000000000000a0000000000000f16141515180000162b2c172b2c172b2c1800000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0000000000001a00000000001a00000000000000000000
0c1717180f0f0f0f0f0f0f0f0f0f380f0f0f161417171717141717180f0f0f161715180f0f1617171517171717171800000000001a0000000000001a0000000000000f161717171800001607071707071707071800000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f193b00000000001a00000000001a00000000000f0f0f0f0f
1c1715180f0f0f0f06070707070707080f0f160b0c170b0c170b0c180f0f0f161717180f0f1617151717171717170708000000001a0000000f38191a000000000f0607071717171800001617151714141717141800000000000f0f0f0f0f0f0f380f0f0f0f0f0f06070707080000000700000000000700000000000607070708
1c1517180f0f0f0f16171515171717180f0f161b1c151b1c171b1c180f0f0f161717180f0f1615171717171717080f000a000000150f0f0f06070708000000000f161715171715180000160b0c170b0c170b0c18000a0a0f000f0f0f0a0f0f0f0607080f0f0f0f16141417180000001700000000001500000000001617171718
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000000000000000000000000000000000000000000000000000000000000000f0f0f0f000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f000000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000f0000000000000000000000000000000000000f0f0000000000000000000000000f0f0f0f0f0f0f0f0f0f0f0f0000000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020204040404040404040404040404040404
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020205050505050505050505050505050505
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020203030303030303030303030303030303
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020233343435020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0202020202020202023502020202020202020202020202020202020233343434350202020202333502023334343434350202020202020202020202020202020202020202020202020202020202333434343434350202020202023334350202020202020202020202020202020233343502020202020202020202024041020202
0233343434350202020202020202020202020202333502020202023334343434343535020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202333435020202020202020202020202020202020202025051020202
0202020202020202333434350202020202020202020202020202020202020202020202020202020202020202020202020233343502263334350202020202333502020202020202023335020202020202020202260202020202020202020202020202020202020202020233343435020202020202020202020202020202020202
0202023335020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020253020202020202020202020202020202020202020202020202020202025353020202333434350202020202020202333435020202023334343434350202020202020202020202020202020202
0202020202020202020202020202020202020202020202020202020202020202333502020202020202020202020202020202026237640202020202020202020202020233343434350202020202020202623737640202020253260202020202020202020202020202020202020202020202020202020202020202020202020202
0202360202020202020202020202020202023334343502020202020202020202020202333435020202020202022602020202623737376402020202020202022602260202020202020202020202020262376262376402026237640202020202333435020202020202020202020202020202020202020202020202020202020202
2636373602022602022602020227020202020202025302020202020202020202020233343434350202020202360202020262373737363764020202020202273636020202020202020202020202026237626273377375717373736426020202020202020202360202020202020202023602020202020202020202020202020202
2737373727360202262702363637360202020202623764020202020202262626020202020202020202020236370202026237733636377337757676022636373737020202020226260202360202623762717337733773737373737364020253020226020202370202363627272702363702020202020202020202020202020202
3737373737372636373737373737373602367071737373757636020227272702020202020226262602363637377026627373737373737373735376763637373737363627363636363636377071376273737373737373737373737373757137643636363627373636373737373736373702020202020202020202020202020202
3737373737373737373737373737373737373737373737373737363637373775767076705353537670373737373762367373737373737370717375763737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373737373702020202020202020202020202020202
__sfx__
0101000010120101501012010120101201012010120101201f120201202212023120241202412025120271202712028120291202a1202b1202c1202d1202f1202f1203012031120321202f7202c7202a72027720
01020000053200532005320063200632006320073200732007320073200732019520195201e520235202c5202f5203052031520325202832028320013000130028320283201e5001e6002932029320156201d620
01020000302203022000000302203022000000302203022030220000002b3002d0202c0202902028020280202702025020230202c2001f0201a020180202b20014020110200e0200c02009020080200602004020
010000003f3203f3203f32034620346203462036620386203b6203e6203e62038620366202e6202c6202b6202c6202d720020200202001020010200102002020396202f62029620216201d620136200862002620
0103000004320073200932009320063000130001300123201432016320173201732006300083001e3201e3202132026020260201230014300153002c0202c0202d0202e0202f0203002031020320203402036020
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000b771000000b771000000b771000000b7710000011771000001177100000117710000011771000000e771000000e771000000e771000000e751000001175100000117510000011751000001175100000
01080000100300000010030000000000000000100300000011030000001103000000000000000011030000000e030000000e03000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0108000017420000001741000000000000000017420000001a420000001a4100000000000000001a420000001c420000001c4100000000000000001c420000001d420000001d4100000000000000000000000000
010800000b210000000b210000000b210000000b210000000b210000000b210000000b210000000b2100000013210000001321000000132100000013210000000e210000000e210000000e210000000e21000000
010800000b210000000b210000000b210000000b210000000b210000000b210000000b210000000b2100000011210000001121000000112100000011210000001321000000132100000013210000001321000000
010800001d420000001d4200000000000000001c4200000000000000001c4200000000000000001a42000000000000000017420000001742000000154200000017420000001a4200000017420000000000000000
0108000017420000001742000000000000000017420000001d420000001d4200000000000000001d420000001c420000001c4200000000000000001c420000001a420000001a4200000000000000000000000000
010400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 14151944
00 18151a44
00 14151940
02 17161a40
03 0f104040
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 04040404
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000


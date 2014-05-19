--------------------------------------------------------------------------------
function isCompanion()
  return lovebound ~= nil and lovebound.isCompanion()
end
--------------------------------------------------------------------------------
function interceptItemator(itemConfig)
  if lovebound.intercept and itemConfig.lovebound then
    lovebound.updateRelationship(lovebound.targetId, itemConfig)
    lovebound.intercept = false
    lovebound.targetId = nil
    return true
  end
  return false
end
--------------------------------------------------------------------------------
lovebound = {
  interactDelay = 1,
  interactTimer = 0,
  decayTime = 3600
}
if delegate ~= nil then delegate.create("lovebound") end
--------------------------------------------------------------------------------
function lovebound.init()

end
--------------------------------------------------------------------------------
function lovebound.main()
  if lovebound.interactTimer > 0 then
    lovebound.interactTimer = lovebound.interactTimer - entity.dt()
  end
end
--------------------------------------------------------------------------------
function lovebound.die()
  if lovebound.beacon then
  
  end
end
--------------------------------------------------------------------------------
function lovebound.damage(args)
  local Uuid = world.entityUuid(args.sourceId)
  
  if args.sourceKind ~= "lovebound" then 
    if lovebound.targetId == Uuid then lovebound.targetId = nil end
    return
  end
  lovebound.intercept = true
  lovebound.targetId = Uuid
  return true
end
--------------------------------------------------------------------------------
function lovebound.interact(args)
  if args == nil or args.sourceId == nil then return end
  if lovebound.interactTimer > 0 then
    local Uuid = world.entityUuid(args.sourceId)
    local r = lovebound.getRelationship(Uuid)
    if lovebound.willFollow(r) then
      entity.say("Can I tag along?")
      storage.lb.companionUuid = Uuid
      self.companionEntityId = args.sourceId
    elseif Uuid == storage.lb.companionUuid then
      entity.say("See you later.")
      storage.lb.companionUuid = nil
      self.companionEntityId = nil
    end
    return true
  end
  lovebound.interactTimer = lovebound.interactDelay
end
--------------------------------------------------------------------------------
function lovebound.willFollow(r)
  if r == nil then return false end
  if storage.lb.companionUuid == nil then
    return r.f > entity.configParameter("relationship.companionThreshold", 50)
  end
  local c = lovebound.getRelationship(storage.lb.companionUuid)
  return r.f > c.f
end
--------------------------------------------------------------------------------
function lovebound.addRelationshipEffect(args)
  if args == nil then return end
  local relationship = "lb" .. tostring(args.type) .. "pill"
  if args.emote ~= nil then entity.emote(args.emote) end
  if relationship then
    if self.state.stateDesc() == "sitState" then self.state.endState() end
    lovebound.oldPrimaryItem = entity.getItemSlot("primary")
    entity.setItemSlot("primary", {name = relationship, count = 1})
    delegate.delayCallback("lovebound", "activateRelationshipEffect", nil, 0.1)
  end
end
--------------------------------------------------------------------------------
function lovebound.activateRelationshipEffect()
  entity.beginPrimaryFire()
  delegate.delayCallback("lovebound", "endRelationshipEffect", nil, 0.1)
end
--------------------------------------------------------------------------------
function lovebound.endRelationshipEffect()
  entity.endPrimaryFire()
  delegate.delayCallback("lovebound", "equipOld", nil, 0.1)
end
--------------------------------------------------------------------------------
function lovebound.equipOld()
    entity.setItemSlot("primary", lovebound.oldPrimaryItem)
end
--------------------------------------------------------------------------------
function lovebound.getRelationship(targetId)
  if storage.lb == nil then
    storage.lb = entity.configParameter("lb", {data = {}})
    if storage.lb == nil then storage.lb = {data = {}} end
  end
  if targetId == nil then return end
  if storage.lb.data == nil then storage.lb.data = {} end
  
  local r = lovebound.decay(storage.lb.data[targetId])
  if r == nil then
    r = {
      f = 0, l = 0, t = os.time()
    }
  end
  return r
end
--------------------------------------------------------------------------------
function lovebound.updateRelationship(targetId, args)
  if targetId == nil then return end

  local r = lovebound.getRelationship(targetId)
  local df = 0
  local dl = 0
  
  if args.sourceKind == "love" then
    if r.f < entity.configParameter("relationship.loveThreshold", 100) then -- buy me a drink first!
      dl = entity.randomizeParameterRange("relationship.disgustRange")
      df = entity.randomizeParameterRange("relationship.offendRange")
    else -- how lovely
      dl = entity.randomizeParameterRange("relationship.flirtRange")
    end
  else -- you're cool
    df = entity.randomizeParameterRange("relationship.charmRange")
  end
  
  r.f = r.f + df
  r.l = r.l + dl
  storage.lb.data[targetId] = r
  
  if df > 0 then
    local fThreshold = entity.configParameter("relationship.companionThreshold", nil)
    if fThreshold ~= nil and r.f > fThreshold then
      
    end
    lovebound.addRelationshipEffect({type = "friendship", emote = "happy" })
    --world.spawnProjectile("friendprojectile", entity.toAbsolutePosition({ 0, 2 }))
  elseif dl > 0 then
    local fThreshold = entity.configParameter("relationship.loveThreshold", nil)
    if fThreshold ~= nil and r.f > fThreshold then
      entity.say("I Love You!")
    end
    lovebound.addRelationshipEffect({type = "love", emote = "wink" })
    --world.spawnProjectile("loveprojectile", entity.toAbsolutePosition({ 0, 2 }))
  elseif dl < 0 or df < 0 then
    lovebound.addRelationshipEffect({type = "dislike", emote = "annoyed" })
    --world.spawnProjectile("dislikeprojectile", entity.toAbsolutePosition({ 0, 2 }))
  else
    lovebound.addRelationshipEffect({type = "indifference", emote = "neutral" })
    --world.spawnProjectile("indifferenceprojectile", entity.toAbsolutePosition({ 0, 2 }))
  end
  
  --TODO check if currently following and decay
  return true
end
--------------------------------------------------------------------------------
function lovebound.decay(r)
  if r == nil or r.f == nil or r.l == nil or r.t == nil then return nil end  
  local decay = entity.configParameter("relationship.decayRate", 1) * lovebound.decayTime
  local d = os.time() - r.t
  
  if r.l > 0 then
    r.l = r.l - (d / decay)
  elseif r.f > 0 then
    r.f = r.f - (d / decay)
  end
  r.t = os.time()
  return r
end
--------------------------------------------------------------------------------
function lovebound.isCompanion()
  lovebound.getRelationship()
  return storage.lb.companionUuid ~= nil
end
--------------------------------------------------------------------------------
function lovebound.beaconPing(beaconId)
  if not lovebound.isCompanion() then return end
  
  if self.state then self.state.pickState({beaconId = beaconId}) end
end
--------------------------------------------------------------------------------
function lovebound.beaconConfig()
  local config = {
    itemName = "beacondatachip",
    species = entity.species(),
    type = "villager",
    level = entity.level(),
    seed = entity.seed(),
    config = {
      dropPools = {"none"},
      scriptConfig = {
        spawnedBy = entity.configParameter("spawnedBy", nil),
        lb = storage.lb,
        npceq = storage.npceq
      }
    }
  }
  return config
end
--------------------------------------------------------------------------------
function lovebound.despawn()
  entity.setItemSlot("primary", {name = "advancedteleporter", count = 1})
  delegate.delayCallback("lovebound", "activateRelationshipEffect", nil, 0.5)
end
--------------------------------------------------------------------------------

function overload()
    chatState.loveboundEnter = chatState.enterWith
    chatState.enterWith = function(event)
      if isCompanion() then return nil end
      chatState.loveboundEnter(event)
    end

    converseState.loveboundEnter = converseState.enterWith
    converseState.enterWith = function(args)
      if isCompanion() then return nil end  
      converseState.loveboundEnter(args)
    end

    fleeState.loveboundEnter = fleeState.enterWith
    fleeState.enterWith = function(args)
      if isCompanion() then return nil end  
      fleeState.loveboundEnter(args)
    end

    sitState.loveboundEnter = sitState.enter
    sitState.enter = function()
      if isCompanion() then return nil end  
      sitState.loveboundEnter()
    end

    sleepState.loveboundEnter = sleepState.enter
    sleepState.enter = function()
      if isCompanion() then return nil end  
      sleepState.loveboundEnter()
    end

    standingIdleState.loveboundEnter = standingIdleState.enter
    standingIdleState.enter = function()
      if isCompanion() then return nil end  
      standingIdleState.loveboundEnter()
    end

    wanderState.loveboundEnter = wanderState.enter
    wanderState.enter = function()
      if isCompanion() then return nil end  
      wanderState.loveboundEnter()
    end

    workState.loveboundEnter = workState.enter
    workState.enter = function()
      if isCompanion() then return nil end  
      workState.loveboundEnter()
    end
end
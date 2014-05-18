if delegate ~= nil then delegate.create("lovebound") end
--------------------------------------------------------------------------------
function isCompanion()
  return lovebound ~= nil and lovebound.isCompanion()
end
--------------------------------------------------------------------------------
function isCompatible()
  return entity.seed() == tostring(tonumber(entity.seed()))
end
--------------------------------------------------------------------------------
function shouldRespawn()
--  if self.seedValidated == true then return false end
--  self.seedValidated = true
--  for i, value in pairs(entity) do
--	    world.logInfo("--" .. i)
--	  end
--	  for i, value in pairs(world) do
--	    world.logInfo("--" .. i)
--	  end
--  if not isCompatible() then
--    world.logInfo("--lovebound -- Respawning entity with clonable seed")
--    --world.spawnNpc(entity.toAbsolutePosition({ 0.0, 0.0 }), entity.species(), "villager", entity.level(), tonumber(entity.seed()));
--    return true
--  end
  return false
end
--------------------------------------------------------------------------------
function interceptItemator(itemConfig)
  if lovebound.intercept and itemConfig.lovebound then
    lovebound.updateRelationship(itemConfig)
    lovebound.intercept = false
    return true
  end
  return false
end
--------------------------------------------------------------------------------
lovebound = {}
--------------------------------------------------------------------------------
function lovebound.init()
  if storage.relationships == nil then
    local relationships = entity.configParameter("relationships", {})
    if relationships ~= nil then
      storage.relationships = relationships
    end
  end
  
  if storage.companionUuid == nil then
    local companionUuid = entity.configParameter("companionUuid", nil)
    if companionUuid ~= nil then
      storage.companionUuid = companionUuid
    end
  end
  
  --overload()
end
--------------------------------------------------------------------------------
function lovebound.main()
--  if entity.id() ~= nil and entity.id() ~= 0 then
--    if shouldRespawn() then die() end
--  end
end
--------------------------------------------------------------------------------
function lovebound.die()

end
--------------------------------------------------------------------------------
function lovebound.damage(args)
  local Uuid = world.entityUuid(args.sourceId)
  
  if args.sourceKind ~= "lovebound" then 
    if lovebound.targetId == Uuid then lovebound.targetId = nil end
    return nil
  end
  lovebound.intercept = true
  lovebound.targetId = Uuid
  return true
end
--------------------------------------------------------------------------------
function lovebound.interact(args)
    if storage.companionUuid == nil then
        local Uuid = world.entityUuid(args.sourceId)
        storage.companionUuid = Uuid
    else
        storage.companionUuid = nil
        self.companionEntityId = nil
    end
    --world.spawnNpc(entity.toAbsolutePosition({ 0.0, 0.0 }), entity.species(), "villager", entity.level(), entity.seed());
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
    entity.setItemSlot("primary", lovebound.oldPrimaryItem)
end
--------------------------------------------------------------------------------
function lovebound.decay()
  local decay = entity.configParameter("relationship.decayRate", 0.1)
  for i,status in pairs(storage.relationships) do
    status.friend = status.friend - decay
    status.love = status.love - decay
    if status.friend <= 0 then
      storage.relationships[i] = nil
    end
  end
end
--------------------------------------------------------------------------------
function lovebound.updateRelationship(args)
  if lovebound.targetId == nil then return end
  
  local status = storage.relationships[lovebound.targetId]
  local df = 0
  local dl = 0
  
  if status == nil then
    status = {
		friend = 0,
		love = 0
	}
  end
  
  if args.sourceKind == "love" then
    if status.friend < 10 then -- buy me a drink first!
      dl = entity.randomizeParameterRange("relationship.disgustRange")
      df = entity.randomizeParameterRange("relationship.offendRange")
    else -- how lovely
      dl = entity.randomizeParameterRange("relationship.flirtRange")
    end
  else -- you're cool
    df = entity.randomizeParameterRange("relationship.charmRange")
  end
  
  status.friend = status.friend + df
  status.love = status.love + dl
  storage.relationships[lovebound.targetId] = status
  
  if df > 0 then
    local fThreshold = entity.configParameter("relationship.companionThreshold", nil)
    if fThreshold ~= nil and status.friend > fThreshold then
      entity.say("Can I tag along with you?")
    end
    lovebound.addRelationshipEffect({type = "friendship", emote = "happy" })
    --world.spawnProjectile("friendprojectile", entity.toAbsolutePosition({ 0, 2 }))
  elseif dl > 0 then
    local fThreshold = entity.configParameter("relationship.companionThreshold", nil)
    if fThreshold ~= nil and status.friend > fThreshold then
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
  return true
end
--------------------------------------------------------------------------------
function lovebound.isCompanion()
  return storage.companionUuid ~= nil
end
--------------------------------------------------------------------------------



--  local pri = world.entityHandItem(args.sourceId, "primary")
--  local alt = world.entityHandItem(args.sourceId, "alt")
--  local df = 1 --math.random(-2, 5)
  
--if entity.seed() == tonumber(entity.seed()) then df = 0 end

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
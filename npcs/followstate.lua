followState = {
  closeDistance = 3,
  runDistance = 5,
  teleportDistance = 36,
}

function followState.enter()
  if not isCompanion() then return nil end

  return { running = false }
end

function followState.enterWith(params)
  if not isCompanion() then return nil end

  -- We're masquerading as wander for captive monsters
  if params.wander then
    return { running = false }
  end

  return nil
end

function followState.update(dt, stateData)
 
  -- Translate owner uuid to entity id
  if self.companionEntityId ~= nil then
    if not world.entityExists(self.companionEntityId) then
      self.companionEntityId = nil
    end
  end

  if self.companionEntityId == nil then
    local playerIds = world.playerQuery(entity.position(), 50)
    for _, playerId in pairs(playerIds) do
      if world.entityUuid(playerId) == storage.companionUuid then
        self.companionEntityId = playerId
        break
      end
    end
  end

  -- Companion is nowhere around
  if self.companionEntityId == nil then
    return false
  end

  local companionPosition = world.entityPosition(self.companionEntityId)
  local toCompanion = world.distance(companionPosition, entity.position())
  local distance = math.abs(toCompanion[1])
  local movement
  if distance > followState.teleportDistance then
    movement = 0
    followState.teleport(companionPosition)
    storage.companionUuid = nil
    return true
  elseif distance < followState.closeDistance then
    stateData.running = false
    movement = 0
  elseif toCompanion[1] < 0 then
    movement = -1
  elseif toCompanion[1] > 0 then
    movement = 1
  end

  if distance > followState.runDistance then
    stateData.running = true
  end

  if movement ~= 0 then
    move({ movement, toCompanion[2] }, followState.closeDistance)
  end
  entity.setRunning(stateData.running)

  return false
end

function followState.teleport(position)
    helper.log("Follow State :: teleport")
    local species = entity.species()
    local type = "villager"
    local level = entity.level()
    local seed = entity.seed()
    local params = {}
    params.relationships = storage.relationships
    params.companionUuid = storage.companionUuid
    params.equipment = storage.equipment
    --world.spawnNPC(position, species, type, level, seed, params)
    world.logInfo("break here")
    --entity["die"]()
end

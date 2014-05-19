beaconState = {
  closeDistance = 3,
  runDistance = 5
}

function beaconState.enterWith(params)
  if lovebound ~= nil and lovebound.isCompanion() and params.beaconId then
    return {
      beaconId = params.beaconId,
      running = false,
      timer = 6
    }
  end

  return nil,1
end

function beaconState.update(dt, stateData)
  -- Lost beacon
  if stateData.beaconId == nil or not world.entityExists(stateData.beaconId) then
      return true,1
  end
  -- Beacon off or no longer a companion
  local switch = world.callScriptedEntity(stateData.beaconId, "entity.animationState", "beaconState")
  if switch ~= "on" or not lovebound.isCompanion() then 
    return true,1
  end

  local position = world.entityPosition(stateData.beaconId)
  local toTarget = world.distance(entity.position(), position)
  local distance = world.magnitude(toTarget)
  if distance < beaconState.closeDistance then
    local result = world.callScriptedEntity(stateData.beaconId, "relocateNpc", entity.id())
    entity.setRunning(false)
    if result then lovebound.despawn() end
    return true,1
  else
    moveTo(position, dt)
  end
  stateData.running = distance > beaconState.runDistance
  entity.setRunning(stateData.running)

  return false
end
equipState = {}

function equipState.enter()
  local position = entity.position()
  local target = equipState.findTarget(position)
  if target ~= nil then
    return {
      targetId = target.targetId,
      targetPosition = target.targetPosition,
      timer = 10
    }
  end
  return nil
end

function equipState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.timer < 0 then
    return true, entity.configParameter("work.cooldown", nil)
  end

  local position = entity.position()
  local toTarget = world.distance(stateData.targetPosition, position)
  local distance = world.magnitude(toTarget)
  if distance < entity.configParameter("work.toolRange") then
    equipment.swapContainer(stateData.targetId)
    return true
  else
    move(toTarget, dt)
  end

  return false
end

function equipState.findTarget(position)
    --TODO What shape query?
    local objectIds = world.objectQuery(position, 20, { callScript = "hasCapability", callScriptArgs = {"equipment"} })
    if objectIds[1] ~= nil then
        return {targetId = objectIds[1], targetPosition = world.entityPosition(objectIds[1])}
    end
    return nil
end
--------------------------------------------------------------------------------
equipment = {
    isEquiped = false
}
delegate.create("equipment")

function equipment.init()
    if storage.equipment ~= nil then
        equipment.unequip()
        equipment.delay = world.time()
        equipment.main = equipment.tick
    else
        equipment.store()
        equipment.isEquiped = true
    end
end

function equipment.tick()
    if world.time() - equipment.delay > 0.5 then
    --    equipment.update()
    --    equipment.main = nil
        equipment.delay = world.time()
        --TODO
        --1) rewrite json items to prevent defaulting clothes
        --2) or use this route?
        local p = entity.position()
        if world.isVisibleToPlayer({p[1]-10, p[2]-10, p[1]+10, p[2]+10}) then
            if not equipment.isEquiped then
              delegate.delayCallback("equipment", "update", nil, 0)
            end
        else
            if equipment.isEquiped then
              delegate.delayCallback("equipment", "unequip", nil, 0)
            end
        end
    end
end

function equipment.store()
  local eq = entity.configParameter("equipment", nil)
  if eq == nil then
    eq = {}
    eq.head = entity.getItemSlot("head")
    eq.chest = entity.getItemSlot("chest")
    eq.legs = entity.getItemSlot("legs")
    eq.back = entity.getItemSlot("back")
  end
  storage.equipment = eq
end

function equipment.unequip()
    entity.setItemSlot("head", nil)
    entity.setItemSlot("chest", nil)
    entity.setItemSlot("legs", nil)
    entity.setItemSlot("back", nil)
    equipment.isEquiped = false
end

function equipment.update()
    local eq = storage.equipment
    if eq == nil then return end
    entity.setItemSlot("head", eq.head)
    entity.setItemSlot("chest", eq.chest)
    entity.setItemSlot("legs", eq.legs)
    entity.setItemSlot("back", eq.back)
    equipment.isEquiped = true
end

function equipment.swapContainer(storageId)
    local eq = storage.equipment
    eq.head = world.callScriptedEntity(storageId, "swapItemAt", eq.head, 0)
    eq.chest = world.callScriptedEntity(storageId, "swapItemAt", eq.chest, 1)
    eq.legs = world.callScriptedEntity(storageId, "swapItemAt", eq.legs, 2)
    eq.back = world.callScriptedEntity(storageId, "swapItemAt", eq.back, 3)
    storage.equipment = eq
    equipment.update()
end

function equipment.generate()
--TODO fix equipment to match any species
--TODO add safty checks
    local npcItem = "items." .. entity.species() .. "[0][1][0]"
    if storage.equipment.head == nil then
        storage.equipment.head = entity.randomizeParameter(npcItem .. ".head")
    end
    if storage.equipment.chest == nil then
        storage.equipment.chest = entity.randomizeParameter(npcItem .. ".chest")
    end
    if storage.equipment.legs == nil then
        storage.equipment.legs = entity.randomizeParameter(npcItem .. ".legs")
    end
    if storage.equipment.back == nil then
        storage.equipment.back = entity.randomizeParameter(npcItem .. ".back")
    end
end
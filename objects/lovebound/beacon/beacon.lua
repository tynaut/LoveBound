beacon = {
  npcRage = 20,
  dataRange = 3,
  data = {},
  npc = {}
}
--------------------------------------------------------------------------------
function init(args)
  entity.setInteractive(true)
  if storage.state == nil then
    switch(false)
  else
    switch(storage.state)
  end
end
--------------------------------------------------------------------------------
function main(args)
  if storage.state then
    pingNpcs()
    collectData()
  end
end
--------------------------------------------------------------------------------
function onInboundNodeChange(args)
  if entity.getInboundNodeLevel(0) then
    switch(true)
  else
    switch(false)
  end
end
--------------------------------------------------------------------------------
function onInteraction(args)
  switch(not storage.state)
end
--------------------------------------------------------------------------------
function switch(state)
  if state ~= storage.state then
    storage.state = state
    if state then
      entity.setAnimationState("beaconState", "on")
      entity.setAllOutboundNodes(true)
      beacon.data = {}
      beacon.npc = {}
    else
      entity.setAnimationState("beaconState", "off")
      entity.setAllOutboundNodes(false)
    end
  end
end
--------------------------------------------------------------------------------
function pingNpcs()
  local npcIds = world.npcQuery(entity.position(), beacon.npcRage, {order = "nearest"})
  for _,id in ipairs(npcIds) do
    if not beacon.npc[id] then
      world.callScriptedEntity(id, "lovebound.ping", entity.id())
      relocateNpc(id)
      beacon.npc[id] = true
    end
  end
end
--------------------------------------------------------------------------------
function relocateNpc(id)
  if world.isNpc(id) then
    local itemConfig = {
      itemName = "beacondatachip",
      species = world.callScriptedEntity(id, "entity.species"),
      type = "villager",
      level = 1,
      seed = world.callScriptedEntity(id, "entity.seed")
    }
    local config = {
      projectileConfig = {
        actionOnReap = {
          {
            action = "spawnmonster",
            offset = { 0, 0 },
            type = "itemator",
            arguments = {
              itemConfig = itemConfig
            }
          }
        }
      },
      itemConfig = itemConfig
    }
    local item = world.spawnItem(itemConfig.itemName, entity.position(), 1, config)
    if item then beacon.data[item] = true end
  end
end
--------------------------------------------------------------------------------
function collectData()
  local position = entity.position()
  local ids = world.itemDropQuery(position, beacon.dataRange)
  local success = false
  for _,id in ipairs(ids) do
    if world.entityName(id) == "beacondatachip" and not beacon.data[id] then
      local item = world.takeItemDrop(id, entity.id())
      if item then
        local npc = item.data.itemConfig
        local n = world.spawnNpc({position[1], position[2] + 2}, npc.species, npc.type, npc.level, npc.seed);
        if n then
          beacon.npc[n] = true
          success = true
        end
      end
    end
  end
  if success then switch(false) end
end
--------------------------------------------------------------------------------
function init(args)
  entity.setAggressive(false)
  
  --self.lifespan = entity.configParameter("lifespan", 0)
end
function main()
  --if self.lifespan then
    --self.lifespan = self.lifespan - entity.dt()
  --end
end
--------------------------------------------------------------------------------
function die(args)
  local itemConfig = entity.configParameter("itemConfig", {})
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
  if itemConfig.itemName then
    local ids = world.entityQuery(entity.position(), 2, {callScript = "interceptItemator", callScriptArgs = {itemConfig}, order = "nearest"})
    if ids and #ids > 0 then return end
    world.spawnItem(itemConfig.itemName, entity.position(), 1, config)
  end
end
--------------------------------------------------------------------------------
function shouldDie()
  return true--self.lifespan == nil or self.lifespan < 0
end
--------------------------------------------------------------------------------

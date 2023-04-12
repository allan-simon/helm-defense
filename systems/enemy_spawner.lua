local Concord = require("Concord")
local entities = require("../entities")
local EnemySpawnerSystem = Concord.system({pool = {"killable"} })
function EnemySpawnerSystem:spawn(player)
    local world = self:getWorld()
    local needSpawn = true
    for _, e in ipairs(self.pool) do
        if e:has("team") and e.team.teamNumber == 2 then
            needSpawn = false
            break
        end
    end

    if needSpawn then
        Concord.entity(world)
            :assemble(entities.enemy, player)
    end

end

return EnemySpawnerSystem

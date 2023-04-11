local Concord = require("Concord")

local CombatSystem = Concord.system({
    pool = {"attacking"}
})

function CombatSystem:combat()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        -- print(e.key.value, " is attacking ", e.attacking.with, "from ", e.attacking.attackingUsingSide)
        local defender = world:getEntityByKey(e.attacking.with)
        if defender == nil then
            e:remove("attacking")
            e:remove("cantMove")
            goto continue
        end
        if (defender:has('killable')) then

            local attackPoint = 1
            if e.attacking.attackedSide == 'back' then
                attackPoint = 2
            end


            defender.killable.lifePoint = defender.killable.lifePoint - attackPoint
            if defender.killable.lifePoint  <= 0 then
                -- TODO get defender's squad
                -- and add a component "sufferLoss" something like that
                defender:ensure("killed")
                e:remove("attacking")
                e:remove("cantMove")

                e:remove("hasTarget")
                if not e:has("inSquad") then
                    e:ensure("needTarget")
                end
            end
        end
        ::continue::
    end
end

return CombatSystem

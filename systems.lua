local Concord = require("Concord")
local HC = require("HC")

local MoveSystem = Concord.system({
    pool = {"tangible", "velocity"}
})

function MoveSystem:update(dt)
    for _, e in ipairs(self.pool) do

        -- TODO the rotation change maybe should be there
        -- so handling volte-face of squad (even those not player controlled)
        -- is all done at the same place
        e.tangible.shape:move(
            e.velocity.x * dt,
            e.velocity.y * dt
        )
        if e:has('tangibleSquad') then
            for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
                unitRank:move(
                    e.velocity.x * dt,
                    e.velocity.y * dt
                )
            end
        end
    end
end


local DrawSystem = Concord.system({
    pool = {"tangible", "drawable"},
    squad = {"squad", "tangible"}
})

function DrawSystem:draw()
    for _, e in ipairs(self.pool) do
        local shape = e.tangible.shape
        local x, y = shape:center()
        love.graphics.draw(
            e.drawable.image,
            x,
            y,
            shape:rotation(),
            1,
            1,
            e.drawable.width * 0.5,
            e.drawable.height * 0.5
        )
    end

    for _, e in ipairs(self.squad) do
        e.tangible.shape:draw('line')
        for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
           unitRank:draw('line')
        end
    end
end

local PlayerActionSystem = Concord.system({
    pool = {"tangible", "velocity", "playerMovable"}
})

local atan2 = math.atan2
function PlayerActionSystem:playerMove(player)
    local world = self:getWorld()
    local x, y = player:get('move')

    local angle = nil
    -- if x and y are both 0 it means we're not moving
    -- so we don't have the angle
    if x ~= 0 or y ~= 0 then
        angle = atan2(y, x) + math.pi * 0.5
    end
    for _, e in ipairs(self.pool) do
        if e:has('cantMove') then
            -- we verify the one blocking us is still there
            if world:getEntityByKey(e.cantMove.blockedByKey) == nil then
                e:remove('cantMove')
            else
                goto continue
            end
        end
        e.velocity.x = x * e.velocity.maxSpeed
        e.velocity.y = y * e.velocity.maxSpeed

        local shape = e.tangible.shape
        if angle == nil then
            -- we reinit the angle buffer
            -- when you stop moving, so that the buffer does not grow and grow
            e.playerMovable.angles = {}
            goto continue
        end
        table.insert(e.playerMovable.angles, angle)
        local currentAngle = shape:rotation()
        -- when you release the keys of going in diagonal
        -- during a very short instant you will have only
        -- one key press, not two
        -- so instead we take only the nth last angle to avoid this
        local actualAngle = e.playerMovable.angles[
            -- with the same logic we discard the nth first
            -- input because they are not reliable
            -- TODO: we should do this only for keyboard
            math.max(7, #e.playerMovable.angles - 7)
        ] or currentAngle

        local centerX, centerY = shape:center()

        -- if the angle hasn't changed, there's nothing to do
        if actualAngle == currentAngle then
            goto continue
        end

        if e:has('tangibleSquad') then

            -- if the squad has rotated by nearly 180 degree
            -- we rotate the unit rank on itself rather than on the
            -- squad center, otherwise when doing a 180 degree turn
            -- suddenly the unit at the most left will run to the most right
            -- which is not natural
            if (currentAngle - actualAngle) % math.pi < 0.01 then
                for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
                    unitRank:setRotation(actualAngle)
                end
            else
                for _, unitRank in ipairs(e.tangibleSquad.unitRanks) do
                    unitRank:setRotation(actualAngle, centerX, centerY)
                end
            end
        end
        shape:setRotation(actualAngle)

        ::continue::
    end
end

local function goTowardShape(e, targetShape, tolerance)
    tolerance = tolerance or 0

    local tX, tY = targetShape:center()
    local eX, eY = e.tangible.shape:center()

    -- we get the angle between the follower and its target
    local dx = tX - eX
    local dy = tY - eY

    -- no need to for perfect precision
    -- if you reached your destination up to the tolerance threshold
    -- we stop you there
    if ((dx*dx + dy*dy) <  tolerance*tolerance) then
        e.velocity.x = 0
        e.velocity.y = 0
        return
    end

    local angle = atan2(dy, dx) + math.pi * 0.5

    -- and we use it to adapt the velocity to go toward the target
    e.velocity.x = math.sin(angle) * e.velocity.maxSpeed
    e.velocity.y = -1 * math.cos(angle) * e.velocity.maxSpeed

    e.tangible.shape:setRotation(angle)

end

local FollowSquadSystem = Concord.system({
    pool = {"tangible", "tangibleSquad"}
})

function FollowSquadSystem:followSquad()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do

        local unitRanks = e.tangibleSquad.unitRanks

        for _, unitRank in ipairs(unitRanks) do
            local unit = world:getEntityByKey(unitRank._key)
            if unit == nil then
                goto continue
            end
            if unit:has('cantMove') then
                -- we verify the one blocking us is still there
                if world:getEntityByKey(unit.cantMove.blockedByKey) == nil then
                    unit:remove('cantMove')
                else
                    goto continue
                end
            end
            -- we allow a tolerance of 1
            -- otherwise the units would never quite reach the exact point
            -- and would move back and forth continously
            goTowardShape(unit, unitRank, 1)
            -- if the unit has stopped moving it means it has its destination
            -- so we realign it with the squad direction to have the "soldier in line"
            -- feeling
            if unit.velocity.x == 0 and unit.velocity.y == 0 then
                unit.tangible.shape:setRotation(e.tangible.shape:rotation())
            end
            ::continue::
        end
    end
end

local FollowTargetSystem = Concord.system({
    pool = {"tangible", "velocity", "hasTarget"}
})


function FollowTargetSystem:followTarget()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        if e:has('cantMove') then
            goto continue
        end

        local target = world:getEntityByKey(e.hasTarget.target)

        goTowardShape(e, target.tangible.shape)

        ::continue::
    end
end

local ToTangibleSystem = Concord.system({
    pool = {"drawable", "futureTangible"},
    squads = {"futureTangible", "squad"}
})

function ToTangibleSystem:toTangible()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do

        local width = e.drawable.width
        local height = e.drawable.height

        local rectangle = HC.rectangle(
            e.futureTangible.x - width * 0.5,
            e.futureTangible.y - height * 0.5,
            width,
            height
        )
        rectangle._key = e.key.value

        e:give(
            'tangible',
            rectangle
        )
        :remove("futureTangible")
    end

    for _, e in ipairs(self.squads) do
        local sumX = 0
        local sumY = 0

        local sumWidth = 0
        local sumHeight = 0

        -- TODO: compute the "circular mean"
        -- local _sumAngleX = 0
        -- local _sumAngleY = 0

        local units = {}
        for _, unitKey in ipairs(e.squad.units) do
            local unit = world:getEntityByKey(unitKey)
            -- remove dead units
            if unit == nil then
                goto continue
            end
            units[#units+1] = unitKey


            local x, y = unit.tangible.shape:center()
            sumX = sumX + x
            sumY = sumY + y

            sumWidth = sumWidth + unit.drawable.width
            sumHeight = sumHeight + unit.drawable.height

            ::continue::
        end
        e.squad.units = units
        if #units == 0 then
            e:ensure('killed')
            goto bigContinue
        end

        local numberUnits = #e.squad.units
        local gap = 2
        -- we add a gap of 2 between each units
        local totalWidth = sumWidth + ((numberUnits - 1) * gap)
        local totalHeight = sumHeight / numberUnits


        local rectangle = HC.rectangle(
            (sumX/numberUnits) - totalWidth* 0.5,
            (sumY/numberUnits) - totalHeight* 0.5,
            totalWidth,
            totalHeight
        )
        rectangle._ghost = true
        local centerX, centerY = rectangle:center()
        print(centerX, centerY)

        local widthOffset = centerX - (totalWidth * 0.5)
        print(widthOffset, "totalWidth", totalWidth)
        local unitRanks = {}
        for _, unitKey in ipairs(e.squad.units) do
            local unit = world:getEntityByKey(unitKey)
            local width = unit.drawable.width;

            local point = HC.point(widthOffset + width*0.5  , centerY)
            point._key = unitKey
            point._ghost = true
            widthOffset = widthOffset + width + gap

            unitRanks[#unitRanks + 1] = point
        end
        rectangle._key = e.key.value

        e:give(
            'tangible',
            rectangle
        )
        :give('tangibleSquad', unitRanks)
        :remove('futureTangible')

        ::bigContinue::
    end
end

local CollisionSystem = Concord.system({
    pool = {"tangible", "velocity"}
})

local pi = math.pi
local fourth_of_pi = math.pi * 0.25
function CollisionSystem:detectCollision(_)
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        local teamNumber = e.team.teamNumber
        local shape = e.tangible.shape
        if shape._ghost == true then
            goto bigContinue
        end
        local velocity = e.velocity
        local collisions = HC.collisions(shape)
        for other, separating_vector in pairs(collisions) do

            if other._ghost == true then
                goto continue
            end


            -- print(shape._key, "with other", other._key)
            local otherE = world:getEntityByKey(other._key)

            shape:move(separating_vector.x*1.0001,  separating_vector.y * 1.0001)
            --if (other
            -- shape:move((otherE.velocity.x - velocity.x)*dt, (otherE.velocity.y - velocity.y)*dt)

            if teamNumber == otherE.team.teamNumber then
                goto continue
            end

            -- we get the angle from the two centroid to know
            -- we normalize to its rotation
            -- if between -45/45 -> up  45/135 -> right etc.
            local tX, tY = other:center()
            local eX, eY = shape:center()

            -- we get the angle between the follower and its target
            local dx = tX - eX
            local dy = tY - eY
            local angle = atan2(dy, dx)
            -- we get the relative angle to the follower
            local relativeAngle = (angle - shape:rotation()) % (2*pi)

            local touchedDirection = "right"
            if relativeAngle < fourth_of_pi then
                touchedDirection = "right"
            elseif relativeAngle < 3*fourth_of_pi then
                touchedDirection = "back"
            elseif relativeAngle < 5 *fourth_of_pi then
                touchedDirection = "left"
            elseif relativeAngle < 7 *fourth_of_pi then
                touchedDirection = "front"
            else
                touchedDirection = "right"
            end

            local otherAngle = (angle + pi) % (2*pi)

            local otherRelativeAngle = (otherAngle - other:rotation()) % (2*pi)
            local otherTouchedDirection = "right"
            if otherRelativeAngle < fourth_of_pi then
                otherTouchedDirection = "right"
            elseif otherRelativeAngle < 3*fourth_of_pi then
                otherTouchedDirection = "back"
            elseif otherRelativeAngle < 5 *fourth_of_pi then
                otherTouchedDirection = "left"
            elseif otherRelativeAngle < 7 *fourth_of_pi then
                otherTouchedDirection = "front"
            else
                otherTouchedDirection = "right"
            end


            velocity.x = 0
            velocity.y = 0
            otherE.velocity.x = 0
            otherE.velocity.y = 0

            -- you attack and the other hence can't move
            -- except if you are touched from the back
            if touchedDirection ~= "back" then
                e:ensure("attacking", otherE.key.value, touchedDirection, otherTouchedDirection)
                otherE:ensure("cantMove", e.key.value)
            end
            --the other attacks and you hence can't move
            -- except if the other is touched from the back
            if otherTouchedDirection ~= "back" then
                otherE:ensure("attacking", e.key.value, otherTouchedDirection, touchedDirection)
                e:ensure("cantMove", otherE.key.value)
            end


            ::continue::
        end
        ::bigContinue::
    end
end

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

local KillRemoverSystem = Concord.system({
    pool = {"killed"}
})

function KillRemoverSystem:removeKilled()
    local world = self:getWorld()
    for _, e in ipairs(self.pool) do
        if e:has("tangible") then
            HC.remove(e.tangible.shape)
            if e:has("tangibleSquad") then
                for _, point in ipairs(e.tangibleSquad.unitRanks) do
                    HC.remove(point)
                end
            end
        end
        if e:has("inSquad") then
            local squad = world:getEntityByKey(e.inSquad.key)
            squad:ensure("futureTangible")
        end
        e:destroy()
    end
end

--

local FindTargetSystem = Concord.system({pool = {"needTarget", "tangible", "team"} })
function FindTargetSystem:lookForTarget()

    local world = self:getWorld()
    local spatialHash = HC.hash()


    for _, e in ipairs(self.pool) do

        local nearest = nil
        local distance = math.huge


        local eX, eY = e.tangible.shape:center()

        for _, shape in pairs(spatialHash:shapes()) do
            if shape._ghost == true then
                -- some shape like "point" where a unit must stand in squad
                -- or the shape of the squad itsel should not be collidable
                goto continue
            end
            local target = world:getEntityByKey(shape._key)

            if e.team.teamNumber ~= (target:has('team') and target.team.teamNumber or e.team.teamNumber) then

                local x, y = shape:center()
                local currentDistance = (
                    (eX - x)*(eX - x) +
                    (eY - y)*(eY - y)
                )
                if currentDistance < distance then
                    nearest = shape._key
                    distance = currentDistance
                end
            end
            ::continue::
        end

        if nearest ~= nil and not e:has('playerMovable') then
            e:remove('needTarget')
            e:ensure('hasTarget', nearest)
        end

    end
end

--

local entities = require("entities")
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

return {
    DrawSystem,
    PlayerActionSystem,
    ToTangibleSystem,
    FollowTargetSystem,
    FollowSquadSystem,
    MoveSystem,
    CombatSystem,
    CollisionSystem,
    KillRemoverSystem,
    EnemySpawnerSystem,
    FindTargetSystem,
}

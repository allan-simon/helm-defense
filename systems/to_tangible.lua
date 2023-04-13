local Concord = require("Concord")
local HC = require("HC")

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

    ------------------------------
    --  Case for Squads ,
    --  i.e calculate their 'shape' depending on the units
    --  composing them
    -----------------------------

    for _, e in ipairs(self.squads) do
        local sumX = 0
        local sumY = 0


        -- TODO: compute the "circular mean"
        -- local _sumAngleX = 0
        -- local _sumAngleY = 0

        local unitsKeys = {}
        local unitsEntities = {}
        for _, unitKey in ipairs(e.squad.units) do
            local unit = world:getEntityByKey(unitKey)
            -- remove dead units
            if unit ~= nil then
                unitsKeys[#unitsKeys+1] = unitKey
                unitsEntities[#unitsEntities+1] = unit
            end
        end
        local numberUnits = #unitsKeys
        -- as in the loop above we've removed the dead units
        -- we here check that the squad still has unit alive
        -- if not, we consider the squad itself as decimated
        if numberUnits == 0 then
            e:ensure('killed')
            goto bigContinue
        end

        e.squad.units = unitsKeys

        local numberCols = 8
        local numberRows = math.ceil(numberUnits / numberCols)

        local unitMaxWidth = 0
        local unitMaxHeight = 0

        for _, unit in  ipairs(unitsEntities) do
            local x, y = unit.tangible.shape:center()
            sumX = sumX + x
            sumY = sumY + y

            unitMaxWidth = math.max(unitMaxWidth, unit.drawable.width)
            unitMaxHeight = math.max(unitMaxHeight, unit.drawable.height)

        end


        local gap = 2
        -- we add a gap of 2 between each units
        local totalWidth = (unitMaxWidth + gap) * numberCols
        local totalHeight = (unitMaxHeight + gap) * numberRows


        local rectangle = HC.rectangle(
            -- the gravity center of the squad
            -- is set to the average point of the units
            (sumX/numberUnits) - totalWidth* 0.5,
            (sumY/numberUnits) - totalHeight* 0.5,
            --
            totalWidth,
            totalHeight
        )
        -- hack: we add _ghost to the shape like this
        -- as it's not a Entity so we can't add to it a Component
        rectangle._ghost = true

        local centerX, centerY = rectangle:center()

        local widthOffset = centerX - (totalWidth * 0.5)
        local heightOffset = centerY - (totalHeight * 0.5)

        local unitRanks = {}
        local remainingUnits = #unitsEntities
        local position = 0
        for i = 1,numberRows do
            local numberUnitInThatRow = math.min(remainingUnits, numberCols)
            for j = 1,numberUnitInThatRow do
                remainingUnits = remainingUnits - 1

                local point = HC.point(
                     widthOffset + (unitMaxWidth + gap)*(j-1) + unitMaxWidth*0.5,
                     heightOffset + (unitMaxHeight + gap)*(i -1) + unitMaxHeight*0.5
                )
                position = position + 1
                point._key = unitsKeys[position]

                point._ghost = true

                unitRanks[#unitRanks + 1] = point
            end
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

return ToTangibleSystem

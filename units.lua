local function velocityToRotation(xVelocity, yVelocity)
    if xVelocity == 0 and yVelocity == -1 then
        return 0
    end
    if xVelocity == 1 and yVelocity == -1 then
        return 45
    end
    if xVelocity == 1 and yVelocity == 0 then
        return 90
    end
    if xVelocity == 1 and yVelocity == 1 then
        return 135
    end
    if xVelocity == 0 and yVelocity == 1 then
        return 180
    end
    if xVelocity == -1 and yVelocity == 1 then
        return 225
    end
    if xVelocity == -1 and yVelocity == 0 then
        return 270
    end
    if xVelocity == -1 and yVelocity == -1 then
        return 315
    end

    return 0
end

local function keyToVelocity(self, key)
    local key = event.keyName
    if event.phase == 'up' then
        if key == 'w' then
            self.yVelocity = self.yVelocity + 1
        elseif key == 's' then
            self.yVelocity = self.yVelocity - 1
        elseif key == 'a' then
            self.xVelocity = self.xVelocity + 1
        elseif key == 'd' then
            self.xVelocity = self.xVelocity - 1
        else
            print(key)
        end
    else
        if key == 'w' then
            self.yVelocity = self.yVelocity - 1
        elseif key == 's' then
            self.yVelocity = self.yVelocity + 1
        elseif key == 'a' then
            self.xVelocity = self.xVelocity - 1
        elseif key == 'd' then
            self.xVelocity = self.xVelocity + 1
        end
    end

    self.rotation = velocityToRotation(self.xVelocity, self.yVelocity)
end

local function updateFrame()

end

local function draw(self)
    love.graphics.draw(
        self.image,
        self.x,
        self.y,
        0,
        1,
        1,
        self.width/2,
        self.height/2
    )
end

return {
    newSoldier=function()
        local image = love.graphics.newImage("soldier.png")
        return {
            x=10,
            y=10,
            width=image:getWidth(),
            height=image:getHeight(),
            xVelocity = 0,
            yVelocity = 0,
            rotation = 0,
            draw=draw,
            keyToVelocity=keyToVelocity,
            frameUpdate=frameUpdate,
            image=image
        }

    end,
    newEnnemy=function()
        local image = love.graphics.newImage("ennemy.png")

        return {
            xVelocity = 0,
            yVelocity = 0,
            rotation = 180,
            keyToVelocity=keyToVelocity,
            frameUpdate=frameUpdate,
            image=image
        }
    end
}

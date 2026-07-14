-- Localizing commonly used globals
local pd <const> = playdate
local gfx <const> = playdate.graphics

local animationImagetable = gfx.imagetable.new("images/ship-table-37-30.png")
local paddleWidth = 20
local paddleHeight = 32
local frameTime = 50

function CreatePaddle()
    local animationLoop = gfx.animation.loop.new(frameTime, animationImagetable, true)
    local sprite = gfx.sprite.new(animationLoop:image())
    sprite:setCollideRect(37-paddleWidth, 0, paddleWidth, paddleHeight)
    sprite:moveTo(24, (SCREEN_SIZE.dy - 40) / 2)

    sprite:setGroups(PADDLE_GROUP)
    sprite:setTag(PADDLE_GROUP)
    sprite:setCollidesWithGroups(BALL_GROUP)

    sprite.update = function()
        sprite:setImage(animationLoop:image())
    end

    sprite:add()

    local paddle = {
        sprite = sprite,
        speedMultiplier = 1.5
    }

    return paddle
end

function UpdatePaddle(paddle)

    if pd.isCrankDocked() then
        return
    end

    local halfHeight = paddleHeight / 2
    local topBoundary = 40 + halfHeight
    local bottomBoundary = SCREEN_SIZE.dy - halfHeight
    local crankChange = pd.getCrankChange()
    local crankPosition = pd.getCrankPosition()
    local x, y = paddle.sprite:getPosition()
    if crankPosition <= 180 then
        y = topBoundary + crankPosition * 220/bottomBoundary
    else
        
        y = bottomBoundary - crankPosition % 180 * 220/bottomBoundary
    end

    -- clamp y position
    y = math.max(
        topBoundary,
        math.min(bottomBoundary, y)
    )

    paddle.sprite:moveTo(x, y)



end
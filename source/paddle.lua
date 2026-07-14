-- Localizing commonly used globals
local pd <const> = playdate
local gfx <const> = playdate.graphics

local image = gfx.image.new("images/paddle.png")

local paddleWidth = 12
local paddleHeight = 32

function CreatePaddle()

    local sprite = gfx.sprite.new(image)
    sprite:setCollideRect(0, 0, paddleWidth, paddleHeight)
    sprite:moveTo(24, (SCREEN_SIZE.dy - 40) / 2)

    sprite:setGroups(PADDLE_GROUP)
    sprite:setTag(PADDLE_GROUP)
    sprite:setCollidesWithGroups(BALL_GROUP)

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
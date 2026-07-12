-- Localizing commonly used globals
local gfx <const> = playdate.graphics
local image = gfx.image.new("images/ball.png")
local vector2D <const> = playdate.geometry.vector2D
local ballSize = 8
local wallSpeedModifier = 0.98
local brickSpeedModifier = 1.1
local ballDamage = 1

local function damageBrickBySprite(sprite)
    for i = 1, #Bricks do
        if Bricks[i].sprite == sprite then
            if DamageBrick(Bricks[i], ballDamage) then
                table.remove(Bricks, i)
            end
            break
        end
    end
end

-- Assume image is centered (Anchored 0.5, 0.5)
local function bounce_off_obstacles(ball, newPosition)
    -- temporarily move the ball sprite to the new position to check for collisions
    local oldPosition = ball.position
    ball.sprite:moveTo(newPosition.dx, newPosition.dy)
    local collisions = ball.sprite:overlappingSprites()
    ball.sprite:moveTo(oldPosition.dx, oldPosition.dy)
    
    local hitBrick = false

    for i = 1, #collisions do

        local sprite = collisions[i]

        if sprite:getTag() == BRICK_GROUP then
            
            damageBrickBySprite(sprite)
            hitBrick = true

        elseif sprite:getTag() == PADDLE_GROUP then

            ball.velocity.dx = math.abs(ball.velocity.dx)
            local _, paddleY = sprite:getPosition()
            local offset = (ball.position.dy - paddleY) / 24
            ball.velocity.dy += offset * 2

        end

    end

    -- for now just flip the x velocity
    if hitBrick then
        ball.velocity.dx = -ball.velocity.dx * brickSpeedModifier
    end

    -- check if it has collided with the edge of the screen
    if (newPosition.dx - ballSize/2 < BallBounds[1].dx) then
        ball.velocity.dx = -ball.velocity.dx * wallSpeedModifier
        return true
    elseif (newPosition.dx + ballSize/2 > BallBounds[2].dx) then
        ball.velocity.dx = -ball.velocity.dx * wallSpeedModifier
        return true
    end
    if (newPosition.dy - ballSize/2 < BallBounds[1].dy) then
        ball.velocity.dy = -ball.velocity.dy * wallSpeedModifier
        return true
    elseif (newPosition.dy + ballSize/2 > BallBounds[2].dy) then
        ball.velocity.dy = -ball.velocity.dy * wallSpeedModifier
        return true
    end
    return false
end

function CreateBall(position, velocity)
    local sprite = gfx.sprite.new(image)
    sprite = gfx.sprite.new(image)
    sprite:setCollideRect(0, 0, 8, 8)
    sprite:moveTo(position.dx, position.dy)
    sprite:setGroups(BALL_GROUP)
    sprite:setCollidesWithGroups({BRICK_GROUP, PADDLE_GROUP})
    sprite:add()

    local ball = {
        position = position,
        sprite = sprite,
        velocity = velocity
    }

    return ball
end

function UpdateBall(ball)
    -- to prevent the ball from getting stuck in the ground, check and bounce before actually moving
    local newPosition = vector2D.new(ball.position.dx + ball.velocity.dx, ball.position.dy + ball.velocity.dy)
    -- this will update the velocity of the ball if it would hit a wall at the new position
    bounce_off_obstacles(ball ,newPosition)

    ball.position.dx += ball.velocity.dx
    ball.position.dy += ball.velocity.dy
    ball.sprite:moveTo(ball.position.dx, ball.position.dy)
end
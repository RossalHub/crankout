-- Localizing commonly used globals
local gfx <const> = playdate.graphics
local image = gfx.image.new("images/ball.png")
local vector2D <const> = playdate.geometry.vector2D
local sampleplayer <const> = playdate.sound.sampleplayer

local paddleHitSound = sampleplayer.new("sound/paddle_hit.wav")

local ballSize = 8

local wallSpeedModifier = 0.98
local brickSpeedModifier = 1
local ballDamage = 1

local function damageBrickBySprite(sprite, ball)
    for i = 1, #Bricks do
        if Bricks[i].sprite == sprite then
            OnBrickHit(Bricks[i], ball)
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
    
    for i = 1, #collisions do
        local sprite = collisions[i]

        if sprite:getTag() == BRICK_GROUP then
            damageBrickBySprite(sprite, ball)
            local brickX, brickY = gfx.sprite.getPosition(collisions[i])
            
            if GetBrickCollisionFace(brickX, brickY, ball.position.dx, ball.position.dy) then
                ball.velocity.dx = -ball.velocity.dx * brickSpeedModifier
            else
                ball.velocity.dy = -ball.velocity.dy * brickSpeedModifier
            end
            break
        elseif sprite:getTag() == PADDLE_GROUP then
            ball.velocity.dx = math.abs(ball.velocity.dx)
            local _, paddleY = sprite:getPosition()
            local offset = (ball.position.dy - paddleY) / 24
            ball.velocity.dy += offset * 2 
            ball.velocity.dy += playdate.getCrankChange()/5
            paddleHitSound:play()
            break
        end
    end

    -- check if it has collided with the edge of the screen
    if (newPosition.dx + ballSize/2 > BallBounds[2].dx) then
        ball.velocity.dx = -ball.velocity.dx * wallSpeedModifier
        return true
    end

    if (newPosition.dy - ballSize/2 < BallBounds[1].dy) or
       (newPosition.dy + ballSize/2 > BallBounds[2].dy) 
    then
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
        velocity = velocity,
        damage = ballDamage
    }

    table.insert(Balls, ball)
end

function UpdateBall(ball)
    -- to prevent the ball from getting stuck in the ground, check and bounce before actually moving
    local newPosition = vector2D.new(ball.position.dx + ball.velocity.dx, ball.position.dy + ball.velocity.dy)
    -- this will update the velocity of the ball if it would hit a wall at the new position
    bounce_off_obstacles(ball ,newPosition)

    ball.position.dx += ball.velocity.dx
    ball.position.dy += ball.velocity.dy
    ball.sprite:moveTo(ball.position.dx, ball.position.dy)

    -- ball has gone behind the paddle
    if ball.position.dx < -30 then
        DestroyBall(ball)
    end
end

function DestroyBall(ball)
    gfx.sprite.remove(ball.sprite)
    
    for i = 1, #Balls do
        if Balls[i] == ball then
            table.remove(Balls, i)
            break
        end
    end
end
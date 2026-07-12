
-- Localizing commonly used globals
local gfx <const> = playdate.graphics
local image = gfx.image.new("images/brick.png")
local vector2D <const> = playdate.geometry.vector2D
local sampleplayer <const> = playdate.sound.sampleplayer

local hitSound = sampleplayer.new("sound/brick_hit.wav")
local destroySound = sampleplayer.new("sound/brick_destroy.wav")

local brickWidth = 12
local brickHeight = 25
local brickAngle = 65

function GetBrickCollisionFace(brickX, brickY, ballX, ballY)
    -- return true if the front or back of the brick was hit
    local angle = vector2D.new(brickX - ballX, brickY - ballY)
    local direction = math.abs(math.atan(angle.dy, angle.dx)*(180/math.pi))

    if direction < brickAngle or direction > 180-brickAngle then
        return true
    end
    return false
end

function CreateBrick(position, type)
    local health
    if type == BrickType.Basic then
        health = 1
    elseif type == BrickType.Sturdy then
        health = 2
    elseif type == BrickType.Ball then
        health = 2
    elseif type == BrickType.Tough then
        health = 3
    elseif type == BrickType.Speed then
        health = 4
    elseif type == BrickType.Slow then
        health = 4
    else
        health = 1
    end

    -- eventually will use a different image for each type
    local sprite = gfx.sprite.new(image)
    sprite = gfx.sprite.new(image)
    sprite:setCollideRect(0, 0, 12, 25)
    sprite:moveTo(position.dx, position.dy)
    sprite:setGroups(BRICK_GROUP)
    sprite:setTag(BRICK_GROUP)
    sprite:setCollidesWithGroups(BALL_GROUP)
    sprite:add()


    local brick = {
        maxHealth = health,
        health = health,
        position = position,
        sprite = sprite,
        type = type
    }

    table.insert(Bricks, brick)
end

local function destroyBrick(brick)
    gfx.sprite.remove(brick.sprite)
    BricksDestroyed += 1

    if brick.type == BrickType.Ball then
        -- should randomize the direction eventually
        CreateBall(brick.position, vector2D.new(5, 5))
    end

    for i = 1, #Bricks do
        if Bricks[i] == brick then
            table.remove(Bricks, i)
            break
        end
    end
end

function OnBrickHit(brick, ball)
    -- deal damage to the brick
    brick.health -= ball.damage

    -- apply any effects on the ball
    if brick.type == BrickType.Slow then
        ball.velocity *= 0.75
    elseif brick.type == BrickType.Speed then
        ball.velocity *= 1.3
    end

    -- destroy the brick if it is dead
    if brick.health <= 0 then
        destroySound:play()
        destroyBrick(brick)
        return true
    end
    
    hitSound:play()
    -- if not dead, fade out the sprite to indicate it is damaged
    local image = gfx.sprite.getImage(brick.sprite)
    local fadedImage = image:fadedImage(brick.health/brick.maxHealth, gfx.image.kDitherTypeBayer2x2)
    brick.sprite:setImage(fadedImage)
    return false
end
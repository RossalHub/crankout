
-- Localizing commonly used globals
local gfx <const> = playdate.graphics
local images = {
    gfx.image.new("images/brick1.png"),
    gfx.image.new("images/brick2.png"),
    gfx.image.new("images/brick3.png"),
    gfx.image.new("images/ball_brick.png"),
    gfx.image.new("images/speed_brick.png"),
    gfx.image.new("images/slow_brick.png"),
    gfx.image.new("images/demon_brick.png")
}
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
        health = 1
    elseif type == BrickType.Tough then
        health = 3
    elseif type == BrickType.Speed then
        health = 1
    elseif type == BrickType.Slow then
        health = 1
    else
        health = 1
    end

    -- eventually will use a different image for each type
    local sprite = gfx.sprite.new(images[type])
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
    CreateBrickEffect(brick.position.dx,brick.position.dy)

    if brick.type == BrickType.Ball then
        -- should randomize the direction eventually
        CreateBall(brick.position, vector2D.new(BallMinVelocity, 5))
    elseif brick.type == BrickType.Demon then
        -- hell in a cell
        BrickSpawnTimerRate = 500
        BgDelta = 4
        HardMusic:play(0)
        StartBrickSpawner()
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

local function GetRandomBrickType()
    --1% chance to create demon
    if math.random() < 0.01 then
        return BrickType.Demon
    --20% chance to create gap
    elseif math.random() < 0.20 then 
        return nil 
    end

    -- randomize types
    local roll = math.random(1, 100)
    if roll <= 50 then return BrickType.Basic
    elseif roll <= 70 then return BrickType.Sturdy
    elseif roll <= 80 then return BrickType.Tough
    elseif roll <= 87 then return BrickType.Ball
    elseif roll <= 94 then return BrickType.Speed
    else return BrickType.Slow end
end

-- shifts all existing rows by 1
function ShiftBricksLeft()
    -- iterate backwards when removing items from a table to avoid skipping indices
    for i = #Bricks, 1, -1 do
        local brick = Bricks[i]
        brick.position.dx -= brickWidth
        brick.sprite:moveTo(brick.position.dx, brick.position.dy)

        -- edge case if brick goes too far left
        if brick.position.dx < 120 then
            gfx.sprite.remove(brick.sprite)
            table.remove(Bricks, i)
        end
    end
    BallMinVelocity += 0.25
    BallMinVelocity = clamp(BallMinVelocity, 2, 8)
end

-- spawns new column of bricks on the right side
function SpawnNewBrickColumn()
    ShiftBricksLeft()

    -- spawn at right edge of the screen
    local spawnX = SCREEN_SIZE.dx - brickWidth/2
    
    -- loop through the 8 rows
    for y = 1, BrickRows, 1 do
        local brickY = 40 - brickHeight/2 + y*brickHeight
        local randomType = GetRandomBrickType()
        
        -- spawn a brick if randomType isn't nil
        if randomType ~= nil then
            CreateBrick(vector2D.new(spawnX, brickY), randomType)
        end
    end
end

-- sets up brick timer
local brickSpawnTimer = nil
function StartBrickSpawner()
    if brickSpawnTimer then 
        brickSpawnTimer:remove() 
    end
    
    -- 20,000 milliseconds = 20 seconds
    brickSpawnTimer = playdate.timer.new(BrickSpawnTimerRate, SpawnNewBrickColumn)
    brickSpawnTimer.repeats = true
end
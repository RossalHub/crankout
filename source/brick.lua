
-- Localizing commonly used globals
local gfx <const> = playdate.graphics
local image = gfx.image.new("images/brick.png")
local vector2D <const> = playdate.geometry.vector2D

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

function CreateBrick(x, y)
    local sprite = gfx.sprite.new(image)
    sprite = gfx.sprite.new(image)
    sprite:setCollideRect(0, 0, 12, 25)
    sprite:moveTo(x, y)
    sprite:setGroups(BRICK_GROUP)
    sprite:setTag(BRICK_GROUP)
    sprite:setCollidesWithGroups(BALL_GROUP)
    sprite:add()

    local brick = {
        maxHealth = 2,
        health = 2,
        x = x,
        y = y,
        sprite = sprite
    }

    return brick
end

function DamageBrick(brick, damage)
    brick.health -= damage
    if brick.health <= 0 then
        gfx.sprite.remove(brick.sprite)
        BricksDestroyed += 1
        return true
    end
    local image = gfx.sprite.getImage(brick.sprite)
    local fadedImage = image:fadedImage(brick.health/brick.maxHealth, gfx.image.kDitherTypeBayer2x2)
    brick.sprite:setImage(fadedImage)
    return false
end
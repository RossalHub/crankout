-- Below is a small example program where you can move a circle
-- around with the crank. You can delete everything in this file,
-- but make sure to add back in a playdate.update function since
-- one is required for every Playdate game!
-- =============================================================

-- Importing libraries used for drawCircleAtPoint and crankIndicator
import "CoreLibs/graphics"
import "CoreLibs/ui"

-- Localizing commonly used globals
local pd <const> = playdate
local gfx <const> = playdate.graphics
local vector2D <const> = playdate.geometry.vector2D
local sampleplayer <const> = playdate.sound.sampleplayer


-- Define constants
SCREEN_SIZE = vector2D.new(400, 240)

-- Defining player variables
local playerSize = 10
local playerVelocity = 3
local playerX, playerY = 200, 120


-- Define ball variables
local ballPosition = vector2D.new(50, 50)
local ballVel = vector2D.new(5, 5)
local ballImage = gfx.image.new("images/circle_32x32_black")
local ballSize = vector2D.new(32,32)
local ballBounceSpeedModifier = 0.98
local ballBounceSoundEffect = sampleplayer.new("sound/wall_bounce")


-- Drawing player image
local playerImage = gfx.image.new(32, 32)
gfx.pushContext(playerImage)
    -- Draw outline
    gfx.drawRoundRect(4, 3, 24, 26, 1)
    -- Draw screen
    gfx.drawRect(7, 6, 18, 12)
    -- Draw eyes
    gfx.drawLine(10, 12, 12, 10)
    gfx.drawLine(12, 10, 14, 12)
    gfx.drawLine(17, 12, 19, 10)
    gfx.drawLine(19, 10, 21, 12)
    -- Draw crank
    gfx.drawRect(27, 15, 3, 9)
    -- Draw A/B buttons
    gfx.drawCircleInRect(16, 20, 4, 4)
    gfx.drawCircleInRect(21, 20, 4, 4)
    -- Draw D-Pad
    gfx.drawRect(8, 22, 6, 2)
    gfx.drawRect(10, 20, 2, 6)
gfx.popContext()

-- Defining helper function
local function ring(value, min, max)
	if (min > max) then
		min, max = max, min
	end
	return min + (value - min) % (max - min)
end

-- Assume image is centered (Anchored 0.5, 0.5)
local function bounce_off_walls(position, velocity, size, speedModifier)
    if (position.dx - size.dx/2 < 0) then
        velocity.dx = -velocity.dx * speedModifier
        return true
    elseif (position.dx + size.dx/2 > SCREEN_SIZE.dx) then
        velocity.dx = -velocity.dx * speedModifier
        return true
    end
    if (position.dy - size.dy/2 < 0) then
        velocity.dy = -velocity.dy * speedModifier
        return true
    elseif (position.dy + size.dy/2 > SCREEN_SIZE.dy) then
        velocity.dy = -velocity.dy * speedModifier
        return true
    end
    return false
end
-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.clear()
    -- Draw crank indicator if crank is docked
    if pd.isCrankDocked() then
        pd.ui.crankIndicator:draw()
    else
        -- Calculate velocity from crank angle 
        local crankPosition = pd.getCrankPosition() - 90
        local xVelocity = math.cos(math.rad(crankPosition)) * playerVelocity
        local yVelocity = math.sin(math.rad(crankPosition)) * playerVelocity
        -- Move player
        playerX += xVelocity
        playerY += yVelocity
        -- Loop player position
        playerX = ring(playerX, -playerSize, SCREEN_SIZE.dx + playerSize)
        playerY = ring(playerY, -playerSize, SCREEN_SIZE.dy + playerSize)
    end
    -- Move ball 
    ballPosition.dx += ballVel.dx
    ballPosition.dy += ballVel.dy
    if bounce_off_walls(ballPosition, ballVel, ballSize, ballBounceSpeedModifier) then
        ballBounceSoundEffect:play()
    end


    ----- Draw Stuff -----
    -- Draw text
    gfx.drawTextAligned("Template configured!", 200, 30, kTextAlignment.center)
    -- Draw player
    playerImage:drawAnchored(playerX, playerY, 0.5, 0.5)
    -- Draw ball 
    ballImage:drawAnchored(ballPosition.dx, ballPosition.dy, 0.5, 0.5)

end

-- Below is a small example program where you can move a circle
-- around with the crank. You can delete everything in this file,
-- but make sure to add back in a playdate.update function since
-- one is required for every Playdate game!
-- =============================================================

-- Importing libraries used for drawCircleAtPoint and crankIndicator
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/Object"
import "CoreLibs/sprites"

import "brick.lua"
import "ball.lua"
-- Localizing commonly used globals
local pd <const> = playdate
local gfx <const> = playdate.graphics
local vector2D <const> = playdate.geometry.vector2D
local sampleplayer <const> = playdate.sound.sampleplayer


-- Define constants
SCREEN_SIZE = vector2D.new(400, 240)
Font = playdate.graphics.font.new("fonts/yoster")
BALL_GROUP = 1
BRICK_GROUP = 2

-- Defining player variables
local playerSize = 10
local playerVelocity = 3
local playerX, playerY = 24, SCREEN_SIZE.dy / 2


-- Define ball variables
BallBounds = {vector2D.new(0,40), SCREEN_SIZE} -- Used as walls for ball

-- load in Bricks
local brickWidth = 12
local brickHeight = 25

local brickRows = 8
local brickColumns = 4

BricksTotal = brickRows*brickColumns
BricksDestroyed = 0

Bricks = {}

for x = 1, brickColumns, 1 do
    for y = 1, brickRows, 1 do 
        local brickX = SCREEN_SIZE.dx - brickWidth/2 - brickWidth*brickColumns + x*brickWidth
        local brickY = 40- brickHeight/2 + y*brickHeight
        table.insert(Bricks, CreateBrick(brickX, brickY))
    end
end

-- UI
local UIBoxImage = gfx.image.new(SCREEN_SIZE.dx, SCREEN_SIZE.dy)
-- Drawing a box with code
local UIBoxHeight = 38
local UIBoxLineWidth = 4
gfx.pushContext(UIBoxImage)
    gfx.setLineWidth(UIBoxLineWidth)
    -- Horizontal Lines
    gfx.drawLine(0, UIBoxLineWidth/2, SCREEN_SIZE.dx, UIBoxLineWidth/2)
    gfx.drawLine(0, UIBoxHeight, SCREEN_SIZE.dx, UIBoxHeight)
    -- Verticle Lines
    gfx.drawLine(UIBoxLineWidth/2,0,UIBoxLineWidth/2,UIBoxHeight)
    gfx.drawLine(SCREEN_SIZE.dx-UIBoxLineWidth/2,0,SCREEN_SIZE.dx-UIBoxLineWidth/2,UIBoxHeight)
gfx.popContext()

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

-- Inverts game colour
playdate.display.setInverted(true) 

local ball = CreateBall(vector2D.new(50, 100), vector2D.new(5, 5))

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.clear()

    UpdateBall(ball)
    -- Draw crank indicator if crank is docked
    if not pd.isCrankDocked() then
        -- Moves the paddle based on crank speed
        local crankChange = pd.getCrankChange()

        playerY += crankChange * playerVelocity

        -- Clamps to the screen bounds
        local halfHeight = 16 -- note: player image is currently 32px tall, so it should be updated once the paddle sprite is added. 
        playerY = math.max(halfHeight, math.min(SCREEN_SIZE.dy - halfHeight, playerY))
    end

    ----- Draw Stuff -----
    gfx.sprite.update()
    if pd.isCrankDocked() then
        pd.ui.crankIndicator:draw()
    end
    -- Draw text
    -- gfx.drawTextAligned("Template configured!", 200, 30, kTextAlignment.center)
    -- Draw player
    playerImage:drawAnchored(playerX, playerY, 0.5, 0.5)
    -- Draw UI
    UIBoxImage:draw(0,0)
    playdate.graphics.drawText(string.format("Blocks Destroyed: %d", BricksDestroyed), 10, 10)
    playdate.graphics.drawText(string.format("Blocks Remaining: %d", BricksTotal-BricksDestroyed), 200, 10)
end

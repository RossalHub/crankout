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
import "paddle.lua"
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
PADDLE_GROUP = 4

-- Define Enums
BrickType = {
    Basic = 1, -- one hit, nothing special
    Sturdy = 2, -- 2 hits
    Tough = 3, -- 3 hits
    Ball = 4, -- spawns a ball when destroyed, 2 hits
    Speed = 5, -- gives the ball a large speed increase, 4 hits
    Slow = 6, -- slows down the ball when hit, 4 hits
}


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
        CreateBrick(vector2D.new(brickX, brickY), BrickType.Ball)
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

-- Defining helper function
local function ring(value, min, max)
	if (min > max) then
		min, max = max, min
	end
	return min + (value - min) % (max - min)
end

-- Inverts game colour
playdate.display.setInverted(true) 

Balls = {}

CreateBall(vector2D.new(50, 100), vector2D.new(3, 5))
CreateBall(vector2D.new(50, 100), vector2D.new(4, 0))
CreateBall(vector2D.new(50, 100), vector2D.new(5, -5))

local paddle = CreatePaddle()

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.clear()

    for i = 1, #Balls do
        UpdateBall(Balls[i])
    end
    -- Draw crank indicator if crank is docked
    UpdatePaddle(paddle)

    ----- Draw Stuff -----
    gfx.sprite.update()
    if pd.isCrankDocked() then
        pd.ui.crankIndicator:draw()
    end
    -- Draw text
    -- gfx.drawTextAligned("Template configured!", 200, 30, kTextAlignment.center)
    -- Draw player
    -- Draw UI
    UIBoxImage:draw(0,0)
    playdate.graphics.drawText(string.format("Blocks Destroyed: %d", BricksDestroyed), 10, 10)
    playdate.graphics.drawText(string.format("Blocks Remaining: %d", BricksTotal-BricksDestroyed), 200, 10)
end

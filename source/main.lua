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
import "CoreLibs/animation"
import "CoreLibs/timer"

import "brick.lua"
import "ball.lua"
import "paddle.lua"
import "brick_effect.lua"
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

BrickRows = 8
BrickColumns = 4

BricksTotal = BrickRows*BrickColumns
BricksDestroyed = 0

Bricks = {}

for x = 1, BrickColumns, 1 do
    for y = 1, BrickRows, 1 do 
        local brickX = SCREEN_SIZE.dx - brickWidth/2 - brickWidth*BrickColumns + x*brickWidth
        local brickY = 40- brickHeight/2 + y*brickHeight
        CreateBrick(vector2D.new(brickX, brickY), math.random(6))
    end
end

-- UI
local UIBoxImage = gfx.image.new(SCREEN_SIZE.dx, SCREEN_SIZE.dy)
-- Drawing a box with code
local UIBoxHeight = 38
local UIBoxLineWidth = 4

gfx.setBackgroundColor(gfx.kColorBlack)
gfx.setColor(gfx.kColorWhite)

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

Balls = {}
-- Create balls with no velocity
function CreateStarterBalls()
    CreateBall(vector2D.new(50, 100), vector2D.new(0, 0))
    CreateBall(vector2D.new(50, 100), vector2D.new(0, 0))
    CreateBall(vector2D.new(50, 100), vector2D.new(0, 0))
end
-- Add velocity to balls
function LaunchBalls()
    Balls[1].velocity = vector2D.new(3, 5)
    Balls[2].velocity = vector2D.new(4, 0)
    Balls[3].velocity = vector2D.new(5, -5)
end
-- Start the game 
function StartGame()
    LaunchBalls()
    StartBrickSpawner()
end

local playing_game = false
local paddle = CreatePaddle()
CreateStarterBalls()

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.clear()

    for i = 1, #Balls do
        if Balls[i] ~= nil then
            UpdateBall(Balls[i])
        end
    end
    
    UpdatePaddle(paddle)

    playdate.timer.updateTimers()

    ----- Draw Stuff -----
    gfx.sprite.update()
    -- Draw crank indicator if crank is docked
    if pd.isCrankDocked() then
        pd.ui.crankIndicator:draw()
    elseif not playing_game then -- Start Game
        playing_game = true
        StartGame()
    end
   
    UIBoxImage:draw(0,0)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("Blocks Destroyed: %d", BricksDestroyed), 10, 10)
    gfx.drawText(string.format("Balls in play: %d", #Balls), 200, 10)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

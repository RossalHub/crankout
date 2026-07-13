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

-- helper to generate the initial wall of bricks
function GenerateBricks()
    for x = 1, BrickColumns, 1 do
        for y = 1, BrickRows, 1 do 
            local brickX = SCREEN_SIZE.dx - brickWidth/2 - brickWidth*BrickColumns + x*brickWidth
            local brickY = 40- brickHeight/2 + y*brickHeight
            CreateBrick(vector2D.new(brickX, brickY), math.random(6))
        end
    end
end

-- generate first set of bricks
GenerateBricks()

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

-- game states
local playing_game = false
local game_over = false
local paddle = CreatePaddle()
CreateStarterBalls()

-- checks if the player ran out of balls, or if all balls have stalled
function CheckGameOver()
    -- end if no balls are left
    if #Balls == 0 then return true end
    
    -- check if all balls have stopped moving
    local all_stopped = true
    for i = 1, #Balls do
        -- threshold of 0.1
        if math.abs(Balls[i].velocity.dx) > 0.1 or math.abs(Balls[i].velocity.dy) > 0.1 then
            all_stopped = false
            break
        end
    end
    
    return all_stopped
end

-- clears board and restarts
function ResetGame()
    -- clear existing balls
    for i = #Balls, 1, -1 do
        DestroyBall(Balls[i])
    end
    
    -- clear existing bricks
    for i = #Bricks, 1, -1 do
        gfx.sprite.remove(Bricks[i].sprite)
        table.remove(Bricks, i)
    end
    
    -- reset stats and timers
    BricksDestroyed = 0
    if BrickSpawnTimer then 
        BrickSpawnTimer:remove() 
        BrickSpawnTimer = nil
    end
    
    -- repopulate the board
    GenerateBricks()
    CreateStarterBalls()
    
    -- reset states
    playing_game = false
    game_over = false
end

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.clear()

    if game_over then
        -- keep drawing frozen game behind the UI
        gfx.sprite.update()
        UIBoxImage:draw(0,0)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(string.format("Blocks Destroyed: %d", BricksDestroyed), 10, 10)
        gfx.drawText(string.format("Balls in play: %d", #Balls), 200, 10)
        
        -- dark overlay box behind the gameover text
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(90, 85, 220, 70)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawRect(90, 85, 220, 70)
        
        -- game over text
        gfx.drawText("*GAME OVER*", 150, 100)
        gfx.drawText("Press A to Try Again!", 115, 125)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
        -- A button to reset the game
        if playdate.buttonJustPressed(playdate.kButtonA) then
            ResetGame()
        end
        
        -- return early so physics don't update while game is over
        return
    end

    for i = 1, #Balls do
        if Balls[i] ~= nil then
            UpdateBall(Balls[i])
        end
    end
    
    UpdatePaddle(paddle)

    playdate.timer.updateTimers()
    
    -- check for game over after updating physics
    if playing_game and CheckGameOver() then
        game_over = true
    end

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

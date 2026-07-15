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
Font = gfx.font.new("fonts/yoster")
BALL_GROUP = 1
BRICK_GROUP = 2
PADDLE_GROUP = 4

-- Define Enums
BrickType = {
    Basic = 1, -- one hit, nothing special
    Sturdy = 2, -- 2 hits
    Tough = 3, -- 3 hits
    Ball = 4, -- spawns a ball when destroyed, 1 hit
    Speed = 5, -- gives the ball a large speed increase, 1 hit
    Slow = 6, -- slows down the ball when hit, 1 hit
}

local logoImage = gfx.image.new("images/logo.png")


-- Define ball variables
BallBounds = {vector2D.new(0,40), SCREEN_SIZE} -- Used as walls for ball
BallMinVelocity = 2

-- load in Bricks
local brickWidth = 12
local brickHeight = 25

BrickRows = 8
BrickColumns = 4

BricksTotal = BrickRows*BrickColumns
BricksDestroyed = 0

Bricks = {}

-- leaderboard setup
-- load saved scores or create a default table of 5 zeros
Leaderboard = playdate.datastore.read("leaderboard") or {0, 0, 0, 0, 0}
local latestScoreRank = nil

-- checks final score against the leaderboard and saves if it's in the top 5
local function UpdateLeaderboard(finalScore)
    latestScoreRank = nil
    if finalScore == 0 then return end
    
    for i = 1, 5 do
        if finalScore > Leaderboard[i] then
            table.insert(Leaderboard, i, finalScore)
            table.remove(Leaderboard, 6) -- keep table at 5 entries
            latestScoreRank = i
            playdate.datastore.write(Leaderboard, "leaderboard")
            break
        end
    end
end

-- helper to draw the leaderboard cleanly in multiple places
local function DrawLeaderboard(y, showNewFlag)
    gfx.drawTextAligned("*HIGH SCORES*", 200, y, kTextAlignment.center)
    local startY = y + 25
    
    for i = 1, 5 do
        local rowY = startY + ((i - 1) * 20)
        -- rank on the left
        gfx.drawTextAligned(tostring(i) .. ".", 150, rowY, kTextAlignment.left)
        -- score on the right
        gfx.drawTextAligned(tostring(Leaderboard[i]), 230, rowY, kTextAlignment.right)
        
        -- NEW! flag if applicable
        if showNewFlag and latestScoreRank == i then
            gfx.drawTextAligned("NEW!", 245, rowY, kTextAlignment.left)
        end
    end
end

function GenerateBricks(xOffset)
    xOffset = xOffset or 0
    for x = 1, BrickColumns, 1 do
        for y = 1, BrickRows, 1 do 
            local brickX = SCREEN_SIZE.dx - brickWidth/2 - brickWidth*BrickColumns + x*brickWidth + xOffset
            local brickY = 40 - brickHeight/2 + y*brickHeight
            CreateBrick(vector2D.new(brickX, brickY), math.random(6))
        end
    end
end

-- background
BgOffset = 0
local bgSpriteTable = gfx.imagetable.new("images/stars-table-400-200.png")
local bgAnimationLoop = gfx.animation.loop.new(250, bgSpriteTable, true)
local function drawBg(x, y, width, height)
    bgAnimationLoop:draw(-BgOffset%400, 40)
    bgAnimationLoop:draw(-BgOffset%400-400, 40)
    BgOffset += 1
end

gfx.sprite.setBackgroundDrawingCallback(drawBg)

-- UI
local UIBoxImage = gfx.image.new(SCREEN_SIZE.dx, SCREEN_SIZE.dy)
-- Drawing a box with code
local UIBoxHeight = 39 -- Was 38
local UIBoxLineWidth = 2 --Was 4

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

Balls = {}
-- Create balls with no velocity
function CreateStarterBalls()
    CreateBall(vector2D.new(50, 100), vector2D.new(0, 0))
    CreateBall(vector2D.new(50, 100), vector2D.new(0, 0))
    CreateBall(vector2D.new(50, 100), vector2D.new(0, 0))
end

function LaunchBalls()
    if Balls[1] then Balls[1].velocity = vector2D.new(3, 5) end
    if Balls[2] then Balls[2].velocity = vector2D.new(4, 0) end
    if Balls[3] then Balls[3].velocity = vector2D.new(5, -5) end
end

-- game states
local title_screen = true
local intro_animating = false
local playing_game = false
local game_over = false

local paddle = nil
local introTimer = nil

-- animation position offsets
local uiYOffset = -42      
local paddleXOffset = -50  
local brickXOffset = 100   

-- track animation
local introProgress = 0

-- lerp animation
local function lerp(start, finish, t)
    return start + (finish - start) * t
end

function clamp(value, min, max)
    return math.max(math.min(value, max), min)
end

function StartIntroAnimation()
    title_screen = false
    intro_animating = true
    introProgress = 0
    
    -- instantiate objects slightly off-screen
    paddle = CreatePaddle()
    paddle.sprite:moveTo(-30, 120) 
    
    GenerateBricks(brickXOffset)   
    
    -- create timer
    introTimer = playdate.timer.new(500, 0, 1)
    introTimer.easingFunction = playdate.easingFunctions.outCubic
    
    introTimer.updateCallback = function(timer)
        introProgress = timer.value
    end
    
    -- trigger StartGame automatically when timer finishes
    introTimer.timerEndedCallback = function()
        StartGame()
    end
end

function StartGame()
    intro_animating = false
    playing_game = true
    CreateStarterBalls()
    LaunchBalls()
    StartBrickSpawner()
end

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
    BallMinVelocity = 2
    for i = #Balls, 1, -1 do DestroyBall(Balls[i]) end
    for i = #Bricks, 1, -1 do
        gfx.sprite.remove(Bricks[i].sprite)
        table.remove(Bricks, i)
    end
    if paddle and paddle.sprite then
        gfx.sprite.remove(paddle.sprite)
    end
    
    -- reset stats and timers
    BricksDestroyed = 0
    latestScoreRank = nil -- clear NEW! flag for the next round
    
    if BrickSpawnTimer then 
        BrickSpawnTimer:remove() 
        BrickSpawnTimer = nil
    end
    
    -- restart animation on retry
    uiYOffset = -42
    paddleXOffset = -50
    brickXOffset = 100
    StartIntroAnimation()
    game_over = false
end

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.clear()

    -- title screen state
    if title_screen then
        -- updates the background so that the stars are also in the title screen
        gfx.sprite.update()

        if logoImage then
            local w, h = logoImage:getSize()
            logoImage:draw(200 - w/2, 10) 
        else
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            gfx.drawTextAligned("*CRANKOUT*", 200, 30, kTextAlignment.center)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
        end
        
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        DrawLeaderboard(85, false) 
        
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
        if pd.isCrankDocked() then
            pd.ui.crankIndicator:draw()
        else
            StartIntroAnimation()
        end
        return
    end

    -- intro animating state
    if intro_animating then
        playdate.timer.updateTimers()
        
        -- lerp offset to 0
        local currentUiY = lerp(-42, 0, introProgress)
        local currentPaddleX = lerp(-30, 30, introProgress) 
        local currentBrickXShift = lerp(100, 0, introProgress)
        
        -- apply animation to the paddle
        if paddle and paddle.sprite then
            local _, py = paddle.sprite:getPosition()
            paddle.sprite:moveTo(currentPaddleX, py)
        end
        
        -- apply animation to the bricks
        for i = 1, #Bricks do
            -- determine the correct column based on how GenerateBricks populates the table
            local col = math.floor((i - 1) / BrickRows) + 1
            local nativeX = SCREEN_SIZE.dx - brickWidth/2 - brickWidth*BrickColumns + col*brickWidth
            
            Bricks[i].position.dx = nativeX + currentBrickXShift
            Bricks[i].sprite:moveTo(Bricks[i].position.dx, Bricks[i].position.dy)
        end
        
        -- draw sliding structures
        gfx.sprite.update()
        UIBoxImage:draw(0, currentUiY)
        
        return
    end

    -- game over state
    if game_over then
        -- keep drawing frozen game behind the UI
        gfx.sprite.update()
        UIBoxImage:draw(0,0)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(string.format("Blocks Destroyed: %d", BricksDestroyed), 10, 10)
        gfx.drawText(string.format("Balls in play: %d", #Balls), 200, 10)
        
        -- dark overlay box behind the gameover and leaderboard text
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(80, 20, 240, 200)
        gfx.setColor(gfx.kColorWhite)
        gfx.setLineWidth(2)
        gfx.drawRect(80, 20, 240, 200)
        
        -- game over text
        gfx.drawTextAligned("*GAME OVER*", 200, 30, kTextAlignment.center)
        
        -- draw leaderboard with new! flag enabled
        DrawLeaderboard(65, true)
        
        gfx.drawTextAligned("Press A to Try Again!", 200, 195, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
        -- A button to reset the game
        if playdate.buttonJustPressed(playdate.kButtonA) then
            ResetGame()
        end
        
        -- return early so physics don't update while game is over
        return
    end

    -- gameplay state
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
        -- trigger leaderboard check right when the game ends
        UpdateLeaderboard(BricksDestroyed)
    end

    ----- Draw Stuff -----
    gfx.sprite.update()
    UIBoxImage:draw(0,0)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(string.format("Blocks Destroyed: %d", BricksDestroyed), 10, 10)
    gfx.drawText(string.format("Balls in play: %d", #Balls), 200, 10)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

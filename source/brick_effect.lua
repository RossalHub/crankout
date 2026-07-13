
-- Localizing commonly used globals
local gfx <const> = playdate.graphics

local frameTime = 50
local totalFrames = 10
local animationImagetable = gfx.imagetable.new("images/brick_explosion_white-table-48-50.png")

-- return a value between 0 and 1 representing fade amount
local function get_animation_fade_amount(frame)
    return (totalFrames-frame)/totalFrames
end

function CreateBrickEffect(x, y)
    local animationLoop = gfx.animation.loop.new(frameTime, animationImagetable, false)
    local animatedSprite = gfx.sprite.new(animationLoop:image())
    animatedSprite:moveTo(x, y)
    animatedSprite:add()

    -- Set new rules for the update function
    animatedSprite.update = function()
        animatedSprite:setImage(animationLoop:image():fadedImage(get_animation_fade_amount(animationLoop.frame), gfx.image.kDitherTypeBayer2x2))
        -- Removes the sprite when the animation finished
        if not animationLoop:isValid() then
            animatedSprite:remove()
        end
    end

end







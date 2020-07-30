function createSheet(image, width, height)
    local sheet = {}
    sheet.spriteSheet = image
    sheet.quads = {}
 
    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(sheet.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end
 
    return sheet
end

function createGem()
    return {color = math.random(1, 4), x = borderX + 96, y = borderY, fall = true}
end

function drawSheet(sheet, idx, x, y)
    love.graphics.draw(sheet.spriteSheet, sheet.quads[idx], x, y)
end

function love.load()
    math.randomseed(os.time())
    love.window.setTitle("Gemfall")

    border = love.graphics.newImage("Border.png")
    borderX = 272
    borderY = 28
    gemSheet = createSheet(love.graphics.newImage("Gems.png"), 32, 32)
    gemCircle = love.graphics.newImage("GemCircle.png")

    gems = {}
    currentGem = nil
    currentGem2 = nil
    isFalling = false
    score = 0
    difficulty = 0
    gameOver = false
end

function love.update(delta)
    if gameOver then
        return
    end

    if not currentGem and not isFalling then
        currentGem = createGem()
        currentGem2 = createGem()
        currentGem2.x = currentGem.x + 32

        for idx, gem in ipairs(gems) do
            if (gem.x == currentGem.x and gem.y == currentGem.y) or (gem.x == currentGem2.x and gem.y == currentGem2.y) then
                gameOver = true
                return
            end
        end

        table.insert(gems, currentGem)
        table.insert(gems, currentGem2)
    end

    needCheck = false
    isFalling = false

    for idx, gem in ipairs(gems) do
        if gem.fall then
            if gem.fast then
                gem.y = gem.y + 800 * delta
            elseif gem == currentGem or gem == currentGem2 then
                gem.y = gem.y + (100 + difficulty) * delta
            else
                gem.y = gem.y + 100 * delta
            end

            if gem.y >= borderY + 480 then
                gem.y = borderY + 480
                gem.fall = false
                gem.fast = false
                needCheck = true

                if gem == currentGem or gem == currentGem2 then
                    currentGem = nil
                    currentGem2 = nil
                end
            end

            if gem.fall then
                for idx, gem2 in ipairs(gems) do
                    if gem2 ~= gem and not gem2.fall and gem.x == gem2.x and gem.y >= gem2.y - 32 then
                        gem.y = gem2.y - 32
                        gem.fall = false
                        gem.fast = false
                        needCheck = true
        
                        if gem == currentGem or gem == currentGem2 then
                            currentGem = nil
                            currentGem2 = nil
                        end

                        break
                    elseif gem ~= currentGem and gem ~= currentGem2 then
                        isFalling = true
                    end
                end
            end
        end
    end

    if needCheck then
        checkGems()
    end
end

function checkGem(gem)
    for idx, gem2 in ipairs(gems) do
        if not gemGroups[gem2] and gem.color == gem2.color and gem.x == gem2.x then
            if gem.y == gem2.y - 32 or gem.y == gem2.y + 32 then
                gemGroups[gem2] = gemGroups[gem]
                table.insert(gemGroups[gem2], gem2)
                checkGem(gem2)
            end
        end

        if not gemGroups[gem2] and gem.color == gem2.color and gem.y == gem2.y then
            if gem.x == gem2.x - 32 or gem.x == gem2.x + 32 then
                gemGroups[gem2] = gemGroups[gem]
                table.insert(gemGroups[gem2], gem2)
                checkGem(gem2)
            end
        end
    end
end

function checkGems()
    gemGroups = {}

    for idx, gem in ipairs(gems) do
        if not gemGroups[gem] then
            gemGroups[gem] = {}
            table.insert(gemGroups[gem], gem)
            checkGem(gem)
        end
    end

    removed = false
    gems = {}
    for gem, group in pairs(gemGroups) do
        if #group < 3 then
            table.insert(gems, gem)
        else
            score = score + #group
            removed = true
        end
    end

    if removed then
        difficulty = difficulty + 2
        for idx, gem in ipairs(gems) do
            if gem ~= currentGem and gem ~= currentGem2 then
                gem.fall = true
            end
        end
        isFalling = true
    end
end

function love.draw()
    love.graphics.print(score, borderX - 200, borderY, 0, 4, 4)
    love.graphics.draw(border, borderX, borderY)
    for idx, gem in ipairs(gems) do
        love.graphics.draw(gemCircle, gem.x, gem.y)
        drawSheet(gemSheet, gem.color, gem.x, gem.y)
    end

    if gameOver then
        love.graphics.print("GAME OVER", borderX - 200, borderY + 64, 0, 4, 4)
    end
end

function checkCanMove(gem, right)
    if right then
        for idx, gem2 in ipairs(gems) do
            if gem2 ~= currentGem and gem2 ~= currentGem2 and gem.x == gem2.x - 32 and gem.y > gem2.y - 32 and gem.y < gem2.y + 32 then
                canMove = false
                break
            end
        end
    else
        for idx, gem2 in ipairs(gems) do
            if gem2 ~= currentGem and gem2 ~= currentGem2 and currentGem.x == gem2.x + 32 and gem.y > gem2.y - 32 and gem.y < gem2.y + 32 then
                canMove = false
                break
            end
        end
    end
end

function love.keypressed(key)
    if not currentGem then return end

    if key == "right" then
        canMove = currentGem.x < borderX + 192 and currentGem2.x < borderX + 192

        if canMove then
            checkCanMove(currentGem, true)
            checkCanMove(currentGem2, true)
        end

        if canMove then
            currentGem.x = currentGem.x + 32
            currentGem2.x = currentGem2.x + 32
        end
    end

    if key == "left" then
        canMove = currentGem.x > borderX + 32 and currentGem2.x > borderX + 32

        if canMove then
            checkCanMove(currentGem, false)
            checkCanMove(currentGem2, false)
        end

        if canMove then
            currentGem.x = currentGem.x - 32
            currentGem2.x = currentGem2.x - 32
        end
    end

    if key == "up" then
        if currentGem2.x == currentGem.x + 32 then
            currentGem2.x = currentGem.x
            currentGem2.y = currentGem.y + 32
        elseif currentGem2.y == currentGem.y + 32 then
            canMove = currentGem.x > borderX + 32
            checkCanMove(currentGem, false)
            if canMove then
                currentGem2.x = currentGem.x - 32
                currentGem2.y = currentGem.y
            end
        elseif currentGem2.x == currentGem.x - 32 then
            currentGem2.x = currentGem.x
            currentGem2.y = currentGem.y - 32
        elseif currentGem2.y == currentGem.y - 32 then
            canMove = currentGem.x < borderX + 192
            checkCanMove(currentGem, true)
            if canMove then
                currentGem2.x = currentGem.x + 32
                currentGem2.y = currentGem.y
            end
        end
    end

    if key == "down" then
        currentGem.fast = true
        currentGem2.fast = true
    end
 end
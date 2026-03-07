--[[ 
    + spaced side buttons & main island side button border = green
    + walk speed slider at bottom
    + paused teleporting during lasso/minigame events
    + separate Auto Load UW button (independent 60s cycle)
    + Auto Teleport Custom (Input custom minimum strength)
    + FIXED: Reopen button no longer opens when dragged
    + WEATHER NOTIFIER: Bypasses Roblox Volume = 0 and sends Windows/In-Game alerts
    + UI FIX: Fixed chunky/weird text on the weather tick buttons
    + WEATHER UPDATE: Added Rain, Thunderstorm, Snowy, and Valentines to the grid!
    + NEW: Custom Pet Notifier (Alerts you using the volume-bypass system when a strong pet spawns)
    + UI LAYOUT FIX: Changed to a clean 2-Column layout to prevent it from being too tall!
    + UI SCALE FIX: Reduced overall menu size by exactly 25% for a compact footprint.
    + UI POS FIX: Reopen button now spawns in the bottom right corner by default.
--]]

local player = game.Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local theme = {
    Background = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(26, 148, 255),
    Success = Color3.fromRGB(61, 179, 98),
    Danger = Color3.fromRGB(170, 37, 46),
    Text = Color3.new(1, 1, 1),
    Font = Enum.Font.SourceSansBold
}

-- Dictionary to store active weathers 
local TargetWeathers = {}
local weatherDisplayNames = 
    {["Rain"] = "Rain",
    ["Thunderstorm"] = "Thunderstorm",["AuroraBorealis"] = "Aurora",
    ["CosmicShower"] = "Cosmic Shower",["Eruption"] = "Volcano",
    ["Underwater"] = "Underwater",
    ["Sandstorm"] = "Sandstorm",["Snowy"] = "Snowy",
    ["Valentines"] = "Valentines",["Blizzard"] = "Blizzard",
    ["Gravebound"] = "Gravebound"
}
-- Initialize all to true by default
for weatherId, _ in pairs(weatherDisplayNames) do
    TargetWeathers[weatherId] = true
end

---------------------------------------------------------------------
-- ROBUST NOTIFICATION HANDLER (OS Sound Bypass)
---------------------------------------------------------------------
local function sendOSNotification(title, text)
    if type(messagebox) == "function" then
        task.spawn(function()
            pcall(function() messagebox(text, title, 64) end)
        end)
    end

    task.spawn(function()
        pcall(function()
            local gameSettings = UserSettings():GetService("UserGameSettings")
            local originalVolume = gameSettings.MasterVolume
            
            if originalVolume == 0 then
                gameSettings.MasterVolume = 0.5 
            end
            
            local sound = Instance.new("Sound", workspace)
            sound.SoundId = "rbxassetid://4590657391" -- Clean ping sound
            sound.Volume = 3
            sound:Play()
            
            task.delay(2.5, function()
                if originalVolume == 0 then
                    gameSettings.MasterVolume = 0 
                end
                sound:Destroy()
            end)
        end)
    end)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 10,
        })
    end)
end

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local screenGui = Instance.new("ScreenGui", guiParent)
screenGui.Name = "TeleportGUI_Sirius"
screenGui.ResetOnSpawn = false

local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                     startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main Frame (25% Smaller: 420x285)
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 420, 0, 285)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -142)
mainFrame.BackgroundColor3 = theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
makeDraggable(mainFrame)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 9)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 22)
title.Text = "Teleport GUI Custom"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = theme.Text
title.Font = theme.Font
title.TextSize = 14
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 9)

local closeButton = Instance.new("TextButton", title)
closeButton.Size = UDim2.new(0, 22, 1, 0)
closeButton.Position = UDim2.new(1, -22, 0, 0)
closeButton.Text = "X"
closeButton.BackgroundTransparency = 1
closeButton.TextColor3 = theme.Danger
closeButton.TextSize = 14

local reopenButton = Instance.new("TextButton", screenGui)
reopenButton.Size = UDim2.new(0, 112, 0, 22)
-- Placed in the bottom right corner (with 20px padding from the edges)
reopenButton.Position = UDim2.new(1, -132, 1, -42)
reopenButton.Text = "Open Teleport GUI"
reopenButton.BackgroundColor3 = theme.Background
reopenButton.TextColor3 = theme.Text
reopenButton.Font = theme.Font
reopenButton.TextSize = 11
reopenButton.Visible = false
reopenButton.AutoButtonColor = false
makeDraggable(reopenButton)
Instance.new("UICorner", reopenButton).CornerRadius = UDim.new(0, 6)
local reopenStroke = Instance.new("UIStroke", reopenButton)
reopenStroke.Color = theme.Danger
reopenStroke.Thickness = 1
reopenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    reopenButton.Visible = true
end)

local rStartPos, rHasDragged
reopenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rStartPos = input.Position
        rHasDragged = false
    end
end)
reopenButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and rStartPos then
        if (input.Position - rStartPos).Magnitude > 5 then
            rHasDragged = true
        end
    end
end)
reopenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not rHasDragged then
            mainFrame.Visible = true
            reopenButton.Visible = false
        end
        rStartPos = nil
    end
end)

local function styleButton(text, pos, color, customWidth)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0, customWidth or 150, 0, 30)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = theme.Font
    btn.TextSize = 12
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = color
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return btn
end

local function styleSideButton(text, pos, color)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    btn.TextColor3 = theme.Text
    btn.Font = theme.Font
    btn.TextSize = 11
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = color
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return btn
end

---------------------------------------------------------------------
-- TWO COLUMN LAYOUT (25% Smaller Coordinates)
---------------------------------------------------------------------

-- LEFT COLUMN
local petNotifButton = styleButton("Custom Pet Notifier: OFF", UDim2.new(0, 15, 0, 30), theme.Danger, 188)
local weatherButton = styleButton("Rare Weather Notifier: OFF", UDim2.new(0, 15, 0, 71), theme.Danger, 188)

local weatherTickFrame = Instance.new("Frame", mainFrame)
weatherTickFrame.Size = UDim2.new(0, 188, 0, 120)
weatherTickFrame.Position = UDim2.new(0, 15, 0, 112)
weatherTickFrame.BackgroundTransparency = 1

local gridLayout = Instance.new("UIGridLayout", weatherTickFrame)
gridLayout.CellSize = UDim2.new(0, 88, 0, 17) 
gridLayout.CellPadding = UDim2.new(0, 8, 0, 3)
gridLayout.SortOrder = Enum.SortOrder.Name

for weatherId, displayName in pairs(weatherDisplayNames) do
    local tickBtn = Instance.new("TextButton", weatherTickFrame)
    tickBtn.Name = displayName 
    tickBtn.Text = "✅ " .. displayName
    tickBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tickBtn.TextColor3 = theme.Success
    tickBtn.Font = theme.Font
    tickBtn.TextSize = 11 
    tickBtn.AutoButtonColor = false
    Instance.new("UICorner", tickBtn).CornerRadius = UDim.new(0, 3)
    
    local strk = Instance.new("UIStroke", tickBtn)
    strk.Color = theme.Success
    strk.Thickness = 1
    strk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
    
    tickBtn.MouseButton1Click:Connect(function()
        TargetWeathers[weatherId] = not TargetWeathers[weatherId]
        if TargetWeathers[weatherId] then
            tickBtn.Text = "✅ " .. displayName
            tickBtn.TextColor3 = theme.Success
            strk.Color = theme.Success
        else
            tickBtn.Text = "❌ " .. displayName
            tickBtn.TextColor3 = theme.Danger
            strk.Color = theme.Danger
        end
    end)
end

-- RIGHT COLUMN
local tpButton = styleButton("Teleport to Strongest Pet", UDim2.new(0, 218, 0, 30), Color3.new(1,1,1))
local autoAnyButton = styleButton("Auto Teleport (All)", UDim2.new(0, 218, 0, 71), theme.Danger)
local autoCustomButton = styleButton("Auto Teleport Custom", UDim2.new(0, 218, 0, 112), theme.Danger)

local minStrengthInput = Instance.new("TextBox", mainFrame)
minStrengthInput.Size = UDim2.new(0, 150, 0, 22)
minStrengthInput.Position = UDim2.new(0, 218, 0, 153)
minStrengthInput.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
minStrengthInput.TextColor3 = Color3.new(1, 1, 1)
minStrengthInput.Font = theme.Font
minStrengthInput.TextSize = 11
minStrengthInput.PlaceholderText = "Min Strength (3000)"
minStrengthInput.Text = "3000"
minStrengthInput.ClearTextOnFocus = false
Instance.new("UICorner", minStrengthInput).CornerRadius = UDim.new(0, 4)
local inputStroke = Instance.new("UIStroke", minStrengthInput)
inputStroke.Color = Color3.fromRGB(100, 100, 100)
inputStroke.Thickness = 1
inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local loadUWButton = styleButton("Auto Load UW", UDim2.new(0, 218, 0, 186), theme.Danger)

-- FAR RIGHT (Side Buttons)
local sideUnderwater = styleSideButton("UW", UDim2.new(1, -45, 0, 30), theme.Accent)
local sideMainIsland = styleSideButton("MI", UDim2.new(1, -45, 0, 71), theme.Success)

---------------------------------------------------------------------
-- BOTTOM SLIDER (Scaled Down)
---------------------------------------------------------------------
local sliderFrame = Instance.new("Frame", mainFrame)
sliderFrame.Size = UDim2.new(1, -30, 0, 22) 
sliderFrame.Position = UDim2.new(0, 15, 1, -34)
sliderFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0,6)

local sliderBar = Instance.new("Frame", sliderFrame)
sliderBar.Size = UDim2.new(1, -16, 0, 6)
sliderBar.Position = UDim2.new(0, 8, 0, 8)
sliderBar.BackgroundColor3 = Color3.new(1,1,1)
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0,3)

local knob = Instance.new("TextButton", sliderFrame)
knob.Size = UDim2.new(0, 15, 0, 22)
knob.Position = UDim2.new(0, 0, 0, 0)
knob.Text = ""
knob.BackgroundColor3 = Color3.new(1,1,1)
Instance.new("UICorner", knob).CornerRadius = UDim.new(0,6)
knob.AutoButtonColor = false


local function createGlow(button, color)
    local glowFrame = Instance.new("Frame", button)
    glowFrame.Size = UDim2.new(1, 8, 1, 8)
    glowFrame.Position = UDim2.new(0, -4, 0, -4)
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = button.ZIndex - 1
    Instance.new("UICorner", glowFrame).CornerRadius = UDim.new(0, 8)
    local outer = Instance.new("UIStroke", glowFrame)
    outer.Thickness = 7; outer.Transparency = 1; outer.Color = color
    local inner = Instance.new("UIStroke", glowFrame)
    inner.Thickness = 3; inner.Transparency = 1; inner.Color = color
    local grad = Instance.new("UIGradient", glowFrame)
    return {frame = glowFrame, outer = outer, inner = inner, grad = grad, tweens = {}}
end

local glowTP = createGlow(tpButton, Color3.new(1,1,1))
local glowAll = createGlow(autoAnyButton, theme.Danger)
local glowCustom = createGlow(autoCustomButton, theme.Danger)
local glowUW = createGlow(loadUWButton, theme.Danger)
local glowPetNotif = createGlow(petNotifButton, theme.Accent)
local glowWeather = createGlow(weatherButton, theme.Accent)

local function startGlow(glow)
    for _, t in ipairs(glow.tweens) do t:Cancel() end
    glow.tweens = {
        TweenService:Create(glow.outer, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.65}),
        TweenService:Create(glow.inner, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0}),
        TweenService:Create(glow.grad, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360})
    }
    for _, t in ipairs(glow.tweens) do t:Play() end
end

local function stopGlow(glow)
    for _, t in ipairs(glow.tweens) do t:Cancel() end
    glow.tweens = {}
    glow.outer.Transparency = 1; glow.inner.Transparency = 1; glow.grad.Rotation = 0
end

local function findStrongestPetAny()
    local strongest, max = nil, 0
    for _, obj in pairs(CollectionService:GetTagged("Roaming")) do
        local s = obj:GetAttribute("Strength")
        local o = obj:GetAttribute("OwnerId")
        if s and (not o or o == 0) and s > max then
            max = s; strongest = obj
        end
    end
    return strongest
end

local function findStrongestPetCustom(minStrength)
    local strongest, max = nil, minStrength - 1
    for _, obj in pairs(CollectionService:GetTagged("Roaming")) do
        local s = obj:GetAttribute("Strength")
        local o = obj:GetAttribute("OwnerId")
        if s and s >= minStrength and (not o or o == 0) and s > max then
            max = s; strongest = obj
        end
    end
    return strongest
end

local function isPlayerBusy()
    for _, obj in pairs(CollectionService:GetTagged("Roaming")) do
        local o = obj:GetAttribute("OwnerId")
        if o == player.UserId then return true end
    end
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in pairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Enabled then
                local name = string.lower(gui.Name)
                if string.find(name, "minigame") or string.find(name, "catch") or string.find(name, "lasso") then
                    return true
                end
            end
        end
        local mgFrame = pg:FindFirstChild("Minigame", true) or pg:FindFirstChild("Catching", true) or pg:FindFirstChild("Minigames", true)
        if mgFrame and mgFrame:IsA("GuiObject") and mgFrame.Visible then
            local sGui = mgFrame:FindFirstAncestorOfClass("ScreenGui")
            if sGui and sGui.Enabled then return true end
        end
    end
    return false
end

local underwater = CFrame.new(13.0744, 180.5068, -4959.8169)
local mainIsland = CFrame.new(-105.803, 830.677, -2745.03)

tpButton.MouseButton1Click:Connect(function()
    local pet = findStrongestPetAny()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if pet and root then
        startGlow(glowTP)
        root.CFrame = pet:GetPivot() + Vector3.new(0,5,0)
        task.delay(3, function() stopGlow(glowTP) end)
    end
end)

local autoModeAll = false
autoAnyButton.MouseButton1Click:Connect(function()
    autoModeAll = not autoModeAll
    autoAnyButton.Text = "Auto Teleport (All): " .. (autoModeAll and "ON" or "OFF")
    if autoModeAll then
        startGlow(glowAll); autoAnyButton.UIStroke.Color = Color3.new(1,1,1); autoAnyButton.TextColor3 = Color3.new(1,1,1)
    else
        stopGlow(glowAll); autoAnyButton.UIStroke.Color = theme.Danger; autoAnyButton.TextColor3 = theme.Danger
    end
end)

local currentMinStrength = 3000
minStrengthInput.FocusLost:Connect(function()
    local val = tonumber(minStrengthInput.Text)
    if val then
        currentMinStrength = val
    else
        minStrengthInput.Text = tostring(currentMinStrength)
    end
end)

local autoModeCustom = false
autoCustomButton.MouseButton1Click:Connect(function()
    autoModeCustom = not autoModeCustom
    autoCustomButton.Text = "Auto Teleport Custom: " .. (autoModeCustom and "ON" or "OFF")
    if autoModeCustom then
        startGlow(glowCustom); autoCustomButton.UIStroke.Color = Color3.new(1,1,1); autoCustomButton.TextColor3 = Color3.new(1,1,1)
    else
        stopGlow(glowCustom); autoCustomButton.UIStroke.Color = theme.Danger; autoCustomButton.TextColor3 = theme.Danger
    end
end)

local autoLoadUW = false
loadUWButton.MouseButton1Click:Connect(function()
    autoLoadUW = not autoLoadUW
    loadUWButton.Text = "Auto Load UW: " .. (autoLoadUW and "ON" or "OFF")
    if autoLoadUW then
        startGlow(glowUW); loadUWButton.UIStroke.Color = Color3.new(1,1,1); loadUWButton.TextColor3 = Color3.new(1,1,1)
    else
        stopGlow(glowUW); loadUWButton.UIStroke.Color = theme.Danger; loadUWButton.TextColor3 = theme.Danger
    end
end)

local customPetNotifEnabled = false
petNotifButton.MouseButton1Click:Connect(function()
    customPetNotifEnabled = not customPetNotifEnabled
    petNotifButton.Text = "Custom Pet Notifier: " .. (customPetNotifEnabled and "ON" or "OFF")
    if customPetNotifEnabled then
        startGlow(glowPetNotif); petNotifButton.UIStroke.Color = theme.Accent; petNotifButton.TextColor3 = theme.Accent
        sendOSNotification("Pet Notifier", "Notifier ON! Alerting for pets >= " .. tostring(currentMinStrength))
    else
        stopGlow(glowPetNotif); petNotifButton.UIStroke.Color = theme.Danger; petNotifButton.TextColor3 = theme.Danger
    end
end)

local weatherNotifEnabled = false
weatherButton.MouseButton1Click:Connect(function()
    weatherNotifEnabled = not weatherNotifEnabled
    weatherButton.Text = "Rare Weather Notifier: " .. (weatherNotifEnabled and "ON" or "OFF")
    if weatherNotifEnabled then
        startGlow(glowWeather); weatherButton.UIStroke.Color = theme.Accent; weatherButton.TextColor3 = theme.Accent
        sendOSNotification("Weather Notifier", "Notifier ON! Using weathers checked below.")
    else
        stopGlow(glowWeather); weatherButton.UIStroke.Color = theme.Danger; weatherButton.TextColor3 = theme.Danger
    end
end)

sideUnderwater.MouseButton1Click:Connect(function()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = underwater end
end)

sideMainIsland.MouseButton1Click:Connect(function()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = mainIsland end
end)

local draggingKnob = false
knob.MouseButton1Down:Connect(function() draggingKnob = true end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingKnob = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingKnob and input.UserInputType == Enum.UserInputType.MouseMovement then
        local relX = math.clamp(input.Position.X - sliderFrame.AbsolutePosition.X - 8, 0, sliderBar.AbsoluteSize.X)
        knob.Position = UDim2.new(0, relX, 0, 0)
        local speed = 30 + (relX/sliderBar.AbsoluteSize.X)*(200-30)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speed end
    end
end)

task.spawn(function()
    local lastUnderwaterTP = 0
    local savedPosition = nil
    local returning = false
    local lastWeather = nil
    local notifiedPets = {}

    while true do
        task.wait(0.5)

        -- WEATHER NOTIFICATION LOGIC
        if weatherNotifEnabled then
            pcall(function()
                local Knit = require(ReplicatedStorage.Packages.knit)
                local WeatherCtrl = Knit.GetController("WeatherController")
                local current = nil
                
                if WeatherCtrl then current = WeatherCtrl.CurrentWeather end
                if not current then current = workspace:GetAttribute("Weather") end

                if current and current ~= lastWeather then
                    lastWeather = current
                    -- Check if the specific weather is Ticked ON
                    if TargetWeathers[current] then
                        local prettyName = weatherDisplayNames[current] or current
                        sendOSNotification("Pet Catchers - Rare Weather!", prettyName .. " has started in the game!")
                    end
                end
            end)
        end

        -- CUSTOM PET NOTIFIER LOGIC
        if customPetNotifEnabled then
            pcall(function()
                for _, obj in pairs(CollectionService:GetTagged("Roaming")) do
                    local s = obj:GetAttribute("Strength")
                    local o = obj:GetAttribute("OwnerId")
                    if s and s >= currentMinStrength and (not o or o == 0) then
                        if not notifiedPets[obj] then
                            notifiedPets[obj] = true
                            local petName = obj:GetAttribute("Name") or "A rare pet"
                            sendOSNotification("Strong Pet Found!", petName .. " spawned with " .. tostring(s) .. " strength!")
                        end
                    end
                end
                
                for obj, _ in pairs(notifiedPets) do
                    if not obj:IsDescendantOf(workspace) then
                        notifiedPets[obj] = nil
                    end
                end
            end)
        end

        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        if isPlayerBusy() then
            continue
        end

        if autoLoadUW and not returning then
            if os.clock() - lastUnderwaterTP >= 60 then
                lastUnderwaterTP = os.clock()
                savedPosition = root.CFrame
                root.CFrame = underwater
                returning = true

                task.delay(3, function()
                    local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if r and savedPosition then
                        r.CFrame = savedPosition
                    end
                    returning = false
                end)
            end
        end

        if autoModeCustom and not returning then
            local pet = findStrongestPetCustom(currentMinStrength)
            if pet then root.CFrame = pet:GetPivot() + Vector3.new(0,5,0) end
        elseif autoModeAll and not returning then
            local pet = findStrongestPetAny()
            if pet then root.CFrame = pet:GetPivot() + Vector3.new(0,5,0) end
        end
    end
end)

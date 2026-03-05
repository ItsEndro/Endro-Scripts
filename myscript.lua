--[[ 
    + spaced side buttons & main island side button border = green
    + walk speed slider at bottom
--]]

local player = game.Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local theme = {
    Background = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(26, 148, 255),
    Success = Color3.fromRGB(61, 179, 98),   -- green for main island border
    Danger = Color3.fromRGB(170, 37, 46),
    Text = Color3.new(1, 1, 1),
    Font = Enum.Font.SourceSansBold
}

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local screenGui = Instance.new("ScreenGui", guiParent)
screenGui.Name = "TeleportGUI_Sirius"
screenGui.ResetOnSpawn = false

-- stable drag logic
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

-- Main Frame (wider to fit side buttons with space)
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 260) -- increased height for slider
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -130) -- centered using new size
mainFrame.BackgroundColor3 = theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
makeDraggable(mainFrame)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Title
local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Teleport GUI 3K"
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = theme.Text
title.Font = theme.Font
title.TextSize = 18
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

-- Close button
local closeButton = Instance.new("TextButton", title)
closeButton.Size = UDim2.new(0, 30, 1, 0)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.Text = "X"
closeButton.BackgroundTransparency = 1
closeButton.TextColor3 = theme.Danger
closeButton.TextSize = 18

-- Reopen Button (fixed border, no glow)
local reopenButton = Instance.new("TextButton", screenGui)
reopenButton.Size = UDim2.new(0, 150, 0, 30)
reopenButton.Position = UDim2.new(0.5, -75, 0.9, 0)
reopenButton.Text = "Open Teleport GUI"
reopenButton.BackgroundColor3 = theme.Background
reopenButton.TextColor3 = theme.Text
reopenButton.Font = theme.Font
reopenButton.TextSize = 14
reopenButton.Visible = false
reopenButton.AutoButtonColor = false
makeDraggable(reopenButton)
Instance.new("UICorner", reopenButton).CornerRadius = UDim.new(0, 8)
local reopenStroke = Instance.new("UIStroke", reopenButton)
reopenStroke.Color = theme.Danger
reopenStroke.Thickness = 2
reopenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    reopenButton.Visible = true
end)

reopenButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    reopenButton.Visible = false
end)

-- Button factory (main)
local function styleButton(text, pos, color)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0, 200, 0, 40)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = color
    btn.Font = theme.Font
    btn.TextSize = 16
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = color
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return btn
end

-- Side button factory (small square circular)
local function styleSideButton(text, pos, color)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = pos
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    btn.TextColor3 = theme.Text
    btn.Font = theme.Font
    btn.TextSize = 14
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = color
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return btn
end

-- Buttons
local tpButton = styleButton("Teleport to Strongest Pet", UDim2.new(0,20,0,40), Color3.new(1,1,1))
local autoAnyButton = styleButton("Auto Teleport (All)", UDim2.new(0,20,0,95), theme.Danger)
local autoButton = styleButton("Auto Teleport 3K", UDim2.new(0,20,0,150), theme.Danger)

-- Side Buttons: positioned with extra horizontal spacing (no touching)
local sideUnderwater = styleSideButton("UW", UDim2.new(1, -60, 0, 40), theme.Accent)
local sideMainIsland = styleSideButton("MI", UDim2.new(1, -60, 0, 95), theme.Success)

-- Glow system (behind buttons)
local function createGlow(button, color)
    local glowFrame = Instance.new("Frame", button)
    glowFrame.Size = UDim2.new(1, 12, 1, 12)
    glowFrame.Position = UDim2.new(0, -6, 0, -6)
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex = button.ZIndex - 1
    Instance.new("UICorner", glowFrame).CornerRadius = UDim.new(0, 10)
    local outer = Instance.new("UIStroke", glowFrame)
    outer.Thickness = 10
    outer.Transparency = 1
    outer.Color = color
    local inner = Instance.new("UIStroke", glowFrame)
    inner.Thickness = 4
    inner.Transparency = 1
    inner.Color = color
    local grad = Instance.new("UIGradient", glowFrame)
    return {frame = glowFrame, outer = outer, inner = inner, grad = grad, tweens = {}}
end

local glowTP = createGlow(tpButton, Color3.new(1,1,1))
local glowAll = createGlow(autoAnyButton, theme.Danger)
local glow2K = createGlow(autoButton, theme.Danger)

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
    glow.outer.Transparency = 1
    glow.inner.Transparency = 1
    glow.grad.Rotation = 0
end

-- Pet finders
local function findStrongestPetAny()
    local strongest, max = nil, 0
    for _, obj in pairs(CollectionService:GetTagged("Roaming")) do
        local s = obj:GetAttribute("Strength")
        local o = obj:GetAttribute("OwnerId")
        if s and (not o or o == 0) and s > max then
            max = s
            strongest = obj
        end
    end
    return strongest
end

local function findStrongestPet3K()
    local strongest, max = nil, 2900
    for _, obj in pairs(CollectionService:GetTagged("Roaming")) do
        local s = obj:GetAttribute("Strength")
        local o = obj:GetAttribute("OwnerId")
        if s and s >= 2900 and (not o or o == 0) and s > max then
            max = s
            strongest = obj
        end
    end
    return strongest
end

-- ISLAND POSITIONS
local underwater = CFrame.new(13.0744, 180.5068, -4959.8169)
local mainIsland = CFrame.new(-105.803, 830.677, -2745.03)

-- Teleport buttons handlers
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
        startGlow(glowAll)
        autoAnyButton.UIStroke.Color = Color3.new(1,1,1)
        autoAnyButton.TextColor3 = Color3.new(1,1,1)
    else
        stopGlow(glowAll)
        autoAnyButton.UIStroke.Color = theme.Danger
        autoAnyButton.TextColor3 = theme.Danger
    end
end)

local autoMode3K = false
autoButton.MouseButton1Click:Connect(function()
    autoMode3K = not autoMode3K
    autoButton.Text = "Auto Teleport 3K: " .. (autoMode3K and "ON" or "OFF")
    if autoMode3K then
        startGlow(glow2K)
        autoButton.UIStroke.Color = Color3.new(1,1,1)
        autoButton.TextColor3 = Color3.new(1,1,1)
    else
        stopGlow(glow2K)
        autoButton.UIStroke.Color = theme.Danger
        autoButton.TextColor3 = theme.Danger
    end
end)

-- Side buttons
sideUnderwater.MouseButton1Click:Connect(function()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = underwater end
end)

sideMainIsland.MouseButton1Click:Connect(function()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame = mainIsland end
end)

-- WalkSpeed slider at bottom
local sliderFrame = Instance.new("Frame", mainFrame)
sliderFrame.Size = UDim2.new(0, 260, 0, 30)
sliderFrame.Position = UDim2.new(0, 20, 1, -40)
sliderFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0,8)

local sliderBar = Instance.new("Frame", sliderFrame)
sliderBar.Size = UDim2.new(1, -20, 0, 8)
sliderBar.Position = UDim2.new(0,10,0,11)
sliderBar.BackgroundColor3 = Color3.new(1,1,1)
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0,4)

local knob = Instance.new("TextButton", sliderFrame)
knob.Size = UDim2.new(0,20,0,30)
knob.Position = UDim2.new(0,0,0,0)
knob.Text = ""
knob.BackgroundColor3 = Color3.new(1,1,1)
Instance.new("UICorner", knob).CornerRadius = UDim.new(0,8)
knob.AutoButtonColor = false

local dragging = false
knob.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local relX = math.clamp(input.Position.X - sliderFrame.AbsolutePosition.X - 10, 0, sliderBar.AbsoluteSize.X)
        knob.Position = UDim2.new(0, relX, 0, 0)
        local speed = 30 + (relX/sliderBar.AbsoluteSize.X)*(200-30)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = speed end
    end
end)

-- Main loop (auto teleport + island switching)
task.spawn(function()
    local lastUnderwaterTP = 0
    local savedPosition = nil
    local returning = false

    while true do
        task.wait(0.5)

        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- If any auto TP is enabled, do underwater cycle every 60s
        if (autoMode3K or autoModeAll) and not returning then
            if os.clock() - lastUnderwaterTP >= 60 then
                lastUnderwaterTP = os.clock()

                -- Save current position
                savedPosition = root.CFrame

                -- TP to underwater
                root.CFrame = underwater
                returning = true

                -- TP back after 3 seconds
                task.delay(3, function()
                    local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if r and savedPosition then
                        r.CFrame = savedPosition
                    end
                    returning = false
                end)
            end
        end

        -- Auto 3K pet TP
        if autoMode3K and not returning then
            local pet = findStrongestPet3K()
            if pet then
                root.CFrame = pet:GetPivot() + Vector3.new(0,5,0)
            end
        end

        -- Auto any pet TP
        if autoModeAll and not returning then
            local pet = findStrongestPetAny()
            if pet then
                root.CFrame = pet:GetPivot() + Vector3.new(0,5,0)
            end
        end
    end
end)

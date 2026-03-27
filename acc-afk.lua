-- ==========================================
-- ULTIMATE AFK GRIND SCRIPT (STUTTER-FREE)
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Clean up old GUI if re-executing
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("AFK_GrindUI")
if oldGui then oldGui:Destroy() end

-- ==========================================
-- 1. CONFIGURATION & CACHES
-- ==========================================
local SWEEP_CENTER = Vector3.new(-594, 7, -130)
local SWEEP_RADIUS = 25
local SWEEP_STEP = 8
local SWEEP_DELAY = 0.1
local PLACE_DELAY = 0.05

local autoOpen = false
local autoPlace = false
local autoSweep = false
local macroEnabled = false
local minimized = false

local ignoredPrompts = {}
local selectedPacksQueue = {}
local packFrameRef = nil

-- Cache Remotes
local RemoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local CardRemote = RemoteFolder:WaitForChild("Card")
local PotionRemote = RemoteFolder:WaitForChild("Potion")

-- ==========================================
-- 2. GUI CREATION
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AFK_GrindUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 340, 0, 315) -- Increased height to fit HP2
Main.Position = UDim2.new(0.5, 50, 0.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "AFK GRINDER"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1

local MinimizeBtn = Instance.new("TextButton", Main)
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -35, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.new(1, 1, 1)
MinimizeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", MinimizeBtn)

local MacroBtn = Instance.new("TextButton", Main)
MacroBtn.Size = UDim2.new(0.4, 0, 0, 265) -- Adjusted size to match new height
MacroBtn.Position = UDim2.new(0.05, 0, 0, 40)
MacroBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
MacroBtn.Text = "AFK MACRO\n\nOFF"
MacroBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MacroBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", MacroBtn)

local AutoOpenBtn = Instance.new("TextButton", Main)
AutoOpenBtn.Size = UDim2.new(0.45, 0, 0, 40)
AutoOpenBtn.Position = UDim2.new(0.5, 0, 0, 40)
AutoOpenBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
AutoOpenBtn.Text = "Open: OFF"
AutoOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoOpenBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AutoOpenBtn)

local AutoPlaceBtn = Instance.new("TextButton", Main)
AutoPlaceBtn.Size = UDim2.new(0.45, 0, 0, 40)
AutoPlaceBtn.Position = UDim2.new(0.5, 0, 0, 85)
AutoPlaceBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
AutoPlaceBtn.Text = "Place: OFF"
AutoPlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoPlaceBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AutoPlaceBtn)

local PlaceInput = Instance.new("TextBox", Main)
PlaceInput.Size = UDim2.new(0.45, 0, 0, 40)
PlaceInput.Position = UDim2.new(0.5, 0, 0, 130)
PlaceInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PlaceInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PlaceInput.PlaceholderText = "Select Packs in GUI"
PlaceInput.Text = ""
PlaceInput.TextScaled = true
PlaceInput.Font = Enum.Font.GothamBold
Instance.new("UICorner", PlaceInput)

local PotionInput = Instance.new("TextBox", Main)
PotionInput.Size = UDim2.new(0.15, 0, 0, 40)
PotionInput.Position = UDim2.new(0.5, 0, 0, 175)
PotionInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PotionInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PotionInput.PlaceholderText = "Amt"
PotionInput.Text = "1"
PotionInput.Font = Enum.Font.GothamBold
Instance.new("UICorner", PotionInput)

local AutoHPBtn = Instance.new("TextButton", Main)
AutoHPBtn.Size = UDim2.new(0.28, 0, 0, 40)
AutoHPBtn.Position = UDim2.new(0.67, 0, 0, 175)
AutoHPBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
AutoHPBtn.Text = "Use HP1"
AutoHPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHPBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AutoHPBtn)

-- HP2 CONTROLS
local Potion2Input = Instance.new("TextBox", Main)
Potion2Input.Size = UDim2.new(0.15, 0, 0, 40)
Potion2Input.Position = UDim2.new(0.5, 0, 0, 220)
Potion2Input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Potion2Input.TextColor3 = Color3.fromRGB(255, 255, 255)
Potion2Input.PlaceholderText = "Amt"
Potion2Input.Text = "0"
Potion2Input.Font = Enum.Font.GothamBold
Instance.new("UICorner", Potion2Input)

local AutoHP2Btn = Instance.new("TextButton", Main)
AutoHP2Btn.Size = UDim2.new(0.28, 0, 0, 40)
AutoHP2Btn.Position = UDim2.new(0.67, 0, 0, 220)
AutoHP2Btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
AutoHP2Btn.Text = "Use HP2"
AutoHP2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoHP2Btn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AutoHP2Btn)

local AutoSweepBtn = Instance.new("TextButton", Main)
AutoSweepBtn.Size = UDim2.new(0.45, 0, 0, 40)
AutoSweepBtn.Position = UDim2.new(0.5, 0, 0, 265) -- Moved down to accommodate HP2
AutoSweepBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
AutoSweepBtn.Text = "Sweep: OFF"
AutoSweepBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoSweepBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", AutoSweepBtn)

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinimizeBtn.Text = minimized and "+" or "-"
    for _, child in ipairs(Main:GetChildren()) do
        if (child:IsA("TextButton") or child:IsA("TextBox")) and child.Name ~= "MinimizeBtn" then
            child.Visible = not minimized
        end
    end
    Main.Size = minimized and UDim2.new(0, 340, 0, 35) or UDim2.new(0, 340, 0, 315)
end)

-- ==========================================
-- 3. UTILITIES & FUNCTIONS
-- ==========================================
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
end

local function getEquippedPacksFromUI()
    if packFrameRef and not packFrameRef:IsDescendantOf(game) then
        packFrameRef = nil
    end

    if not packFrameRef then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local backpackGui = playerGui:FindFirstChild("Backpack")
            if backpackGui and backpackGui:FindFirstChild("Frame") then
                packFrameRef = backpackGui.Frame:FindFirstChild("PackFrame")
            end
        end
    end

    local equippedPacks = {}
    if not packFrameRef then return equippedPacks end

    for _, packUI in ipairs(packFrameRef:GetChildren()) do
        if packUI:IsA("GuiObject") then
            local equippedMarker = packUI:FindFirstChild("Equipped")
            if equippedMarker and equippedMarker:IsA("GuiObject") and equippedMarker.Visible then
                table.insert(equippedPacks, packUI.Name)
            end
        end
    end

    return equippedPacks
end

local function teleportTo(pos)
    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        char:PivotTo(CFrame.new(pos))
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

-- ==========================================
-- 4. AUTO OPEN - PROMPT SCANNER
-- Scans ALL prompts in workspace every cycle regardless of distance.
-- PromptShown only fires when nearby so we can't rely on it for infinite range.
-- ==========================================
local function isTimerText(txt)
    return string.match(txt, "%d+:%d+")
        or string.match(txt, "%d+s")
        or string.match(txt, "%d+m")
        or string.match(txt, "%d+h")
        or string.match(txt, "%d+%.%d+")
end

local function isValidPackPrompt(prompt)
    -- Skip prompts we recently interacted with
    if ignoredPrompts[prompt] and tick() < ignoredPrompts[prompt] then return false end

    local txt = (prompt.ActionText .. " " .. prompt.ObjectText .. " " .. prompt.Name):lower()

    -- Skip buy/shop prompts
    if txt:find("buy") or txt:find("purchase") or txt:find("cost")
    or txt:find("price") or txt:find("%$") or txt:find("¥") then return false end

    -- Skip timer prompts (not ready yet)
    if isTimerText(txt) then return false end

    -- Skip prompts whose parent has a visible timer on it
    local parentPart = prompt.Parent
    if parentPart then
        for _, child in ipairs(parentPart:GetChildren()) do
            if child.ClassName == "BillboardGui" or child.ClassName == "SurfaceGui" then
                for _, uiChild in ipairs(child:GetDescendants()) do
                    if uiChild.ClassName == "TextLabel" or uiChild.ClassName == "TextBox" then
                        if isTimerText(uiChild.Text:lower()) then
                            return false
                        end
                    end
                end
            end
        end
    end

    if txt:find("open") or txt:find("hatch") or txt:find("ready") or txt:find("claim") or txt:find("pack") then
        return true
    end

    return false
end

-- AUTO OPEN LOOP
-- Scans all workspace descendants for valid prompts every tick.
-- Teleports directly to the prompt no matter where it is in the map.
task.spawn(function()
    while task.wait(0.1) do
        if not autoOpen then continue end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then continue end

        -- Scan entire workspace for a valid prompt — no distance restriction
        local foundPrompt = nil
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.ClassName == "ProximityPrompt" and isValidPackPrompt(obj) then
                foundPrompt = obj
                break
            end
        end

        if foundPrompt and foundPrompt.Parent and foundPrompt.Parent:IsA("BasePart") then
            -- Mark as ignored for 5 seconds so we don't re-open immediately
            ignoredPrompts[foundPrompt] = tick() + 5

            -- Teleport directly to the prompt, no matter how far away
            char:PivotTo(CFrame.new(foundPrompt.Parent.Position + Vector3.new(0, 3, 0)))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.08)

            if fireproximityprompt then
                fireproximityprompt(foundPrompt)
            else
                foundPrompt:InputHoldBegin()
                task.wait(foundPrompt.HoldDuration + 0.08)
                foundPrompt:InputHoldEnd()
            end

            -- Clean up expired ignored prompts
            for p, timeExpires in pairs(ignoredPrompts) do
                if tick() > timeExpires or typeof(p) ~= "Instance" or not p.Parent then
                    ignoredPrompts[p] = nil
                end
            end

            task.wait(0.08)
        end
    end
end)

-- ==========================================
-- 5. PERMANENT BACKGROUND THREADS
-- ==========================================

-- AUTO PLACE THREAD
task.spawn(function()
    local lastDisplayedPack = nil
    local equippedPack = nil

    while true do
        task.wait(PLACE_DELAY)
        local activePackID = selectedPacksQueue[1]

        if activePackID ~= lastDisplayedPack then
            PlaceInput.Text = activePackID or "No Pack Equipped!"
            lastDisplayedPack = activePackID
        end

        if autoPlace and activePackID then
            pcall(function()
                if activePackID ~= equippedPack then
                    equippedPack = activePackID
                    CardRemote:FireServer("Equip", activePackID)
                end
                CardRemote:FireServer("Place", activePackID)
            end)
        else
            equippedPack = nil
        end
    end
end)

-- GRID SWEEP THREAD
task.spawn(function()
    local currentX = SWEEP_CENTER.X - SWEEP_RADIUS
    local currentZ = SWEEP_CENTER.Z - SWEEP_RADIUS

    while task.wait(SWEEP_DELAY) do
        if autoSweep then
            teleportTo(Vector3.new(currentX, SWEEP_CENTER.Y, currentZ))

            currentX = currentX + SWEEP_STEP
            if currentX > SWEEP_CENTER.X + SWEEP_RADIUS then
                currentX = SWEEP_CENTER.X - SWEEP_RADIUS
                currentZ = currentZ + SWEEP_STEP
                if currentZ > SWEEP_CENTER.Z + SWEEP_RADIUS then
                    currentZ = SWEEP_CENTER.Z - SWEEP_RADIUS
                end
            end
        end
    end
end)

-- UI POLLING THREAD
task.spawn(function()
    while task.wait(0.5) do
        local currentEquipped = getEquippedPacksFromUI()

        local eqDict = {}
        for _, pack in ipairs(currentEquipped) do eqDict[pack] = true end

        local queueDict = {}
        for _, pack in ipairs(selectedPacksQueue) do queueDict[pack] = true end

        for i = #selectedPacksQueue, 1, -1 do
            if not eqDict[selectedPacksQueue[i]] then
                table.remove(selectedPacksQueue, i)
            end
        end

        for _, eqPack in ipairs(currentEquipped) do
            if not queueDict[eqPack] then
                table.insert(selectedPacksQueue, eqPack)
            end
        end
    end
end)

-- ==========================================
-- 6. BUTTON CONNECTIONS
-- ==========================================

local macroThread = nil

local function stopMacro()
    if macroThread then
        task.cancel(macroThread)
        macroThread = nil
    end
    macroEnabled = false
    autoSweep = false
    autoPlace = false
    autoOpen = false
    MacroBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    MacroBtn.Text = "AFK MACRO\n\nOFF"
    AutoSweepBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    AutoSweepBtn.Text = "Sweep: OFF"
    AutoPlaceBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    AutoPlaceBtn.Text = "Place: OFF"
    AutoOpenBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    AutoOpenBtn.Text = "Open: OFF"
end

local function startMacro()
    stopMacro()

    if #selectedPacksQueue == 0 then
        notify("Macro Warning", "No packs are currently selected in your Backpack UI!")
    end

    macroEnabled = true
    MacroBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 200)
    MacroBtn.Text = "AFK MACRO\n\n[ RUNNING ]"

    macroThread = task.spawn(function()
        while macroEnabled do
            -- Phase 1: Sweep + Place for 5 seconds
            autoSweep = true
            autoPlace = true
            AutoSweepBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
            AutoSweepBtn.Text = "Sweep: ON"
            AutoPlaceBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
            AutoPlaceBtn.Text = "Place: ON"

            local elapsed = 0
            while elapsed < 5 and macroEnabled do task.wait(0.1); elapsed += 0.1 end
            if not macroEnabled then break end

            -- Phase 2: Stop sweep + place
            autoSweep = false
            autoPlace = false
            AutoSweepBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            AutoSweepBtn.Text = "Sweep: OFF"
            AutoPlaceBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            AutoPlaceBtn.Text = "Place: OFF"

            task.wait(0.2)
            if not macroEnabled then break end

            -- Phase 3: Use HP1 Potions
            local amount = tonumber(PotionInput.Text)
            if amount and amount > 0 then
                for i = 1, math.floor(amount) do
                    if not macroEnabled then break end
                    pcall(function() PotionRemote:FireServer("Apply", "HatchTime1") end)
                    task.wait(0.1)
                end
            end
            
            -- Phase 3B: Use HP2 Potions
            local amount2 = tonumber(Potion2Input.Text)
            if amount2 and amount2 > 0 then
                for i = 1, math.floor(amount2) do
                    if not macroEnabled then break end
                    pcall(function() PotionRemote:FireServer("Apply", "HatchTime2") end)
                    task.wait(0.1)
                end
            end

            local wElapsed = 0
            while wElapsed < 1 and macroEnabled do task.wait(0.1); wElapsed += 0.1 end
            if not macroEnabled then break end

            -- Phase 4: Auto open for 10 seconds
            autoOpen = true
            AutoOpenBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
            AutoOpenBtn.Text = "Open: ON"

            local oElapsed = 0
            while oElapsed < 11.5 and macroEnabled do task.wait(0.1); oElapsed += 0.1 end

            autoOpen = false
            AutoOpenBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            AutoOpenBtn.Text = "Open: OFF"
        end

        stopMacro()
    end)
end

MacroBtn.MouseButton1Click:Connect(function()
    if macroEnabled then
        stopMacro()
    else
        startMacro()
    end
end)

AutoOpenBtn.MouseButton1Click:Connect(function()
    autoOpen = not autoOpen
    AutoOpenBtn.BackgroundColor3 = autoOpen and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(200, 40, 40)
    AutoOpenBtn.Text = autoOpen and "Open: ON" or "Open: OFF"
end)

AutoPlaceBtn.MouseButton1Click:Connect(function()
    autoPlace = not autoPlace
    AutoPlaceBtn.BackgroundColor3 = autoPlace and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(200, 40, 40)
    AutoPlaceBtn.Text = autoPlace and "Place: ON" or "Place: OFF"
end)

AutoHPBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(PotionInput.Text)
    if amount and amount > 0 then
        AutoHPBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
        AutoHPBtn.Text = "Using..."

        task.spawn(function()
            for i = 1, math.floor(amount) do
                pcall(function() PotionRemote:FireServer("Apply", "HatchTime1") end)
                task.wait(0.1)
            end
            AutoHPBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            AutoHPBtn.Text = "Use HP1"
            notify("Potions", "Used " .. tostring(math.floor(amount)) .. " HP1 Potions!")
        end)
    else
        notify("Error", "Please enter a valid amount of potions to use.")
    end
end)

AutoHP2Btn.MouseButton1Click:Connect(function()
    local amount = tonumber(Potion2Input.Text)
    if amount and amount > 0 then
        AutoHP2Btn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
        AutoHP2Btn.Text = "Using..."

        task.spawn(function()
            for i = 1, math.floor(amount) do
                pcall(function() PotionRemote:FireServer("Apply", "HatchTime2") end)
                task.wait(0.1)
            end
            AutoHP2Btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            AutoHP2Btn.Text = "Use HP2"
            notify("Potions", "Used " .. tostring(math.floor(amount)) .. " HP2 Potions!")
        end)
    else
        notify("Error", "Please enter a valid amount of potions to use.")
    end
end)

AutoSweepBtn.MouseButton1Click:Connect(function()
    autoSweep = not autoSweep
    AutoSweepBtn.BackgroundColor3 = autoSweep and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(200, 40, 40)
    AutoSweepBtn.Text = autoSweep and "Sweep: ON" or "Sweep: OFF"
end)

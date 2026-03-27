local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Clean up old GUI if re-executing
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("MutationTracker_Final")
if oldGui then oldGui:Destroy() end

-- 1. CONFIGURATION
local COLORS = {
    Void = Color3.fromRGB(103, 6, 248),
    Diamond = Color3.fromRGB(16, 215, 255),
    Rainbow = Color3.fromRGB(255, 6, 234),
    Merchant = Color3.fromRGB(255, 255, 255),
    Tokens = Color3.fromRGB(100, 255, 100),
    AutoBuy = Color3.fromRGB(200, 100, 100)
}

local PACKS = {
    "Pirate", "Ninja", "Soul", "Slayer", "Sorcerer", "Dragon", "Fire", "Hero", "Hunter",
    "Solo", "Titan", "Chainsaw", "Flight", "Ego", "Clover", "Ghoul", "Geass", "Bizarre",
    "Fairy", "Sins", "Note", "Slime", "Mage", "Zero", "Vagrant", "Rebellion", "Viking", "Mercenary"
}

local toggles = {}
local selectedPacks = {}
local notifiedObjects = {}
local activeTokens = {}
local knownPacks = {} -- Stores active conveyor packs: [Model] = { id = "11-1", type = "Titan" }
local lastMerchantAlert = 0
local minimized = false
local selectedAutoBuyPacks = {} -- {[packName] = true/nil }

-- Cache the Card remote
local CardRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Card")

-- 2. MASTER VOLUME BYPASS NOTIFICATION
local function sendAlert(title, text)
    task.spawn(function()
        pcall(function()
            local gameSettings = UserSettings():GetService("UserGameSettings")
            local originalVolume = gameSettings.MasterVolume
            if originalVolume <= 0.01 then gameSettings.MasterVolume = 0.5 end
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://4590657391"
            sound.Volume = 5
            sound.Parent = SoundService
            sound:Play()
            StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
            task.wait(1.5)
            if originalVolume <= 0.01 then gameSettings.MasterVolume = originalVolume end
            sound:Destroy()
        end)
    end)
end

-- 3. TOKEN EVALUATOR
local function evaluateToken(obj)
    if not obj then return end
    local isToken = false
    if obj.Name:lower():find("token") then isToken = true end
    if obj:IsA("Decal") and obj.Texture:find("101897927515858") then isToken = true end
    if obj:IsA("ImageLabel") and obj.Image:find("101897927515858") then isToken = true end
    if isToken then
        local item = (obj:IsA("Decal") or obj:IsA("ImageLabel")) and obj:FindFirstAncestorOfClass("BasePart") or obj
        if item and item:IsA("BasePart") then
            activeTokens[item] = true
        end
    end
end

-- 4. GUI CREATION
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MutationTracker_Final"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer.PlayerGui

local Main = Instance.new("Frame", ScreenGui)
Main.Position = UDim2.new(0.5, -90, 0.1, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "TRACKER & AUTO"
Title.TextColor3 = Color3.new(1, 1, 1)
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

local yPos = 40
local function CreateToggle(name, color, defaultState)
    toggles[name] = defaultState
    local btn = Instance.new("TextButton", Main)
    btn.Name = "Toggle_" .. name
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = name .. (defaultState and ": ON" or ": OFF")
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = defaultState and 0 or 0.7
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function()
        toggles[name] = not toggles[name]
        btn.Text = name .. (toggles[name] and ": ON" or ": OFF")
        btn.BackgroundTransparency = toggles[name] and 0 or 0.7
        if name == "Tokens" and toggles.Tokens then
            for _, v in ipairs(workspace:GetDescendants()) do evaluateToken(v) end
        end
    end)
    yPos = yPos + 35
end

-- Tracker Toggles
CreateToggle("Void", COLORS.Void, true)
CreateToggle("Diamond", COLORS.Diamond, true)
CreateToggle("Rainbow", COLORS.Rainbow, true)
CreateToggle("Merchant", COLORS.Merchant, true)
CreateToggle("Tokens", COLORS.Tokens, false)

-- Tracker Filter Dropdown Button
local FilterBtn = Instance.new("TextButton", Main)
FilterBtn.Name = "FilterBtn"
FilterBtn.Size = UDim2.new(0.9, 0, 0, 30)
FilterBtn.Position = UDim2.new(0.05, 0, 0, yPos)
FilterBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
FilterBtn.Text = "Tracker Filter ▼"
FilterBtn.Font = Enum.Font.GothamBold
FilterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", FilterBtn)
yPos = yPos + 35

-- Auto Buy Toggle
CreateToggle("AutoBuy", COLORS.AutoBuy, false)

-- Auto Buy Pack Select Button
local AutoBuySelectBtn = Instance.new("TextButton", Main)
AutoBuySelectBtn.Name = "AutoBuySelectBtn"
AutoBuySelectBtn.Size = UDim2.new(0.9, 0, 0, 30)
AutoBuySelectBtn.Position = UDim2.new(0.05, 0, 0, yPos)
AutoBuySelectBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
AutoBuySelectBtn.Text = "Auto Buy: None ▼"
AutoBuySelectBtn.Font = Enum.Font.GothamBold
AutoBuySelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", AutoBuySelectBtn)
yPos = yPos + 35

-- ==========================================
-- TRACKER FILTER DROPDOWN
-- ==========================================
local DropdownFrame = Instance.new("ScrollingFrame", Main)
DropdownFrame.Size = UDim2.new(0, 150, 0, 200)
DropdownFrame.Position = UDim2.new(1, 5, 0, 0)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DropdownFrame.ScrollBarThickness = 4
DropdownFrame.Visible = false
Instance.new("UICorner", DropdownFrame)
Instance.new("UIListLayout", DropdownFrame).SortOrder = Enum.SortOrder.LayoutOrder

for _, packName in ipairs(PACKS) do
    local PackBtn = Instance.new("TextButton", DropdownFrame)
    PackBtn.Size = UDim2.new(1, 0, 0, 25)
    PackBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    PackBtn.Text = "[ ] " .. packName
    PackBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    PackBtn.Font = Enum.Font.GothamSemibold
    PackBtn.TextXAlignment = Enum.TextXAlignment.Left
    PackBtn.MouseButton1Click:Connect(function()
        if selectedPacks[packName] then
            selectedPacks[packName] = nil
            PackBtn.Text = "[ ] " .. packName
            PackBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        else
            selectedPacks[packName] = true
            PackBtn.Text = "[X] " .. packName
            PackBtn.TextColor3 = Color3.new(0.2, 1, 0.2)
        end
    end)
end
DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, #PACKS * 25)

-- ==========================================
-- AUTO BUY DROPDOWN
-- ==========================================
local AutoBuyDropdown = Instance.new("ScrollingFrame", Main)
AutoBuyDropdown.Size = UDim2.new(0, 150, 0, 220)
AutoBuyDropdown.Position = UDim2.new(1, 5, 0, 40)
AutoBuyDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AutoBuyDropdown.ScrollBarThickness = 4
AutoBuyDropdown.Visible = false
Instance.new("UICorner", AutoBuyDropdown)

local AutoBuyListLayout = Instance.new("UIListLayout", AutoBuyDropdown)
AutoBuyListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function updateAutoBuyBtn()
    local count = 0
    for _ in pairs(selectedAutoBuyPacks) do count += 1 end
    AutoBuySelectBtn.Text = count == 0 and "Auto Buy: None ▼" or ("Auto Buy: " .. count .. " Pack(s) ▼")
end

for _, packName in ipairs(PACKS) do
    local Row = Instance.new("Frame", AutoBuyDropdown)
    Row.Size = UDim2.new(1, 0, 0, 30)
    Row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Row.BorderSizePixel = 0

    local SelectBtn = Instance.new("TextButton", Row)
    SelectBtn.Size = UDim2.new(1, 0, 1, 0)
    SelectBtn.Position = UDim2.new(0, 0, 0, 0)
    SelectBtn.BackgroundTransparency = 1
    SelectBtn.Text = "  [ ] " .. packName
    SelectBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    SelectBtn.Font = Enum.Font.GothamSemibold
    SelectBtn.TextXAlignment = Enum.TextXAlignment.Left
    SelectBtn.TextSize = 14

    SelectBtn.MouseButton1Click:Connect(function()
        if selectedAutoBuyPacks[packName] then
            selectedAutoBuyPacks[packName] = nil
            SelectBtn.Text = "  [ ] " .. packName
            SelectBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        else
            selectedAutoBuyPacks[packName] = true
            SelectBtn.Text = "[X] " .. packName
            SelectBtn.TextColor3 = Color3.new(0.2, 1, 0.2)
        end
        updateAutoBuyBtn()
    end)
end
AutoBuyDropdown.CanvasSize = UDim2.new(0, 0, 0, #PACKS * 30)

-- Dropdown toggle logic
FilterBtn.MouseButton1Click:Connect(function()
    DropdownFrame.Visible = not DropdownFrame.Visible
    if DropdownFrame.Visible then AutoBuyDropdown.Visible = false end
end)

AutoBuySelectBtn.MouseButton1Click:Connect(function()
    AutoBuyDropdown.Visible = not AutoBuyDropdown.Visible
    if AutoBuyDropdown.Visible then DropdownFrame.Visible = false end
end)

local originalHeight = yPos + 5
Main.Size = UDim2.new(0, 180, 0, originalHeight)

MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinimizeBtn.Text = minimized and "+" or "-"
    for _, child in ipairs(Main:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "MinimizeBtn" then
            child.Visible = not minimized
        end
    end
    if minimized then
        DropdownFrame.Visible = false
        AutoBuyDropdown.Visible = false
    end
    Main.Size = minimized and UDim2.new(0, 180, 0, 35) or UDim2.new(0, 180, 0, originalHeight)
end)

-- ==========================================
-- 5. PACK CATALOGING (Finds exact conveyor IDs)
-- ==========================================
local function RegisterConveyorPack(obj)
    pcall(function()
        if not obj or not obj.Parent then return end
        
        -- Find the root model or part
        local packRoot = obj
        if not (packRoot:IsA("Model") or packRoot:IsA("BasePart")) then
            packRoot = obj:FindFirstAncestorOfClass("Model") or obj:FindFirstAncestorOfClass("BasePart")
        end
        if not packRoot then
            packRoot = obj:FindFirstAncestorOfClass("ScreenGui") or obj.Parent
        end
        
        if not packRoot or knownPacks[packRoot] then return end
        
        -- Verify it is a pack using the "11-1" naming convention
        local packID = packRoot.Name:match("^%d+%-%d+$") or packRoot.Name:match("%d+%-%d+")
        if not packID then return end
        
        local foundPackName = nil
        
        -- Helper function to find the pack name from text
        local function checkText(text)
            text = text:lower()
            for _, pName in ipairs(PACKS) do
                if text:find(pName:lower()) then
                    return pName
                end
            end
            return nil
        end
        
        -- Check this specific object's text
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            foundPackName = checkText(obj.Text)
        end
        
        -- Deep search inside the packRoot if not found immediately
        if not foundPackName then
            for _, desc in ipairs(packRoot:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                    foundPackName = checkText(desc.Text)
                    if foundPackName then break end
                end
            end
        end
        
        -- Save it to active cache
        if foundPackName then
            knownPacks[packRoot] = { id = packID, type = foundPackName }
        end
    end)
end

-- ==========================================
-- 6. AUTO BUY LOOP
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        if not toggles.AutoBuy then continue end
        
        for packRoot, data in pairs(knownPacks) do
            -- Cleanup destroyed packs
            if not packRoot or not packRoot.Parent then
                knownPacks[packRoot] = nil
                continue
            end
            
            -- If this pack type is checked in our Auto Buy menu, send the exact ID
            if selectedAutoBuyPacks[data.type] then
                pcall(function()
                    CardRemote:FireServer("BuyPack", data.id)
                end)
            end
        end
    end
end)

-- 7. HEARTBEAT LOOP (Tokens)
RunService.Heartbeat:Connect(function()
    if not toggles.Tokens then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for token in pairs(activeTokens) do
        if token and token.Parent then
            token.CFrame = root.CFrame
            token.AssemblyLinearVelocity = Vector3.zero
            token.AssemblyAngularVelocity = Vector3.zero
        else
            activeTokens[token] = nil
        end
    end
end)

-- 8. SMART DETECTION LOGIC
local function CheckMutation(obj, isInitialScan)
    pcall(function()
        if not obj or not obj.Parent then return end
        local packRoot = obj:FindFirstAncestorOfClass("Model") or obj:FindFirstAncestorOfClass("BasePart")
        if not packRoot then
            local gui = obj:FindFirstAncestorOfClass("ScreenGui")
            packRoot = gui or obj.Parent
        end
        if notifiedObjects[packRoot] then return end

        local text = obj.Text:lower()
        local color = obj.TextColor3
        local foundMutation = nil

        for mutation, targetColor in pairs(COLORS) do
            if mutation ~= "Merchant" and mutation ~= "Tokens" and mutation ~= "AutoBuy" and toggles[mutation] then
                if text:find(mutation:lower()) then
                    foundMutation = mutation; break
                end
                if color == targetColor then
                    foundMutation = mutation; break
                end
                local gradient = obj:FindFirstChildOfClass("UIGradient")
                if gradient and gradient.Name:lower():find(mutation:lower()) then
                    foundMutation = mutation; break
                end
            end
        end

        if foundMutation then
            local foundPackName = "Unknown"
            for _, pName in ipairs(PACKS) do
                if packRoot.Name:lower():find(pName:lower()) then
                    foundPackName = pName; break
                end
            end
            if foundPackName == "Unknown" then
                for _, desc in ipairs(packRoot:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                        for _, pName in ipairs(PACKS) do
                            if desc.Text:lower():find(pName:lower()) then
                                foundPackName = pName; break
                            end
                        end
                        if foundPackName ~= "Unknown" then break end
                    end
                end
            end

            local passedFilter = true
            if next(selectedPacks) ~= nil then
                if not selectedPacks[foundPackName] then passedFilter = false end
            end

            if passedFilter then
                notifiedObjects[packRoot] = true
                if not isInitialScan then
                    sendAlert("MUTATION FOUND!", "A " .. foundMutation .. " " .. foundPackName .. " Pack has spawned!")
                end
            end
        end

        if text:find("merchant") and toggles.Merchant then
            if not notifiedObjects[packRoot] then
                notifiedObjects[packRoot] = true
                if not isInitialScan and (tick() - lastMerchantAlert > 30) then
                    lastMerchantAlert = tick()
                    sendAlert("MERCHANT SPAWNED!", "The Traveling Merchant is here!")
                end
            end
        end
    end)
end

-- 9. SETUP LISTENERS
local function SetupListeners(obj, isInitialScan)
    -- Actively register to our auto-buy conveyor dictionary
    RegisterConveyorPack(obj)
    
    if obj:IsA("TextLabel") or obj:IsA("TextBox") then
        CheckMutation(obj, isInitialScan)
        obj:GetPropertyChangedSignal("Text"):Connect(function() 
            RegisterConveyorPack(obj)
            CheckMutation(obj, false) 
        end)
        obj:GetPropertyChangedSignal("TextColor3"):Connect(function() CheckMutation(obj, false) end)
    elseif obj:IsA("Model") and obj.Name:lower():match("merchant") then
        if toggles.Merchant and not notifiedObjects[obj] then
            notifiedObjects[obj] = true
            if not isInitialScan and (tick() - lastMerchantAlert > 30) then
                lastMerchantAlert = tick()
                sendAlert("MERCHANT SPAWNED!", "The Traveling Merchant is here!")
            end
        end
    end
    evaluateToken(obj)
end

-- 10. INITIAL SCAN AND CONNECTIONS
for _, v in pairs(workspace:GetDescendants()) do
    task.spawn(SetupListeners, v, true)
end

workspace.DescendantAdded:Connect(function(v)
    SetupListeners(v, false)
end)

-- Periodically clean memory of destroyed packs
task.spawn(function()
    while task.wait(30) do
        for obj, _ in pairs(notifiedObjects) do
            if not obj or not obj.Parent then notifiedObjects[obj] = nil end
        end
        for packRoot, _ in pairs(knownPacks) do
            if not packRoot or not packRoot.Parent then knownPacks[packRoot] = nil end
        end
    end
end)

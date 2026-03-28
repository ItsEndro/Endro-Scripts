local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
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

-- Exact mutation colors for internal Auto-Buy detection
local MUTATION_COLORS = {
    Gold = Color3.fromRGB(255, 238, 2),
    Emerald = Color3.fromRGB(10, 255, 79),
    Void = Color3.fromRGB(103, 6, 248),
    Diamond = Color3.fromRGB(6, 248, 248),
    Rainbow = Color3.fromRGB(192, 2, 255)
}

local ALL_MUTATIONS = {
    "Regular", "Gold", "Emerald", "Void", "Diamond", "Rainbow"
}

-- The order of this array is VERY important as it maps directly to the Pack ID (e.g. Titan is 11)
local PACKS = {
    "Pirate", "Ninja", "Soul", "Slayer", "Sorcerer", "Dragon", "Fire", "Hero", "Hunter",
    "Solo", "Titan", "Chainsaw", "Flight", "Ego", "Clover", "Ghoul", "Geass", "Bizarre",
    "Fairy", "Sins", "Note", "Slime", "Mage", "Zero", "Vagrant", "Rebellion", "Viking", "Mercenary"
}

local toggles = {}
local selectedPacks = {}
local selectedAutoBuyPacks = {}
local selectedAutoBuyMutations = {}

-- ==========================================
-- CONFIG LOAD SYSTEM
-- ==========================================
local configName = "MutationTrackerConfig.json"

if isfile and isfile(configName) and readfile then
    local success, result = pcall(function()
        return HttpService:JSONDecode(readfile(configName))
    end)
    if success and type(result) == "table" then
        if result.toggles then toggles = result.toggles end
        if result.selectedPacks then selectedPacks = result.selectedPacks end
        if result.selectedAutoBuyPacks then selectedAutoBuyPacks = result.selectedAutoBuyPacks end
        if result.selectedAutoBuyMutations then selectedAutoBuyMutations = result.selectedAutoBuyMutations end
    end
end

local notifiedObjects = {}
local activeTokens = {}
local knownPacks = {}
local lastMerchantAlert = 0
local minimized = false

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
    if toggles[name] == nil then toggles[name] = defaultState end
    local state = toggles[name]

    local btn = Instance.new("TextButton", Main)
    btn.Name = "Toggle_" .. name
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = name .. (state and ": ON" or ": OFF")
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = state and 0 or 0.7
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
AutoBuySelectBtn.Text = "Auto Buy Packs ▼"
AutoBuySelectBtn.Font = Enum.Font.GothamBold
AutoBuySelectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", AutoBuySelectBtn)
yPos = yPos + 35

-- Auto Buy Mutation Select Button
local AutoBuyMutationBtn = Instance.new("TextButton", Main)
AutoBuyMutationBtn.Name = "AutoBuyMutationBtn"
AutoBuyMutationBtn.Size = UDim2.new(0.9, 0, 0, 30)
AutoBuyMutationBtn.Position = UDim2.new(0.05, 0, 0, yPos)
AutoBuyMutationBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
AutoBuyMutationBtn.Text = "Auto Buy Muts ▼"
AutoBuyMutationBtn.Font = Enum.Font.GothamBold
AutoBuyMutationBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", AutoBuyMutationBtn)
yPos = yPos + 35

-- Save Config Button
local SaveBtn = Instance.new("TextButton", Main)
SaveBtn.Name = "SaveBtn"
SaveBtn.Size = UDim2.new(0.9, 0, 0, 30)
SaveBtn.Position = UDim2.new(0.05, 0, 0, yPos)
SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
SaveBtn.Text = "Save Config"
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", SaveBtn)
yPos = yPos + 35

-- Save Functionality
SaveBtn.MouseButton1Click:Connect(function()
    if writefile then
        local data = {
            toggles = toggles,
            selectedPacks = selectedPacks,
            selectedAutoBuyPacks = selectedAutoBuyPacks,
            selectedAutoBuyMutations = selectedAutoBuyMutations
        }
        local success = pcall(function()
            writefile(configName, HttpService:JSONEncode(data))
        end)
        if success then
            SaveBtn.Text = "Saved successfully!"
            SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        else
            SaveBtn.Text = "Error Saving!"
            SaveBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    else
        SaveBtn.Text = "Not Supported!"
        SaveBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    task.delay(1.5, function() 
        SaveBtn.Text = "Save Config" 
        SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    end)
end)

-- ==========================================
-- DROPDOWN FRAMES
-- ==========================================
local function CreateDropdown(parent, yOffset, sizeY, list, stateTable, updateLabelFunc)
    local Frame = Instance.new("ScrollingFrame", parent)
    Frame.Size = UDim2.new(0, 150, 0, sizeY)
    Frame.Position = UDim2.new(1, 5, 0, yOffset)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.ScrollBarThickness = 4
    Frame.Visible = false
    Instance.new("UICorner", Frame)

    local Layout = Instance.new("UIListLayout", Frame)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder

    for _, itemName in ipairs(list) do
        local isSelected = stateTable[itemName]
        
        local Row = Instance.new("Frame", Frame)
        Row.Size = UDim2.new(1, 0, 0, 30)
        Row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Row.BorderSizePixel = 0

        local SelectBtn = Instance.new("TextButton", Row)
        SelectBtn.Size = UDim2.new(1, 0, 1, 0)
        SelectBtn.BackgroundTransparency = 1
        SelectBtn.Text = (isSelected and "[X] " or "  [ ] ") .. itemName
        SelectBtn.TextColor3 = isSelected and Color3.new(0.2, 1, 0.2) or Color3.new(0.8, 0.8, 0.8)
        SelectBtn.Font = Enum.Font.GothamSemibold
        SelectBtn.TextXAlignment = Enum.TextXAlignment.Left
        SelectBtn.TextSize = 14

        SelectBtn.MouseButton1Click:Connect(function()
            if stateTable[itemName] then
                stateTable[itemName] = nil
                SelectBtn.Text = "  [ ] " .. itemName
                SelectBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
            else
                stateTable[itemName] = true
                SelectBtn.Text = "[X] " .. itemName
                SelectBtn.TextColor3 = Color3.new(0.2, 1, 0.2)
            end
            if updateLabelFunc then updateLabelFunc() end
        end)
    end
    Frame.CanvasSize = UDim2.new(0, 0, 0, #list * 30)
    return Frame
end

local DropdownFrame = CreateDropdown(Main, 0, 200, PACKS, selectedPacks, nil)

local function updateAutoBuyBtn()
    local count = 0
    for _ in pairs(selectedAutoBuyPacks) do count += 1 end
    AutoBuySelectBtn.Text = count == 0 and "Auto Buy Packs: 0 ▼" or ("Auto Buy Packs: " .. count .. " ▼")
end
local AutoBuyDropdown = CreateDropdown(Main, 40, 220, PACKS, selectedAutoBuyPacks, updateAutoBuyBtn)
updateAutoBuyBtn()

local function updateAutoBuyMutBtn()
    local count = 0
    for _ in pairs(selectedAutoBuyMutations) do count += 1 end
    AutoBuyMutationBtn.Text = count == 0 and "Auto Buy Muts: Any ▼" or ("Auto Buy Muts: " .. count .. " ▼")
end
local AutoBuyMutDropdown = CreateDropdown(Main, 80, 180, ALL_MUTATIONS, selectedAutoBuyMutations, updateAutoBuyMutBtn)
updateAutoBuyMutBtn()

-- Dropdown toggle logic
local function toggleDropdown(showDropdown)
    DropdownFrame.Visible = (showDropdown == DropdownFrame and not DropdownFrame.Visible)
    AutoBuyDropdown.Visible = (showDropdown == AutoBuyDropdown and not AutoBuyDropdown.Visible)
    AutoBuyMutDropdown.Visible = (showDropdown == AutoBuyMutDropdown and not AutoBuyMutDropdown.Visible)
end

FilterBtn.MouseButton1Click:Connect(function() toggleDropdown(DropdownFrame) end)
AutoBuySelectBtn.MouseButton1Click:Connect(function() toggleDropdown(AutoBuyDropdown) end)
AutoBuyMutationBtn.MouseButton1Click:Connect(function() toggleDropdown(AutoBuyMutDropdown) end)

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
    if minimized then toggleDropdown(nil) end
    Main.Size = minimized and UDim2.new(0, 180, 0, 35) or UDim2.new(0, 180, 0, originalHeight)
end)

-- ==========================================
-- 5. PACK CATALOGING (Finds exact conveyor IDs & Mutations)
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
        local foundMutation = "Regular"
        
        -- Helper function to find the pack name
        local function checkText(text)
            text = text:lower()
            for _, pName in ipairs(PACKS) do
                if text:find(pName:lower()) then return pName end
            end
            return nil
        end
        
        -- Helper function to find mutation
        local function checkMut(o)
            local text = (o:IsA("TextLabel") or o:IsA("TextBox")) and o.Text:lower() or ""
            local color = (o:IsA("TextLabel") or o:IsA("TextBox")) and o.TextColor3 or nil
            
            for mutName, tColor in pairs(MUTATION_COLORS) do
                if text:find(mutName:lower()) then return mutName end
                if color == tColor then return mutName end
                local grad = o:FindFirstChildOfClass("UIGradient")
                if grad and grad.Name:lower():find(mutName:lower()) then return mutName end
            end
            return nil
        end
        
        -- Check this specific object
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then
            foundPackName = checkText(obj.Text)
            local m = checkMut(obj)
            if m then foundMutation = m end
        end
        
        -- Deep search inside the packRoot if missing details
        if not foundPackName or foundMutation == "Regular" then
            for _, desc in ipairs(packRoot:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                    if not foundPackName then foundPackName = checkText(desc.Text) end
                    if foundMutation == "Regular" then
                        local m = checkMut(desc)
                        if m then foundMutation = m end
                    end
                end
            end
        end
        
        -- Save it to active cache
        if foundPackName then
            -- If we already have this pack recorded but suddenly found its mutation, update it
            if knownPacks[packRoot] then
                if knownPacks[packRoot].mutation == "Regular" and foundMutation ~= "Regular" then
                    knownPacks[packRoot].mutation = foundMutation
                end
            else
                knownPacks[packRoot] = { id = packID, type = foundPackName, mutation = foundMutation }
            end
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
            
            -- Check Pack Filter
            if selectedAutoBuyPacks[data.type] then
                
                -- Check Mutation Filter (Empty array = allow ALL mutations)
                local passMutationFilter = true
                if next(selectedAutoBuyMutations) ~= nil then
                    passMutationFilter = (selectedAutoBuyMutations[data.mutation] == true)
                end
                
                if passMutationFilter then
                    pcall(function()
                        CardRemote:FireServer("BuyPack", data.id)
                    end)
                end
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

-- 8. SMART DETECTION LOGIC (Tracker Alerts)
local function CheckMutationAlerts(obj, isInitialScan)
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
                if text:find(mutation:lower()) then foundMutation = mutation; break end
                if color == targetColor then foundMutation = mutation; break end
                local gradient = obj:FindFirstChildOfClass("UIGradient")
                if gradient and gradient.Name:lower():find(mutation:lower()) then foundMutation = mutation; break end
            end
        end

        if foundMutation then
            local foundPackName = "Unknown"
            for _, pName in ipairs(PACKS) do
                if packRoot.Name:lower():find(pName:lower()) then foundPackName = pName; break end
            end
            if foundPackName == "Unknown" then
                for _, desc in ipairs(packRoot:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextBox") then
                        for _, pName in ipairs(PACKS) do
                            if desc.Text:lower():find(pName:lower()) then foundPackName = pName; break end
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
        CheckMutationAlerts(obj, isInitialScan)
        obj:GetPropertyChangedSignal("Text"):Connect(function() 
            RegisterConveyorPack(obj)
            CheckMutationAlerts(obj, false) 
        end)
        obj:GetPropertyChangedSignal("TextColor3"):Connect(function() CheckMutationAlerts(obj, false) end)
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

-- ================================================================= --
-- UNIVERSAL AIMBOT & ESP (CLEAN & STABLE FAST START)
-- ================================================================= --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ==================== SETTINGS & CONFIG SYSTEM ====================
local Settings = {
    AimbotEnabled = true,
    Mode = "Mobile",
    TeamCheckMode = "Free For All (Attack Everyone)",
    WallCheck = false,
    TargetBots = true,
    IgnorePlayers = false,
    ShowFOV = true,
    FOV = 150,
    Smoothness = 2,
    TargetPart = "Head",
    ESPEnabled = true,
    BoxESP = true,
    NameESP = true,
    TracerESP = false,
    FirstPersonActive = true,
    CameraFOVEnabled = false,
    CameraFOVValue = 70
}

local ConfigFileName = "KupaAimbot_Config.json"

local function SaveConfig()
    if writefile then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(Settings))
        end)
    end
end

local function LoadConfig()
    if readfile and isfile and isfile(ConfigFileName) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    Settings[k] = v
                end
            end
        end)
    end
end

LoadConfig()

-- ==================== RAYFIELD INIT ====================
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("Failed to load Rayfield UI library!")
    return
end

local Window = Rayfield:CreateWindow({
   Name = "Universal Aimbot & ESP",
   LoadingTitle = "Loading System...",
   LoadingSubtitle = "by Kupa",
   ConfigurationSaving = { Enabled = false }
})

-- Уведомление о запуске
Rayfield:Notify({
   Title = "Welcome, " .. LocalPlayer.Name,
   Content = "Script loaded successfully!",
   Duration = 3,
   Image = 4483362458,
})

-- ==================== DRAWING ELEMENTS ====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 2
FOVCircle.Transparency = 0.8
FOVCircle.Radius = Settings.FOV

local ESPCache = {}

local function CreateESPForModel(model, nameText)
    if model == LocalPlayer.Character then return end

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Thickness = 1.5
    Box.Filled = false

    local Name = Drawing.new("Text")
    Name.Visible = false
    Name.Text = nameText
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Size = 14
    Name.Center = true
    Name.Outline = true

    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Color = Color3.fromRGB(255, 0, 0)
    Tracer.Thickness = 1

    ESPCache[model] = {Box = Box, Name = Name, Tracer = Tracer, Model = model}
end

local function RemoveESP(model)
    if ESPCache[model] then
        ESPCache[model].Box:Remove()
        ESPCache[model].Name:Remove()
        ESPCache[model].Tracer:Remove()
        ESPCache[model] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then
        CreateESPForModel(p.Character, p.Name)
    end
    p.CharacterAdded:Connect(function(char)
        CreateESPForModel(char, p.Name)
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        CreateESPForModel(char, p.Name)
    end)
end)

task.spawn(function()
    while task.wait(1) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
                local isPlayerChar = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then isPlayerChar = true break end
                end
                
                if not isPlayerChar and obj ~= LocalPlayer.Character and not ESPCache[obj] then
                    CreateESPForModel(obj, obj.Name)
                end
            end
        end
    end
end)

-- ==================== HELPER FUNCTIONS ====================
local function IsVisible(targetPart, targetCharacter)
    if not Settings.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    
    local ignoreList = {LocalPlayer.Character, Camera}
    if targetCharacter then
        table.insert(ignoreList, targetCharacter)
    end
    
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult == nil
end

local function GetFOVPosition()
    if Settings.Mode == "Mobile" then
        return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

local function GetTargetPart(character)
    if Settings.TargetPart == "Head" then
        return character:FindFirstChild("Head")
    elseif Settings.TargetPart == "HumanoidRootPart" then
        return character:FindFirstChild("HumanoidRootPart")
    else
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
    end
end

local function IsRealPlayerModel(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then
            return true
        end
    end
    return false
end

local function IsValidTargetModel(model)
    if model == LocalPlayer.Character then return false end
    
    local isPlayer = IsRealPlayerModel(model)
    
    if isPlayer then
        if Settings.IgnorePlayers then return false end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character == model then
                if Settings.TeamCheckMode == "Normal Teams (Ignore Same Team)" then
                    if LocalPlayer.Team and player.Team then
                        return LocalPlayer.Team ~= player.Team
                    end
                elseif Settings.TeamCheckMode == "Inverted Teams (Flip Logic)" then
                    if LocalPlayer.Team and player.Team then
                        return LocalPlayer.Team == player.Team
                    end
                end
                break
            end
        end
        return true
    else
        if not Settings.TargetBots then return false end
        return true
    end
end

local function GetClosestTarget()
    local closestTarget = nil
    local shortestDistance = Settings.FOV
    local centerPoint = GetFOVPosition()

    for model, _ in pairs(ESPCache) do
        if model and model.Parent and IsValidTargetModel(model) then
            local humanoid = model:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local targetPart = GetTargetPart(model)
                if targetPart then
                    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - centerPoint).Magnitude
                        
                        if distance < shortestDistance then
                            if IsVisible(targetPart, model) then
                                shortestDistance = distance
                                closestTarget = {Character = model, Part = targetPart}
                            end
                        end
                    end
                end
            end
        end
    end

    return closestTarget
end

-- ==================== UI TABS ====================
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local ESPTab = Window:CreateTab("Visuals", 4483362458)
local CameraTab = Window:CreateTab("Camera", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

AimbotTab:CreateToggle({
   Name = "Aimbot Enabled",
   CurrentValue = Settings.AimbotEnabled,
   Callback = function(Value) Settings.AimbotEnabled = Value SaveConfig() end,
})

AimbotTab:CreateDropdown({
   Name = "Platform Mode",
   Options = {"Mobile", "PC"},
   CurrentOption = {Settings.Mode},
   Callback = function(Option) Settings.Mode = Option[1] SaveConfig() end,
})

AimbotTab:CreateDropdown({
   Name = "Team Check Mode",
   Options = {"Free For All (Attack Everyone)", "Normal Teams (Ignore Same Team)", "Inverted Teams (Flip Logic)"},
   CurrentOption = {Settings.TeamCheckMode},
   Callback = function(Option) Settings.TeamCheckMode = Option[1] SaveConfig() end,
})

AimbotTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = Settings.WallCheck,
   Callback = function(Value) Settings.WallCheck = Value SaveConfig() end,
})

AimbotTab:CreateToggle({
   Name = "Target Bots",
   CurrentValue = Settings.TargetBots,
   Callback = function(Value) Settings.TargetBots = Value SaveConfig() end,
})

AimbotTab:CreateToggle({
   Name = "Ignore Players",
   CurrentValue = Settings.IgnorePlayers,
   Callback = function(Value) Settings.IgnorePlayers = Value SaveConfig() end,
})

AimbotTab:CreateToggle({
   Name = "Show / Hide FOV",
   CurrentValue = Settings.ShowFOV,
   Callback = function(Value) Settings.ShowFOV = Value SaveConfig() end,
})

AimbotTab:CreateSlider({
   Name = "FOV Radius",
   Range = {50, 600},
   Increment = 10,
   CurrentValue = Settings.FOV,
   Callback = function(Value) Settings.FOV = Value SaveConfig() end,
})

AimbotTab:CreateSlider({
   Name = "Smoothness",
   Range = {1, 10},
   Increment = 1,
   CurrentValue = Settings.Smoothness,
   Callback = function(Value) Settings.Smoothness = Value SaveConfig() end,
})

AimbotTab:CreateDropdown({
   Name = "Target Part",
   Options = {"Head", "HumanoidRootPart", "Auto/Any"},
   CurrentOption = {Settings.TargetPart},
   Callback = function(Option) Settings.TargetPart = Option[1] SaveConfig() end,
})

ESPTab:CreateToggle({
   Name = "ESP Enabled",
   CurrentValue = Settings.ESPEnabled,
   Callback = function(Value) Settings.ESPEnabled = Value SaveConfig() end,
})

ESPTab:CreateToggle({
   Name = "Box ESP",
   CurrentValue = Settings.BoxESP,
   Callback = function(Value) Settings.BoxESP = Value SaveConfig() end,
})

ESPTab:CreateToggle({
   Name = "Name ESP",
   CurrentValue = Settings.NameESP,
   Callback = function(Value) Settings.NameESP = Value SaveConfig() end,
})

ESPTab:CreateToggle({
   Name = "Tracer Lines",
   CurrentValue = Settings.TracerESP,
   Callback = function(Value) Settings.TracerESP = Value SaveConfig() end,
})

CameraTab:CreateToggle({
   Name = "Enable FOV",
   CurrentValue = Settings.CameraFOVEnabled,
   Callback = function(Value) Settings.CameraFOVEnabled = Value SaveConfig() end,
})

CameraTab:CreateSlider({
   Name = "Camera FOV",
   Range = {70, 120},
   Increment = 1,
   CurrentValue = Settings.CameraFOVValue,
   Callback = function(Value) Settings.CameraFOVValue = Value SaveConfig() end,
})

SettingsTab:CreateToggle({
   Name = "First Person Mode (All Functions)",
   CurrentValue = Settings.FirstPersonActive,
   Callback = function(Value) Settings.FirstPersonActive = Value SaveConfig() end,
})

SettingsTab:CreateButton({
   Name = "Save Config",
   Callback = function()
      SaveConfig()
      Rayfield:Notify({Title = "Success", Content = "Configuration saved!", Duration = 3, Image = 4483362458})
   end,
})

SettingsTab:CreateButton({
   Name = "Load Config",
   Callback = function()
      LoadConfig()
      Rayfield:Notify({Title = "Success", Content = "Configuration loaded!", Duration = 3, Image = 4483362458})
   end,
})

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    if Settings.CameraFOVEnabled then
        Camera.FieldOfView = Settings.CameraFOVValue
    end

    local isAllowedByCamera = true
    if not Settings.FirstPersonActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        local head = LocalPlayer.Character.Head
        local cameraDist = (Camera.CFrame.Position - head.Position).Magnitude
        if cameraDist < 1.2 or Camera.CameraSubject == head then
            isAllowedByCamera = false
        end
    end

    local fovPos = GetFOVPosition()
    FOVCircle.Position = fovPos
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.AimbotEnabled and Settings.ShowFOV and isAllowedByCamera

    local shouldAim = false
    if Settings.AimbotEnabled and isAllowedByCamera then
        if Settings.Mode == "PC" then
            shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif Settings.Mode == "Mobile" then
            shouldAim = true
        end
    end

    if shouldAim then
        local targetData = GetClosestTarget()
        if targetData and targetData.Part then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetData.Part.Position)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / Settings.Smoothness)
        end
    end

    for model, esp in pairs(ESPCache) do
        if model and model.Parent then
            local shouldShow = Settings.ESPEnabled and isAllowedByCamera and IsValidTargetModel(model)

            local humanoid = model:FindFirstChild("Humanoid")
            if shouldShow and humanoid and humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") then
                local rootPart = model.HumanoidRootPart
                local head = model:FindFirstChild("Head") or rootPart
                
                local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))

                if onScreen then
                    local boxHeight = math.abs(headPos.Y - rootPos.Y) * 2
                    local boxWidth = boxHeight / 1.5

                    if Settings.BoxESP then
                        esp.Box.Size = Vector2.new(boxWidth, boxHeight)
                        esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
                        esp.Box.Visible = true
                    else
                        esp.Box.Visible = false
                    end

                    if Settings.NameESP then
                        esp.Name.Text = model.Name
                        esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 16)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end

                    if Settings.TracerESP then
                        esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                        esp.Tracer.Visible = true
                    else
                        esp.Tracer.Visible = false
                    end
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Tracer.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Tracer.Visible = false
            end
        else
            RemoveESP(model)
        end
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera
local DefaultFOV = Camera.FieldOfView

local NoclipEnabled = false
local NoFogEnabled = false
local FullBrightEnabled = false
local AimBotEnabled = false
local OriginalFogEnd = Lighting.FogEnd
local OriginalFogStart = Lighting.FogStart
local OriginalAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local AtmosphereBackup = nil
local OriginalBrightness = Lighting.Brightness
local OriginalGlobalShadows = Lighting.GlobalShadows
local OriginalAmbient = Lighting.Ambient
local OriginalClockTime = Lighting.ClockTime
local OriginalEnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
local OriginalEnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
local OriginalColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
local ColorCorrectionBackup = nil

if OriginalAtmosphere then
    AtmosphereBackup = OriginalAtmosphere:Clone()
end
if OriginalColorCorrection then
    ColorCorrectionBackup = OriginalColorCorrection:Clone()
end

local function Noclip()
    if not Character then
        return
    end
    if NoclipEnabled then
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
        if HumanoidRootPart then
            HumanoidRootPart.CanCollide = false
        end
    else
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
        if HumanoidRootPart then
            HumanoidRootPart.CanCollide = true
        end
    end
end

local function NoFog()
    if not Lighting then
        return
    end
    if NoFogEnabled then
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 1000000
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere:Destroy()
        end
    else
        Lighting.FogEnd = OriginalFogEnd
        Lighting.FogStart = OriginalFogStart
        if AtmosphereBackup and not Lighting:FindFirstChildOfClass("Atmosphere") then
            AtmosphereBackup:Clone().Parent = Lighting
        end
    end
end

local function FullBright()
    if not Lighting then
        return
    end
    if FullBrightEnabled then
        Lighting.Brightness = 3
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 12
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if colorCorrection then
            colorCorrection:Destroy()
        end
    else
        Lighting.Brightness = OriginalBrightness
        Lighting.GlobalShadows = OriginalGlobalShadows
        Lighting.Ambient = OriginalAmbient
        Lighting.ClockTime = OriginalClockTime
        Lighting.EnvironmentDiffuseScale = OriginalEnvironmentDiffuseScale
        Lighting.EnvironmentSpecularScale = OriginalEnvironmentSpecularScale
        if ColorCorrectionBackup and not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
            ColorCorrectionBackup:Clone().Parent = Lighting
        end
    end
end

local function IsRangedWeapon(tool)
    if not tool then
        return false
    end
    local toolName = tool.Name:lower()
    return toolName:find("gun") or toolName:find("rifle") or toolName:find("pistol") or toolName:find("shotgun") or toolName:find("revolver")
end

local function GetClosestEnemy()
    local closestEnemy = nil
    local closestDistance = 1000
    local playerPos = HumanoidRootPart.Position

    for _, model in pairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= Character and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") and model.Humanoid.Health > 0 then
            if not Players:GetPlayerFromCharacter(model) then
                local enemyHead = model:FindFirstChild("Head")
                local enemyPos = enemyHead.Position
                local distance = (playerPos - enemyPos).Magnitude
                if distance < closestDistance then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local rayResult = Workspace:Raycast(playerPos, (enemyPos - playerPos).Unit * distance, rayParams)
                    if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(model) then
                        closestDistance = distance
                        closestEnemy = enemyHead
                    end
                end
            end
        end
    end

    return closestEnemy
end

local function AimBot()
    if not AimBotEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        return
    end
    local equippedTool = Character and Character:FindFirstChildOfClass("Tool")
    if not IsRangedWeapon(equippedTool) then
        return
    end
    local target = GetClosestEnemy()
    if target then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
    end
end

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    if NoclipEnabled then
        Noclip()
    end
end)

RunService.RenderStepped:Connect(function()
    if not Character or not Humanoid or not HumanoidRootPart then
        return
    end
    if NoclipEnabled then
        Noclip()
    end
    if AimBotEnabled then
        Camera.FieldOfView = 90
        AimBot()
    else
        Camera.FieldOfView = DefaultFOV
    end
end)

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICornerMain = Instance.new("UICorner")
local UIStrokeMain = Instance.new("UIStroke")
local TitleFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local MoonIcon = Instance.new("TextLabel")
local Title = Instance.new("TextLabel")
local NoclipButton = Instance.new("TextButton")
local UICornerNoclip = Instance.new("UICorner")
local UIStrokeNoclip = Instance.new("UIStroke")
local NoFogButton = Instance.new("TextButton")
local UICornerNoFog = Instance.new("UICorner")
local UIStrokeNoFog = Instance.new("UIStroke")
local FullBrightButton = Instance.new("TextButton")
local UICornerFullBright = Instance.new("UICorner")
local UIStrokeFullBright = Instance.new("UIStroke")
local AimBotButton = Instance.new("TextButton")
local UICornerAimBot = Instance.new("UICorner")
local UIStrokeAimBot = Instance.new("UIStroke")

ScreenGui.Name = "MoonHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

MainFrame.Size = UDim2.new(0, 200, 0, 230)
MainFrame.Position = UDim2.new(0.8, 0, 0.5, -115)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui

UICornerMain.CornerRadius = UDim.new(0, 10)
UICornerMain.Parent = MainFrame

UIStrokeMain.Thickness = 2
UIStrokeMain.Transparency = 0.5
UIStrokeMain.Parent = MainFrame

TitleFrame.Size = UDim2.new(1, 0, 0, 30)
TitleFrame.BackgroundTransparency = 1
TitleFrame.Position = UDim2.new(0, 0, 0, 0)
TitleFrame.ZIndex = 11
TitleFrame.Parent = MainFrame

UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = TitleFrame

MoonIcon.Size = UDim2.new(0, 30, 0, 30)
MoonIcon.BackgroundTransparency = 1
MoonIcon.Text = "🌙"
MoonIcon.TextColor3 = Color3.fromRGB(220, 220, 100)
MoonIcon.TextSize = 18
MoonIcon.Font = Enum.Font.Gotham
MoonIcon.ZIndex = 11
MoonIcon.Parent = TitleFrame

Title.Size = UDim2.new(0, 100, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Moon Hub"
Title.TextColor3 = Color3.fromRGB(220, 220, 100)
Title.TextSize = 20
Title.Font = Enum.Font.Gotham
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.ZIndex = 11
Title.Parent = TitleFrame

NoclipButton.Size = UDim2.new(0.8, 0, 0, 30)
NoclipButton.Position = UDim2.new(0.1, 0, 0.17, 0)
NoclipButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
NoclipButton.Text = "Noclip"
NoclipButton.TextColor3 = Color3.fromRGB(180, 220, 255)
NoclipButton.TextSize = 18
NoclipButton.Font = Enum.Font.Gotham
NoclipButton.ZIndex = 11
NoclipButton.Parent = MainFrame

UICornerNoclip.CornerRadius = UDim.new(0, 5)
UICornerNoclip.Parent = NoclipButton

UIStrokeNoclip.Thickness = 1
UIStrokeNoclip.Transparency = 0.7
UIStrokeNoclip.Parent = NoclipButton

NoFogButton.Size = UDim2.new(0.8, 0, 0, 30)
NoFogButton.Position = UDim2.new(0.1, 0, 0.30, 0)
NoFogButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
NoFogButton.Text = "No Fog"
NoFogButton.TextColor3 = Color3.fromRGB(180, 220, 255)
NoFogButton.TextSize = 18
NoFogButton.Font = Enum.Font.Gotham
NoFogButton.ZIndex = 11
NoFogButton.Parent = MainFrame

UICornerNoFog.CornerRadius = UDim.new(0, 5)
UICornerNoFog.Parent = NoFogButton

UIStrokeNoFog.Thickness = 1
UIStrokeNoFog.Transparency = 0.7
UIStrokeNoFog.Parent = NoFogButton

FullBrightButton.Size = UDim2.new(0.8, 0, 0, 30)
FullBrightButton.Position = UDim2.new(0.1, 0, 0.43, 0)
FullBrightButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
FullBrightButton.Text = "Full Bright"
FullBrightButton.TextColor3 = Color3.fromRGB(180, 220, 255)
FullBrightButton.TextSize = 18
FullBrightButton.Font = Enum.Font.Gotham
FullBrightButton.ZIndex = 11
FullBrightButton.Parent = MainFrame

UICornerFullBright.CornerRadius = UDim.new(0, 5)
UICornerFullBright.Parent = FullBrightButton

UIStrokeFullBright.Thickness = 1
UIStrokeFullBright.Transparency = 0.7
UIStrokeFullBright.Parent = FullBrightButton

AimBotButton.Size = UDim2.new(0.8, 0, 0, 30)
AimBotButton.Position = UDim2.new(0.1, 0, 0.56, 0)
AimBotButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
AimBotButton.Text = "Aim Bot"
AimBotButton.TextColor3 = Color3.fromRGB(180, 220, 255)
AimBotButton.TextSize = 18
AimBotButton.Font = Enum.Font.Gotham
AimBotButton.ZIndex = 11
AimBotButton.Parent = MainFrame

UICornerAimBot.CornerRadius = UDim.new(0, 5)
UICornerAimBot.Parent = AimBotButton

UIStrokeAimBot.Thickness = 1
UIStrokeAimBot.Transparency = 0.7
UIStrokeAimBot.Parent = AimBotButton

local function UpdateRainbowEffect()
    local hue = (tick() % 5) / 5
    local color = Color3.fromHSV(hue, 1, 1)
    UIStrokeMain.Color = color
    UIStrokeNoclip.Color = color
    UIStrokeNoFog.Color = color
    UIStrokeFullBright.Color = color
    UIStrokeAimBot.Color = color
end

RunService.Heartbeat:Connect(UpdateRainbowEffect)

NoclipButton.MouseButton1Click:Connect(function()
    NoclipEnabled = not NoclipEnabled
    Noclip()
    NoclipButton.BackgroundColor3 = NoclipEnabled and Color3.fromRGB(220, 220, 100) or Color3.fromRGB(30, 50, 80)
end)

NoclipButton.MouseEnter:Connect(function()
    if not NoclipEnabled then
        NoclipButton.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
    end
end)

NoclipButton.MouseLeave:Connect(function()
    if not NoclipEnabled then
        NoclipButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
    end
end)

NoFogButton.MouseButton1Click:Connect(function()
    NoFogEnabled = not NoFogEnabled
    NoFog()
    NoFogButton.BackgroundColor3 = NoFogEnabled and Color3.fromRGB(220, 220, 100) or Color3.fromRGB(30, 50, 80)
end)

NoFogButton.MouseEnter:Connect(function()
    if not NoFogEnabled then
        NoFogButton.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
    end
end)

NoFogButton.MouseLeave:Connect(function()
    if not NoFogEnabled then
        NoFogButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
    end
end)

FullBrightButton.MouseButton1Click:Connect(function()
    FullBrightEnabled = not FullBrightEnabled
    FullBright()
    FullBrightButton.BackgroundColor3 = FullBrightEnabled and Color3.fromRGB(220, 220, 100) or Color3.fromRGB(30, 50, 80)
end)

FullBrightButton.MouseEnter:Connect(function()
    if not FullBrightEnabled then
        FullBrightButton.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
    end
end)

FullBrightButton.MouseLeave:Connect(function()
    if not FullBrightEnabled then
        FullBrightButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
    end
end)

AimBotButton.MouseButton1Click:Connect(function()
    AimBotEnabled = not AimBotEnabled
    AimBotButton.BackgroundColor3 = AimBotEnabled and Color3.fromRGB(220, 220, 100) or Color3.fromRGB(30, 50, 80)
end)

AimBotButton.MouseEnter:Connect(function()
    if not AimBotEnabled then
        AimBotButton.BackgroundColor3 = Color3.fromRGB(50, 70, 100)
    end
end)

AimBotButton.MouseLeave:Connect(function()
    if not AimBotEnabled then
        AimBotButton.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
    end
end)

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

CoreGui.ChildRemoved:Connect(function(child)
    if child.Name == "MoonHub" then
        NoclipEnabled = false
        NoFogEnabled = false
        FullBrightEnabled = false
        AimBotEnabled = false
        Camera.FieldOfView = DefaultFOV
        if Character then
            for _, v in pairs(Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
            if HumanoidRootPart then
                HumanoidRootPart.CanCollide = true
            end
        end
        if Lighting then
            Lighting.FogEnd = OriginalFogEnd
            Lighting.FogStart = OriginalFogStart
            Lighting.Brightness = OriginalBrightness
            Lighting.GlobalShadows = OriginalGlobalShadows
            Lighting.Ambient = OriginalAmbient
            Lighting.ClockTime = OriginalClockTime
            Lighting.EnvironmentDiffuseScale = OriginalEnvironmentDiffuseScale
            Lighting.EnvironmentSpecularScale = OriginalEnvironmentSpecularScale
            if AtmosphereBackup and not Lighting:FindFirstChildOfClass("Atmosphere") then
                AtmosphereBackup:Clone().Parent = Lighting
            end
            if ColorCorrectionBackup and not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
                ColorCorrectionBackup:Clone().Parent = Lighting
            end
        end
    end
end)

print("Moon Hub Loaded!")

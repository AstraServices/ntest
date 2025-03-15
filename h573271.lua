-- // LocalScript: StarterGui
-- Genişletilmiş GUI + Settings + Keybind + TeamCheck + ESP + Hitbox + Body-Head Focus
-- Drag sistemi düzeltildi, FOV'u UIStroke tabanlı daire ile yapıyor
-- Kullanmaman gerekenler: size, scale, visible, zindex, transparency
-- => FOV devreye sokmak/çıkarmak: stroke.Thickness=0 (kapalı), stroke.Thickness>0 (açık).
-- => ESP billboard, sabit boyut

--------------------------------------------------------------------------------
-- Hizmetler
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- Ana GUI
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SystemOverlay"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "SysFrame"
-- Tek sefer sabit boyut verildi
mainFrame.Size = UDim2.fromOffset(400,450)
mainFrame.AnchorPoint = Vector2.new(0, 0.5)
mainFrame.Position = UDim2.new(0, 0, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 1
mainFrame.Parent = screenGui

--------------------------------------------------------------------------------
-- ÜST BAR (Drag Panel)
--------------------------------------------------------------------------------
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.fromOffset(400, 30) -- Tam en
topBar.BackgroundColor3 = Color3.fromRGB(25,25,25)
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local dragging = false
local dragStart = Vector2.new()
local startPos  = nil

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = UserInputService:GetMouseLocation()
        startPos  = mainFrame.Position
    end
end)

topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = currentPos - dragStart
        mainFrame.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
    end
end)

--------------------------------------------------------------------------------
-- Başlık (Label)
--------------------------------------------------------------------------------
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLbl"
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Nypetrat Hub"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Parent = topBar

--------------------------------------------------------------------------------
-- Settings Butonu
--------------------------------------------------------------------------------
local settingsBtn = Instance.new("TextButton")
settingsBtn.Name = "SettingsBtn"
settingsBtn.Size = UDim2.fromOffset(60, 30)
settingsBtn.Position = UDim2.new(1, -60, 0, 0)
settingsBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.Text = "Settings"
settingsBtn.Parent = topBar

local settingsOpen = false

local settingsFrame = Instance.new("Frame")
settingsFrame.Name = "SettingsFrame"
settingsFrame.Position = UDim2.fromOffset(10, 300)
settingsFrame.Size = UDim2.fromOffset(380, 140)
settingsFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = mainFrame

settingsBtn.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    settingsFrame.Visible = settingsOpen
end)

--------------------------------------------------------------------------------
-- Renk Ayarı (tek slider)
--------------------------------------------------------------------------------
local colorLabel = Instance.new("TextLabel")
colorLabel.Name = "ColorLabel"
colorLabel.Size = UDim2.fromOffset(380, 20)
colorLabel.Position = UDim2.fromOffset(0,0)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "GUI Color"
colorLabel.TextColor3 = Color3.new(1,1,1)
colorLabel.Parent = settingsFrame

local colorSlider = Instance.new("Frame")
colorSlider.Name = "ColorSlider"
colorSlider.Position = UDim2.fromOffset(5,20)
colorSlider.Size = UDim2.fromOffset(370, 10)
colorSlider.BackgroundColor3 = Color3.fromRGB(120,120,120)
colorSlider.Parent = settingsFrame

local colorBtn = Instance.new("Frame")
colorBtn.Size = UDim2.fromOffset(10,10)
colorBtn.Position = UDim2.fromOffset(0,0)
colorBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
colorBtn.Parent = colorSlider

local colorDragging = false
local function updateGUIColorFromPosition(xPos)
    local rel = math.clamp(xPos - colorSlider.AbsolutePosition.X, 0, colorSlider.AbsoluteSize.X)
    colorBtn.Position = UDim2.fromOffset(rel-5, 0)
    local pct = rel / colorSlider.AbsoluteSize.X
    local r = math.floor(255*pct)
    local g,b = 30,30
    mainFrame.BackgroundColor3 = Color3.fromRGB(r,g,b)
end

colorSlider.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        colorDragging = true
        updateGUIColorFromPosition(inp.Position.X)
    end
end)

colorSlider.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        colorDragging = false
    end
end)

colorSlider.InputChanged:Connect(function(inp)
    if colorDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        updateGUIColorFromPosition(inp.Position.X)
    end
end)

--------------------------------------------------------------------------------
-- Keybind Sistemi
--------------------------------------------------------------------------------
local aimKey = Enum.UserInputType.MouseButton2
local rHeld = false
local waitingForKey = false
local focusing = false

local keybindButton = Instance.new("TextButton")
keybindButton.Name = "KeybindButton"
keybindButton.Size = UDim2.fromOffset(100, 20)
keybindButton.Position = UDim2.fromOffset(5, 40)
keybindButton.BackgroundColor3 = Color3.fromRGB(80,80,80)
keybindButton.TextColor3 = Color3.new(1,1,1)
keybindButton.Text = "Change Key"
keybindButton.Parent = settingsFrame

keybindButton.MouseButton1Click:Connect(function()
    if not waitingForKey then
        waitingForKey = true
        keybindButton.Text = "Press a key..."
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if waitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            aimKey = input.KeyCode
            keybindButton.Text = "Key: "..tostring(input.KeyCode)
        else
            aimKey = input.UserInputType
            keybindButton.Text = "Key: "..tostring(input.UserInputType)
        end
        waitingForKey = false
        return
    end

    if focusing then
        if input.UserInputType == aimKey or (typeof(aimKey)== "EnumItem" and input.KeyCode == aimKey) then
            rHeld = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if focusing then
        if input.UserInputType == aimKey or (typeof(aimKey)== "EnumItem" and input.KeyCode == aimKey) then
            rHeld = false
        end
    end
end)

--------------------------------------------------------------------------------
-- TeamCheck
--------------------------------------------------------------------------------
local teamCheck = false
local function togg(btn)
    local oldTxt = btn.Text
    if oldTxt:find("%[ %]") then
        btn.Text = oldTxt:gsub("%[ %]", "[X]")
    else
        btn.Text = oldTxt:gsub("%[X%]", "[ ]")
    end
end

--------------------------------------------------------------------------------
-- HEAD-BODY, ESP, HITBOX, TEAMCHECK
--------------------------------------------------------------------------------
local boxTeam = Instance.new("TextButton")
boxTeam.Name = "TeamBox"
boxTeam.Size = UDim2.fromOffset(140,20)
boxTeam.Position = UDim2.fromOffset(10,80)
boxTeam.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxTeam.TextColor3 = Color3.new(1,1,1)
boxTeam.Text = "[ ] TeamCheck"
boxTeam.Parent = mainFrame

local boxHead = Instance.new("TextButton")
boxHead.Name = "HeadBox"
boxHead.Size = UDim2.fromOffset(140,20)
boxHead.Position = UDim2.fromOffset(10,105)
boxHead.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxHead.TextColor3 = Color3.new(1,1,1)
boxHead.Text = "[ ] HeadFocus"
boxHead.Parent = mainFrame

local boxBody = Instance.new("TextButton")
boxBody.Name = "BodyBox"
boxBody.Size = UDim2.fromOffset(140,20)
boxBody.Position = UDim2.fromOffset(10,130)
boxBody.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxBody.TextColor3 = Color3.new(1,1,1)
boxBody.Text = "[ ] BodyFocus"
boxBody.Parent = mainFrame

local boxEsp = Instance.new("TextButton")
boxEsp.Name = "EspBox"
boxEsp.Size = UDim2.fromOffset(140,20)
boxEsp.Position = UDim2.fromOffset(10,155)
boxEsp.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxEsp.TextColor3 = Color3.new(1,1,1)
boxEsp.Text = "[ ] Highlighter"
boxEsp.Parent = mainFrame

local boxHit = Instance.new("TextButton")
boxHit.Name = "HitBox"
boxHit.Size = UDim2.fromOffset(140,20)
boxHit.Position = UDim2.fromOffset(10,180)
boxHit.BackgroundColor3 = Color3.fromRGB(60,60,60)
boxHit.TextColor3 = Color3.new(1,1,1)
boxHit.Text = "[ ] ExpandHit"
boxHit.Parent = mainFrame

local topActive = false
local midActive = false
local hlActive = false
local bigActive = false

boxTeam.MouseButton1Click:Connect(function()
    togg(boxTeam)
    teamCheck = not teamCheck
end)

boxHead.MouseButton1Click:Connect(function()
    togg(boxHead)
    topActive = not topActive
    if topActive then
        midActive = false
        boxBody.Text = boxBody.Text:gsub("%[X%]", "[ ]")
    end
end)

boxBody.MouseButton1Click:Connect(function()
    togg(boxBody)
    midActive = not midActive
    if midActive then
        topActive = false
        boxHead.Text = boxHead.Text:gsub("%[X%]", "[ ]")
    end
end)

boxEsp.MouseButton1Click:Connect(function()
    togg(boxEsp)
    hlActive = not hlActive
    updateAllHighlights()
end)

boxHit.MouseButton1Click:Connect(function()
    togg(boxHit)
    bigActive = not bigActive
    if not bigActive then
        revertAllBoxes()
    else
        expandAllBoxes()
    end
end)

--------------------------------------------------------------------------------
-- FOCUS BUTONU
--------------------------------------------------------------------------------
local focusBtn = Instance.new("TextButton")
focusBtn.Name = "FocusBtn"
focusBtn.Size = UDim2.fromOffset(100,30)
focusBtn.Position = UDim2.fromOffset(180,80)
focusBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
focusBtn.TextColor3 = Color3.new(1,1,1)
focusBtn.Text = "Focus: Off"
focusBtn.Parent = mainFrame

local fovEnabled = false  
focusBtn.MouseButton1Click:Connect(function()
    focusing = not focusing
    focusBtn.Text = focusing and "Focus: On" or "Focus: Off"
    fovEnabled = focusing
    -- stroke.Thickness=0 => devre dışı (\"Disabled\")
    -- stroke.Thickness>0 => etkin
    if fovEnabled then
        stroke.Thickness = lastThickness
    else
        stroke.Thickness = 0
    end
end)

--------------------------------------------------------------------------------
-- FOV dairesi: UIStroke tabanlı
--------------------------------------------------------------------------------
local minDist = 50
local maxDist = 300
local nowDist = 100

local rangeSlide = Instance.new("Frame")
rangeSlide.Name = "RangeSlide"
rangeSlide.Size = UDim2.fromOffset(140,10)
rangeSlide.Position = UDim2.fromOffset(180,120)
rangeSlide.BackgroundColor3 = Color3.fromRGB(120,120,120)
rangeSlide.Parent = mainFrame

local slideBar = Instance.new("Frame")
slideBar.Name = "SlideBar"
slideBar.Size = UDim2.fromScale(1,1)
slideBar.BackgroundColor3 = Color3.fromRGB(150,150,150)
slideBar.Parent = rangeSlide

local slideBtn = Instance.new("Frame")
slideBtn.Name = "SlideBtn"
slideBtn.Size = UDim2.fromScale(0,1)
slideBtn.Position = UDim2.new(0, -5, 0, 0)
slideBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
slideBtn.Parent = slideBar

local draggingFov = false
local lastThickness = 0 -- store

rangeSlide.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFov = true
    end
end)

rangeSlide.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFov = false
    end
end)

rangeSlide.InputChanged:Connect(function(inp)
    if draggingFov and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local rX = math.clamp(inp.Position.X - rangeSlide.AbsolutePosition.X, 0, rangeSlide.AbsoluteSize.X)
        local pct = rX / rangeSlide.AbsoluteSize.X
        slideBtn.Position = UDim2.new(pct, -5, 0, 0)
        nowDist = math.floor(minDist + (maxDist - minDist)*pct)
        updateFOVCircle(nowDist)
    end
end)

--------------------------------------------------------------------------------
-- FOV Circle (UIStroke)
--------------------------------------------------------------------------------
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FOVCircle"
fovCircle.Position = UDim2.fromOffset(100,100)
fovCircle.BackgroundColor3 = Color3.fromRGB(0,0,0)
fovCircle.BackgroundTransparency = 1  -- sabit
fovCircle.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1,0)
corner.Parent = fovCircle

local stroke = Instance.new("UIStroke")
stroke.Thickness = 0  -- ilk başta gizli
stroke.Color = Color3.fromRGB(0,255,0)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.LineJoinMode = Enum.LineJoinMode.Round
stroke.Parent = fovCircle

local function updateFOVCircle(distance)
    local fraction = (distance - minDist)/(maxDist - minDist)
    if fraction<0 then fraction=0 elseif fraction>1 then fraction=1 end
    local thick = 150 - math.floor( fraction*(150-1) )  -- [1..150]
    lastThickness = thick
    if fovEnabled then
        stroke.Thickness = thick
    end
end
updateFOVCircle(nowDist)

RunService.RenderStepped:Connect(function()
    if fovEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
    end
end)

--------------------------------------------------------------------------------
-- TeamCheck / isEnemy
--------------------------------------------------------------------------------
local function isEnemy(pl)
    if pl == LocalPlayer then return false end
    if not teamCheck then
        return true
    else
        return (pl.Team ~= LocalPlayer.Team)
    end
end

--------------------------------------------------------------------------------
-- Aimbot Mantığı: pickClosest
--------------------------------------------------------------------------------
local function lineCheck(tObj)
    if not tObj then return false end
    local origin = Camera.CFrame.Position
    local direction = (tObj.Position - origin)
    local rParams = RaycastParams.new()
    rParams.FilterType = Enum.RaycastFilterType.Blacklist
    rParams.FilterDescendantsInstances = {LocalPlayer.Character}

    local rr = workspace:Raycast(origin, direction, rParams)
    if rr then
        if rr.Instance and rr.Instance:IsDescendantOf(tObj.Parent) then
            return true
        else
            return false
        end
    end
    return false
end

local function pickClosest()
    local closestDist = math.huge
    local closestChar = nil
    for _,p in pairs(Players:GetPlayers()) do
        if isEnemy(p) and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vPoint, onScr = Camera:WorldToViewportPoint(hrp.Position)
                if onScr then
                    local scrPos = Vector2.new(vPoint.X, vPoint.Y)
                    local centerPos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                    local distC = (scrPos - centerPos).Magnitude
                    if distC <= nowDist then
                        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHrp then
                            local distB = (hrp.Position - myHrp.Position).Magnitude
                            if distB <= 35 then
                                if distC < closestDist then
                                    closestDist = distC
                                    closestChar = p.Character
                                end
                            else
                                if lineCheck(hrp) then
                                    if distC < closestDist then
                                        closestDist = distC
                                        closestChar = p.Character
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closestChar
end

RunService.RenderStepped:Connect(function()
    if focusing and rHeld then
        local targetChar = pickClosest()
        if targetChar then
            local aimPart
            if topActive then
                aimPart = targetChar:FindFirstChild("Head")
            elseif midActive then
                aimPart = targetChar:FindFirstChild("HumanoidRootPart")
            end
            if aimPart then
                local cPos = Camera.CFrame.Position
                Camera.CFrame = CFrame.lookAt(cPos, aimPart.Position)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- ESP (Highlighter)
-- Kamera uzaklaştıkça büyümemesi için billboard.Size= UDim2.fromOffset(50,50), LightInfluence=0
--------------------------------------------------------------------------------
local function setupHighlight(ch)
    if not ch then return end
    if ch:FindFirstChild("HBObj") then return end
    local headOrRoot = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    if not headOrRoot then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "HBObj"
    bb.Adornee = headOrRoot
    bb.Size = UDim2.fromOffset(50,50) -- sabit boyut
    bb.LightInfluence = 0            -- kameraya göre büyümesin
    bb.ExtentsOffset = Vector3.new(0,1,0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 999999
    bb.ResetOnSpawn = false
    bb.Enabled = false

    local fr = Instance.new("Frame")
    fr.Size = UDim2.fromScale(1,1)
    fr.BackgroundTransparency = 0.6
    fr.BackgroundColor3 = Color3.fromRGB(255,0,0)
    fr.BorderSizePixel = 2
    fr.BorderColor3 = Color3.new(0,0,0)
    fr.Parent = bb

    bb.Parent = ch
end

local function updateOneHighlight(pl)
    if not pl.Character then return end
    local c = pl.Character
    local bb = c:FindFirstChild("HBObj")
    if not bb then
        setupHighlight(c)
        bb = c:FindFirstChild("HBObj")
        if not bb then return end
    end

    if isEnemy(pl) and hlActive then
        bb.Enabled = true
    else
        bb.Enabled = false
    end
end

function updateAllHighlights()
    for _,ply in pairs(Players:GetPlayers()) do
        updateOneHighlight(ply)
    end
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function(c)
        RunService.Heartbeat:Wait()
        setupHighlight(c)
        updateOneHighlight(pl)
    end)
end)

RunService.Heartbeat:Connect(function()
    if hlActive then
        updateAllHighlights()
    end
end)

--------------------------------------------------------------------------------
-- Hitbox Expander
--------------------------------------------------------------------------------
local function expandHitbox(ch)
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if hrp and not hrp:GetAttribute("OrigSize") then
        hrp:SetAttribute("OrigSize", hrp.Size)
        hrp.Size = Vector3.new(5,5,5)
        hrp.Transparency = 0.3
    end
end

local function revertHitbox(ch)
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if hrp then
        local orig = hrp:GetAttribute("OrigSize")
        if orig then
            hrp.Size = orig
            hrp:SetAttribute("OrigSize", nil)
            hrp.Transparency = 0
        end
    end
end

function expandAllBoxes()
    for _,ply in pairs(Players:GetPlayers()) do
        if isEnemy(ply) and ply.Character then
            expandHitbox(ply.Character)
        else
            revertHitbox(ply.Character)
        end
    end
end

function revertAllBoxes()
    for _,ply in pairs(Players:GetPlayers()) do
        if ply.Character then
            revertHitbox(ply.Character)
        end
    end
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function(ch)
        RunService.Heartbeat:Wait()
        if bigActive then
            if isEnemy(pl) then
                expandHitbox(ch)
            else
                revertHitbox(ch)
            end
        else
            revertHitbox(ch)
        end
    end)
end)

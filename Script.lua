local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LOCAL_PLAYER = Players.LocalPlayer
local MIN_RADIUS, MAX_RADIUS = 5, 30
local MIN_DELAY, MAX_DELAY = 0, 500
local DEFAULT_RADIUS = 11

local Config = {
    isEnabled = true,
    radius = DEFAULT_RADIUS,
    blockDelay = 0,
    sphereVisible = true,
    toggleKey = Enum.KeyCode.M,
    blockToggleKey = Enum.KeyCode.B
}

local GUI = {
    statusLabel = nil,
    rangeLabel = nil,
    valueLabel = nil,
    delayLabel = nil,
    visualSphere = nil,
    mainFrame = nil,
    blockToggleKeyLabel = nil
}

local SAFE_ANIMATIONS = {
    ["180426354"]=true,["180435792"]=true,["180435557"]=true,["180435571"]=true,
    ["684969250"]=true,["12246410284"]=true,["684949179"]=true,["180436148"]=true,
    ["7950784441"]=true,["12245963642"]=true,["16398226659"]=true,["6691954521"]=true,
    ["6768460286"]=true,["6835294179"]=true,["6835294624"]=true,["6835295587"]=true,
    ["6835295340"]=true,["6835295768"]=true,["6843685401"]=true,["6843686183"]=true,
    ["6843688241"]=true,["6844129816"]=true,["6844132951"]=true,["6848072990"]=true,
    ["6857596237"]=true,["6887306042"]=true,["6887334158"]=true,["6891877544"]=true,
    ["6910931126"]=true,["9819726292"]=true,["9819735529"]=true,["9819745648"]=true,
    ["9819790668"]=true,["9819806597"]=true,["9819811478"]=true,["9819823356"]=true,
    ["9819830644"]=true,["9822389499"]=true,["9825822267"]=true,["9825834442"]=true,
    ["6846937588"]=true,["6846943217"]=true,["11116879670"]=true,["10950534442"]=true,
    ["11116773443"]=true,["11116829154"]=true,["11116842345"]=true,["11116851650"]=true,
    ["11116868980"]=true,["11116876082"]=true,["11116879769"]=true,["11116883670"]=true,
    ["11116904044"]=true,["11116906510"]=true,["11116911916"]=true,["11116928049"]=true,
    ["11116935344"]=true,["11116942197"]=true,["11116953107"]=true,["11739213999"]=true,
    ["11739218535"]=true,["11739221487"]=true,["11824454279"]=true,["12110667126"]=true,
    ["12110738932"]=true,["12110743424"]=true,["12119297992"]=true,["15171648575"]=true,
    ["15434704458"]=true,["15434415778"]=true,["15434491089"]=true,["15434493570"]=true,
    ["15744847038"]=true,["16203609238"]=true,["16294404827"]=true,["17003507450"]=true,
    ["18357490871"]=true,["18570567181"]=true,["18570580687"]=true,["18570584513"]=true,
    ["18570587568"]=true,["18570592488"]=true,["18570596139"]=true,["6849692501"]=true,
    ["6849441527"]=true,["7950763400"]=true,["7814314769"]=true,["6849491789"]=true,
    ["6835295052"]=true,["6849489471"]=true,["8201303807"]=true,["10697528876"]=true,
    ["8201293554"]=true,["16398208032"]=true,["11580783004"]=true,["18570602813"]=true,
    ["18570605663"]=true,["18570610312"]=true,["18570613289"]=true,["18570616732"]=true,
    ["18570620535"]=true,["18570623746"]=true,["18570626263"]=true,["18570632470"]=true,
    ["18570671957"]=true,["18570683512"]=true,["18570687683"]=true,["18850450498"]=true,
    ["85696117023177"]=true,["123461108716822"]=true,["1190149394074304"]=true,
    ["116839058176293"]=true,["752942489704875"]=true,["130879133604226"]=true,
    ["11580787715"]=true,["6835295057"]=true,["7814305242"]=true,
    ["119813141112551"]=true,["80008594862427"]=true
}

local function normalizeAnimationId(id)
    return id:match("id=(%d+)") or id:match("%d+")
end

local function getDistance(player)
    local char, localChar = player.Character, LOCAL_PLAYER.Character
    if not (char and localChar) then return math.huge end
    local root, localRoot = char:FindFirstChild("HumanoidRootPart"), localChar:FindFirstChild("HumanoidRootPart")
    if not (root and localRoot) then return math.huge end
    return (root.Position - localRoot.Position).Magnitude
end

local function updateGUIStatus(isBlocking)
    if not GUI.statusLabel then return end
    GUI.statusLabel.Text = isBlocking and "Status: Blocking!" or "Status: Active"
    GUI.statusLabel.TextColor3 = isBlocking and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
    if GUI.visualSphere and Config.sphereVisible then
        GUI.visualSphere.Color = isBlocking and Color3.new(1,0,0) or Color3.new(1,1,0)
    end
end

local function updateRadius(p)
    Config.radius = math.floor((MIN_RADIUS + (MAX_RADIUS - MIN_RADIUS) * p) * 10) / 10
    if GUI.valueLabel then GUI.valueLabel.Text = ("Radius: %.1f studs"):format(Config.radius) end
    if GUI.rangeLabel then GUI.rangeLabel.Text = ("Range: %.1f studs"):format(Config.radius) end
    if GUI.visualSphere then
        local s = Config.radius * 2
        GUI.visualSphere.Size = Vector3.new(s,s,s)
    end
end

local function updateDelay(p)
    Config.blockDelay = math.floor(MIN_DELAY + (MAX_DELAY - MIN_DELAY) * p)
    if GUI.delayLabel then GUI.delayLabel.Text = ("Delay: %d ms"):format(Config.blockDelay) end
end

local function handleAnimation(player, animTrack)
    if not (Config.isEnabled and player ~= LOCAL_PLAYER) or UserInputService:GetFocusedTextBox() then return end
    local animId = normalizeAnimationId(animTrack.Animation.AnimationId)
    if SAFE_ANIMATIONS[animId] then return end
    if getDistance(player) > Config.radius then return end
    updateGUIStatus(true)
    task.spawn(function()
        if Config.blockDelay > 0 then task.wait(Config.blockDelay/1000) end
        if not UserInputService:GetFocusedTextBox() then
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            animTrack.Stopped:Wait()
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
        updateGUIStatus(false)
    end)
end

local function initializePlayerTracking(player)
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:WaitForChild("Animator")
        animator.AnimationPlayed:Connect(function(animTrack)
            handleAnimation(player, animTrack)
        end)
    end
    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function updateBlockToggleButton(btn)
    if Config.isEnabled then
        btn.BackgroundColor3 = Color3.fromRGB(0,170,0)
        btn.Text = "Enabled"
        GUI.statusLabel.Text = "Status: Active"
        GUI.statusLabel.TextColor3 = Color3.fromRGB(0,255,0)
        if Config.sphereVisible then GUI.visualSphere.Transparency = 0.8 end
    else
        btn.BackgroundColor3 = Color3.fromRGB(170,0,0)
        btn.Text = "Disabled"
        GUI.statusLabel.Text = "Status: Inactive"
        GUI.statusLabel.TextColor3 = Color3.fromRGB(255,0,0)
        GUI.visualSphere.Transparency = 1
    end
end

local function createGUI()
    local screenGui = Instance.new("ScreenGui", LOCAL_PLAYER:WaitForChild("PlayerGui"))
    screenGui.Name = "AutoBlockerGUI"

    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Size = UDim2.new(0,200,0,290)
    mainFrame.Position = UDim2.new(0.8,0,0.5,-60)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    mainFrame.BorderSizePixel = 0
    GUI.mainFrame = mainFrame

    local function corner(i,r)
        local c = Instance.new("UICorner", i)
        c.CornerRadius = UDim.new(0,r)
    end

    local dragging, dragStart, startPos
    mainFrame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=i.Position
            startPos=mainFrame.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement and dragging then
            local d=i.Position-dragStart
            mainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.fromRGB(40,40,40)
    title.BorderSizePixel = 0
    title.Text = "Auto Blocker"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14

    GUI.statusLabel = Instance.new("TextLabel", mainFrame)
    GUI.statusLabel.Position = UDim2.new(0,0,0,35)
    GUI.statusLabel.Size = UDim2.new(1,0,0,20)
    GUI.statusLabel.BackgroundTransparency = 1
    GUI.statusLabel.Text = "Status: Active"
    GUI.statusLabel.TextColor3 = Color3.fromRGB(0,255,0)
    GUI.statusLabel.Font = Enum.Font.Gotham
    GUI.statusLabel.TextSize = 12

    GUI.rangeLabel = Instance.new("TextLabel", mainFrame)
    GUI.rangeLabel.Position = UDim2.new(0,0,0,55)
    GUI.rangeLabel.Size = UDim2.new(1,0,0,20)
    GUI.rangeLabel.BackgroundTransparency = 1
    GUI.rangeLabel.Text = ("Range: %.1f studs"):format(Config.radius)
    GUI.rangeLabel.TextColor3 = Color3.new(1,1,1)
    GUI.rangeLabel.Font = Enum.Font.Gotham
    GUI.rangeLabel.TextSize = 12

    local sliderFrame = Instance.new("Frame", mainFrame)
    sliderFrame.Position = UDim2.new(0.1,0,0,80)
    sliderFrame.Size = UDim2.new(0.8,0,0,4)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(60,60,60)
    sliderFrame.BorderSizePixel = 0

    local sliderBtn = Instance.new("TextButton", sliderFrame)
    sliderBtn.Size = UDim2.new(0,16,0,16)
    sliderBtn.Position = UDim2.new(0,-8,0,-6)
    sliderBtn.BackgroundColor3 = Color3.new(1,1,1)
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Text = ""

    GUI.valueLabel = Instance.new("TextLabel", mainFrame)
    GUI.valueLabel.Position = UDim2.new(0,0,0,90)
    GUI.valueLabel.Size = UDim2.new(1,0,0,20)
    GUI.valueLabel.BackgroundTransparency = 1
    GUI.valueLabel.Text = ("Radius: %.1f studs"):format(Config.radius)
    GUI.valueLabel.TextColor3 = Color3.new(1,1,1)
    GUI.valueLabel.Font = Enum.Font.Gotham
    GUI.valueLabel.TextSize = 12

    local delayFrame = Instance.new("Frame", mainFrame)
    delayFrame.Position = UDim2.new(0.1,0,0,120)
    delayFrame.Size = UDim2.new(0.8,0,0,4)
    delayFrame.BackgroundColor3 = Color3.fromRGB(60,60,60)
    delayFrame.BorderSizePixel = 0

    local delayBtn = Instance.new("TextButton", delayFrame)
    delayBtn.Size = UDim2.new(0,16,0,16)
    delayBtn.Position = UDim2.new(0,-8,0,-6)
    delayBtn.BackgroundColor3 = Color3.new(1,1,1)
    delayBtn.BorderSizePixel = 0
    delayBtn.Text = ""

    GUI.delayLabel = Instance.new("TextLabel", mainFrame)
    GUI.delayLabel.Position = UDim2.new(0,0,0,130)
    GUI.delayLabel.Size = UDim2.new(1,0,0,20)
    GUI.delayLabel.BackgroundTransparency = 1
    GUI.delayLabel.Text = ("Delay: %d ms"):format(Config.blockDelay)
    GUI.delayLabel.TextColor3 = Color3.new(1,1,1)
    GUI.delayLabel.Font = Enum.Font.Gotham
    GUI.delayLabel.TextSize = 12

    local keyBtn = Instance.new("TextButton", mainFrame)
    keyBtn.Position = UDim2.new(0.1,0,0,160)
    keyBtn.Size = UDim2.new(0.8,0,0,25)
    keyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = "Toggle Key: "..Config.toggleKey.Name
    keyBtn.TextColor3 = Color3.new(1,1,1)
    keyBtn.Font = Enum.Font.GothamSemibold
    keyBtn.TextSize = 14

    local blockKeyBtn = Instance.new("TextButton", mainFrame)
    blockKeyBtn.Position = UDim2.new(0.1,0,0,190)
    blockKeyBtn.Size = UDim2.new(0.8,0,0,25)
    blockKeyBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    blockKeyBtn.BorderSizePixel = 0
    blockKeyBtn.Text = "Block Key: "..Config.blockToggleKey.Name
    blockKeyBtn.TextColor3 = Color3.new(1,1,1)
    blockKeyBtn.Font = Enum.Font.GothamSemibold
    blockKeyBtn.TextSize = 14

    local sphereBtn = Instance.new("TextButton", mainFrame)
    sphereBtn.Position = UDim2.new(0.1,0,0,220)
    sphereBtn.Size = UDim2.new(0.8,0,0,25)
    sphereBtn.BackgroundColor3 = Color3.fromRGB(0,170,170)
    sphereBtn.BorderSizePixel = 0
    sphereBtn.Text = "Sphere Visible"
    sphereBtn.TextColor3 = Color3.new(1,1,1)
    sphereBtn.Font = Enum.Font.GothamSemibold
    sphereBtn.TextSize = 14

    local toggleBtn = Instance.new("TextButton", mainFrame)
    toggleBtn.Position = UDim2.new(0.1,0,0,250)
    toggleBtn.Size = UDim2.new(0.8,0,0,25)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "Enabled"
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.TextSize = 14

    corner(mainFrame,6)
    corner(toggleBtn,4)
    corner(sphereBtn,4)
    corner(sliderBtn,8)
    corner(delayBtn,8)
    corner(keyBtn,4)
    corner(blockKeyBtn,4)

    GUI.visualSphere = Instance.new("Part", workspace)
    GUI.visualSphere.Shape = Enum.PartType.Ball
    GUI.visualSphere.Size = Vector3.new(Config.radius*2,Config.radius*2,Config.radius*2)
    GUI.visualSphere.Transparency = 0.8
    GUI.visualSphere.CanCollide = false
    GUI.visualSphere.Anchored = true
    GUI.visualSphere.Color = Color3.new(1,1,0)

    local dragR, dragD = false, false
    sliderBtn.MouseButton1Down:Connect(function() dragR=true end)
    delayBtn.MouseButton1Down:Connect(function() dragD=true end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragR=false dragD=false end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            local m=UserInputService:GetMouseLocation()
            if dragR then
                local p=math.clamp((m.X-sliderFrame.AbsolutePosition.X)/sliderFrame.AbsoluteSize.X,0,1)
                sliderBtn.Position=UDim2.new(p,-8,0,-6)
                updateRadius(p)
            elseif dragD then
                local p=math.clamp((m.X-delayFrame.AbsolutePosition.X)/delayFrame.AbsoluteSize.X,0,1)
                delayBtn.Position=UDim2.new(p,-8,0,-6)
                updateDelay(p)
            end
        end
    end)

    local function updateKeys()
        keyBtn.Text="Toggle Key: "..Config.toggleKey.Name
        blockKeyBtn.Text="Block Key: "..Config.blockToggleKey.Name
    end

    local function changeKey(isBlock)
        local b=isBlock and blockKeyBtn or keyBtn
        b.Text="Press any key..."
        local c
        c=UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Keyboard then
                if isBlock then Config.blockToggleKey=i.KeyCode else Config.toggleKey=i.KeyCode end
                updateKeys()
                c:Disconnect()
            end
        end)
    end

    keyBtn.MouseButton1Click:Connect(function() changeKey(false) end)
    blockKeyBtn.MouseButton1Click:Connect(function() changeKey(true) end)

    sphereBtn.MouseButton1Click:Connect(function()
        Config.sphereVisible=not Config.sphereVisible
        if Config.sphereVisible then
            sphereBtn.BackgroundColor3=Color3.fromRGB(0,170,170)
            sphereBtn.Text="Sphere Visible"
            if Config.isEnabled then GUI.visualSphere.Transparency=0.8 end
        else
            sphereBtn.BackgroundColor3=Color3.fromRGB(170,85,85)
            sphereBtn.Text="Sphere Hidden"
            GUI.visualSphere.Transparency=1
        end
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        Config.isEnabled=not Config.isEnabled
        updateBlockToggleButton(toggleBtn)
    end)
end

local function initialize()
    createGUI()
    UserInputService.InputBegan:Connect(function(i)
        if UserInputService:GetFocusedTextBox() then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            if i.KeyCode==Config.toggleKey then
                GUI.mainFrame.Visible=not GUI.mainFrame.Visible
            elseif i.KeyCode==Config.blockToggleKey then
                Config.isEnabled=not Config.isEnabled
                updateBlockToggleButton(GUI.mainFrame:FindFirstChild("ToggleButton"))
            end
        end
    end)
    RunService.Heartbeat:Connect(function()
        if not (Config.isEnabled and GUI.visualSphere) then return end
        local c=LOCAL_PLAYER.Character
        if not c then return end
        local r=c:FindFirstChild("HumanoidRootPart")
        if r then GUI.visualSphere.Position=r.Position end
    end)
    for _,p in ipairs(Players:GetPlayers()) do initializePlayerTracking(p) end
    Players.PlayerAdded:Connect(initializePlayerTracking)
end

initialize()
